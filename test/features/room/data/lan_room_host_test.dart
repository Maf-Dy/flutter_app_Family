import 'dart:convert';
import 'dart:io';

import 'package:family_game/features/room/data/lan_room_host.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LanRoomHost host;
  late HttpClient client;
  late int port;
  const cookie = '${LanRoomHost.cookieName}=0123456789abcdef0123456789abcdef';

  Future<({int status, String body, HttpHeaders headers})> send(
    String method,
    String path, {
    String? form,
    bool withCookie = true,
    String? language,
  }) async {
    final request = await client.openUrl(method, Uri.parse('http://127.0.0.1:$port$path'));
    request.followRedirects = false;
    if (withCookie) request.headers.set(HttpHeaders.cookieHeader, cookie);
    if (language != null) request.headers.set(HttpHeaders.acceptLanguageHeader, language);
    if (form != null) {
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write(form);
    }
    final response = await request.close();
    return (
      status: response.statusCode,
      body: await response.transform(utf8.decoder).join(),
      headers: response.headers,
    );
  }

  setUp(() async {
    host = LanRoomHost(preferredPort: 0);
    port = await host.open(
      const Room(
        code: 'K7Q4',
        category: GameCategory.custom('Famous <b>people</b>'),
        namesPerPlayer: 1,
        hostName: 'Mafdy',
      ),
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await host.close();
  });

  test('serves the join form, escaped, and gives new visitors an id cookie', () async {
    final page = await send('GET', '/', withCookie: false);
    expect(page.status, HttpStatus.ok);
    expect(page.body, contains('Famous &lt;b&gt;people&lt;/b&gt;'));
    expect(page.body, isNot(contains('<b>people</b>')));
    expect(page.body, contains('Drop it in the bowl'));
    expect(page.headers[HttpHeaders.setCookieHeader]?.single, startsWith('${LanRoomHost.cookieName}='));
  });

  test('a valid submission joins the room and shows the confirmation', () async {
    final joined = host.changes.first;
    final post = await send('POST', '/', form: 'name=Omar&s0=Lionel+Messi');
    expect(post.status, HttpStatus.seeOther);
    expect((await joined).players.single.name, 'Omar');
    expect(host.room.slipCount, 1);

    final page = await send('GET', '/');
    expect(page.body, contains('You’re in'));
    expect(page.body, isNot(contains('Lionel Messi')), reason: 'the confirmation never repeats the secret');

    final edit = await send('GET', '/?edit=1');
    expect(edit.body, contains('value="Lionel Messi"'), reason: 'your own phone can edit your slip');
  });

  test('an invalid submission keeps what was typed and explains the problem', () async {
    final post = await send('POST', '/', form: 'name=&s0=%3Cscript%3E');
    expect(post.status, HttpStatus.badRequest);
    expect(post.body, contains('Add your name'));
    expect(post.body, contains('value="&lt;script&gt;"'));
    expect(host.room.players, isEmpty);
  });

  test('a submission without an id cookie is not accepted', () async {
    final post = await send('POST', '/', form: 'name=Omar&s0=Messi', withCookie: false);
    expect(post.status, HttpStatus.badRequest);
    expect(host.room.players, isEmpty);
  });

  test('once reading starts, the bowl is closed', () async {
    host.update((room) => room.startReading());
    final post = await send('POST', '/', form: 'name=Omar&s0=Messi');
    expect(post.status, HttpStatus.conflict);
    expect(post.body, contains('Reading has started'));
    expect((await send('GET', '/')).body, contains('Reading has started'));
  });

  test('status reports the count and a version that changes with the page', () async {
    final before = jsonDecode((await send('GET', '/status')).body) as Map<String, Object?>;
    await send('POST', '/', form: 'name=Omar&s0=Messi');
    final after = jsonDecode((await send('GET', '/status')).body) as Map<String, Object?>;
    expect(before['count'], 0);
    expect(after['count'], 1);
    expect(after['version'], isNot(before['version']));
  });

  test('rejects oversized bodies and unknown paths', () async {
    expect((await send('POST', '/', form: 'name=${'x' * 9000}')).status, HttpStatus.requestEntityTooLarge);
    expect((await send('GET', '/admin')).status, HttpStatus.notFound);
  });

  test('speaks Egyptian Arabic, right to left, to Arabic phones', () async {
    final page = await send('GET', '/', language: 'ar-EG,ar;q=0.9,en;q=0.8');
    expect(page.body, contains('dir="rtl"'));
    expect(page.body, contains('ارميه في الطبق'));
    final english = await send('GET', '/', language: 'en-US');
    expect(english.body, contains('dir="ltr"'));
  });

  test('lets friends pick a team when the room allows it', () async {
    await host.close();
    host = LanRoomHost(preferredPort: 0);
    port = await host.open(
      const Room(
        code: 'K7Q4',
        category: GameCategory.preset(PresetCategory.movies),
        namesPerPlayer: 1,
        hostName: 'Mafdy',
        mode: GameMode.celebrity,
        teamSetup: TeamSetup(count: 3, pick: TeamPick.players),
      ),
    );
    final form = await send('GET', '/');
    expect(form.body, contains('name="team" value="2"'));
    expect(form.body, contains('Green team'));

    final missing = await send('POST', '/', form: 'name=Omar&s0=Up');
    expect(missing.status, HttpStatus.badRequest);
    expect(missing.body, contains('Pick one of the teams'));

    await send('POST', '/', form: 'name=Omar&s0=Up&team=2');
    expect(host.room.players.single.team, 2);
    expect((await send('GET', '/')).body, contains('team-badge'));
  });
}
