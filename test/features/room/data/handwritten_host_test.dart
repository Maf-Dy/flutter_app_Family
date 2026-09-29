import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:family_game/features/room/data/family_page.dart';
import 'package:family_game/features/room/data/family_view.dart';
import 'package:family_game/features/room/data/lan_room_host.dart';
import 'package:family_game/features/room/data/join_page.dart';
import 'package:family_game/features/room/data/join_strings.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/ink.dart';

void main() {
  late LanRoomHost host;
  late HttpClient client;
  late int port;
  const cookie = '${LanRoomHost.cookieName}=0123456789abcdef0123456789abcdef';
  final drawing = SlipInk.tryParse(tinyPng)!;

  Future<({int status, List<int> body, HttpHeaders headers})> send(
    String method,
    String path, {
    String? form,
    Map<String, String> headers = const {},
  }) async {
    final request = await client.openUrl(method, Uri.parse('http://127.0.0.1:$port$path'));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.cookieHeader, cookie);
    headers.forEach(request.headers.set);
    if (form != null) {
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write(form);
    }
    final response = await request.close();
    final body = <int>[];
    await response.forEach(body.addAll);
    return (status: response.statusCode, body: body, headers: response.headers);
  }

  String encode(Map<String, String> form) => Uri(queryParameters: form).query;

  setUp(() async {
    host = LanRoomHost(preferredPort: 0);
    port = await host.open(
      const Room(
        code: 'K7Q4',
        category: GameCategory.preset(PresetCategory.famousPeople),
        namesPerPlayer: 2,
        hostName: 'Mafdy',
        handwritten: true,
        mode: GameMode.family,
      ),
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await host.close();
  });

  test('the join page offers a drawing pad per name instead of text fields', () async {
    final page = utf8.decode((await send('GET', '/')).body);
    expect(RegExp('<canvas').allMatches(page), hasLength(2));
    expect(page, contains('name="s0"'));
    expect(page, contains('Write the name here with your finger'));
    expect(page, contains('class="pad-clear"'));
    expect(page, isNot(contains('class="hand"')), reason: 'no typing in a handwritten room');

    final arabic = JoinPage.form(host.room, const ArabicJoinStrings());
    expect(arabic, contains('dir="rtl"'));
    expect(arabic, contains('اكتب الاسم هنا بصباعك'));
  });

  test('drawings sent as PNG data URLs go in the bowl', () async {
    final post = await send(
      'POST',
      '/',
      form: encode({'name': 'Omar', 's0': drawing.toDataUrl(), 's1': drawing.toDataUrl()}),
    );
    expect(post.status, HttpStatus.seeOther);
    final omar = host.room.players.single;
    expect(omar.inks, [drawing, drawing]);
    expect(omar.secrets, [SlipInk.marker, SlipInk.marker]);

    final edit = utf8.decode((await send('GET', '/?edit=1')).body);
    expect(edit, contains('value="${drawing.toDataUrl()}"'), reason: 'your own phone gets its drawings back to edit');
  });

  test('a missing or broken drawing is a missing name, and the good one is kept', () async {
    final post = await send('POST', '/', form: encode({'name': 'Omar', 's0': drawing.toDataUrl(), 's1': 'Messi'}));
    expect(post.status, HttpStatus.badRequest);
    final page = utf8.decode(post.body);
    expect(page, contains('Write all 2 names with your finger.'));
    expect(page, contains('value="${drawing.toDataUrl()}"'));
    expect(host.room.players, isEmpty);

    final tooBig = SlipInk.tryParse(pngHeader(481, 100));
    expect(tooBig, isNull);
    final wide = 'data:image/png;base64,${base64.encode(pngHeader(481, 100))}';
    expect(
      (await send('POST', '/', form: encode({'name': 'Omar', 's0': wide, 's1': wide}))).status,
      HttpStatus.badRequest,
    );
    expect(host.room.players, isEmpty);
  });

  test('a body far over the drawing limit is refused', () async {
    final huge = 'data:image/png;base64,${'A' * (SlipInk.maxBytes * 3)}';
    final post = await send('POST', '/', form: encode({'name': 'Omar', 's0': huge, 's1': huge}));
    expect(post.status, HttpStatus.requestEntityTooLarge);
    expect(host.room.players, isEmpty);
  });

  group('in the family game', () {
    setUp(() {
      host.update(
        (room) => room
            .withSubmission(playerId: 'a', name: 'Omar', inks: [testInk(1), testInk(2)])
            .withSubmission(playerId: 'b', name: 'Sara', inks: [testInk(3), testInk(4)])
            .withSubmission(playerId: 'c', name: 'Nour', inks: [drawing, testInk(6)])
            .startFamily(Random(2)),
      );
    });

    test('each handwritten slip is served as a PNG at /ink/<id>.png, revalidated by ETag', () async {
      final game = host.room.family!;
      final id = game.slips.indexWhere((s) => s.ink == drawing);
      final png = await send('GET', '/ink/$id.png');
      expect(png.status, HttpStatus.ok);
      expect(png.headers.contentType?.mimeType, 'image/png');
      expect(png.body, drawing.png);
      final etag = png.headers.value(HttpHeaders.etagHeader)!;

      final again = await send('GET', '/ink/$id.png', headers: {HttpHeaders.ifNoneMatchHeader: etag});
      expect(again.status, HttpStatus.notModified);
      expect(again.body, isEmpty);

      expect((await send('GET', '/ink/99.png')).status, HttpStatus.notFound);
      expect((await send('GET', '/ink/x.png')).status, HttpStatus.notFound);
    });

    test('the phone view flags handwritten slips, and the page draws them from /ink', () {
      final view = familyViewFor(host.room.family!, 'a');
      final slips = (view['slips']! as List).cast<Map<String, Object?>>();
      expect(slips.every((s) => s['ink'] == true), isTrue);
      final page = familyBody(const EnglishJoinStrings(), (s) => s, hostName: 'Mafdy');
      expect(page, contains("'/ink/' + x.id + '.png'"));
    });
  });

  test('there is no drawing to serve before a family game starts', () async {
    expect((await send('GET', '/ink/0.png')).status, HttpStatus.notFound);
  });
}
