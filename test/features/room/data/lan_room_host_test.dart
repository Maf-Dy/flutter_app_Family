import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:family_game/features/room/data/family_view.dart';
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
    String? as,
    String? language,
  }) async {
    final request = await client.openUrl(method, Uri.parse('http://127.0.0.1:$port$path'));
    request.followRedirects = false;
    if (as != null) {
      request.headers.set(HttpHeaders.cookieHeader, '${LanRoomHost.cookieName}=$as');
    } else if (withCookie) {
      request.headers.set(HttpHeaders.cookieHeader, cookie);
    }
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

  group('family online', () {
    // Friends' ids, as their cookies carry them.
    final omar = 'a' * 32;
    final nour = 'b' * 32;
    final yara = 'c' * 32;

    Map<String, Object?> json(String body) => jsonDecode(body) as Map<String, Object?>;

    /// How phones name a player: never by their cookie.
    String pub(String id) => familyPublicId(host.room.family!, id);

    setUp(() async {
      await host.close();
      host = LanRoomHost(preferredPort: 0);
      port = await host.open(
        const Room(
          code: 'K7Q4',
          category: GameCategory.preset(PresetCategory.movies),
          namesPerPlayer: 1,
          hostName: 'Mafdy',
          mode: GameMode.family,
        ),
      );
      await send('POST', '/', form: 'name=Omar&s0=Up', as: omar);
      await send('POST', '/', form: 'name=Nour&s0=Coco', as: nour);
      await send('POST', '/', form: 'name=Yara&s0=Heat', as: yara);
    });

    test('there is no game until the host starts one', () async {
      expect((await send('GET', '/game', as: omar)).status, HttpStatus.notFound);
      host.update((room) => room.startFamily(Random(1)));
      final page = await send('GET', '/', as: omar);
      expect(page.body, contains('FAMILY_STRINGS'));
      expect((await send('POST', '/', form: 'name=Late&s0=Jaws')).status, HttpStatus.conflict);
    });

    test('each phone sees itself, and no hidden writers', () async {
      host.update((room) => room.startFamily(Random(1)));
      final view = json((await send('GET', '/game', as: nour)).body);
      expect(view['me'], pub(nour));
      expect(view['myHead'], pub(nour));
      final slips = (view['slips']! as List<Object?>).cast<Map<String, Object?>>();
      expect(slips.map((s) => s['text']), unorderedEquals(['Up', 'Coco', 'Heat']));
      expect(slips.every((s) => !s.containsKey('writer')), isTrue);

      final stranger = json((await send('GET', '/game')).body);
      expect(stranger['me'], isNull, reason: 'someone who joined late only watches');
    });

    test('moves go through the rules, and the right answer merges families', () async {
      host.update((room) => room.startFamily(Random(1)));
      final game = host.room.family!;
      final turn = game.turn;
      final other = [omar, nour, yara].firstWhere((id) => id != turn);
      final otherSlip = game.slips.firstWhere((s) => s.writerId == other).id;

      final early = await send('POST', '/game/guess', form: 'target=${pub(turn)}&slip=$otherSlip', as: other);
      expect(early.status, HttpStatus.conflict);
      expect(json(early.body)['error'], 'notYourTurn');

      final byCookie = await send('POST', '/game/guess', form: 'target=$other&slip=$otherSlip', as: turn);
      expect(json(byCookie.body)['error'], 'invalidTarget', reason: 'players are named by public id only');

      final right = await send('POST', '/game/guess', form: 'target=${pub(other)}&slip=$otherSlip', as: turn);
      expect(right.status, HttpStatus.ok);
      expect(json(right.body)['error'], isNull);
      expect(host.room.family!.headOf(other), turn);

      final notHead = await send('POST', '/game/guess', form: 'target=${pub(turn)}&slip=$otherSlip', as: other);
      expect(json(notHead.body)['error'], 'notHead');

      final watcher = await send('POST', '/game/say', form: 'text=hi');
      expect(watcher.status, HttpStatus.forbidden);
      expect(json(watcher.body)['error'], 'notPlaying');
    });

    test('chat and ideas stay inside the family', () async {
      host.update((room) => room.startFamily(Random(1)));
      await send('POST', '/game/say', form: 'text=${Uri.encodeQueryComponent('Nour wrote Coco')}', as: omar);
      final game = host.room.family!;
      final heat = game.slips.firstWhere((s) => s.writerId == yara).id;
      await send('POST', '/game/suggest', form: 'target=${pub(yara)}&slip=$heat', as: omar);
      expect(host.room.family!.suggestionsFor(omar).single.voters, {omar});

      final mine = json((await send('GET', '/game', as: omar)).body);
      expect((mine['chat']! as List<Object?>), hasLength(1));
      expect((mine['ideas']! as List<Object?>), hasLength(1));
      final theirs = json((await send('GET', '/game', as: nour)).body);
      expect(theirs['chat'], isEmpty);
      expect(theirs['ideas'], isEmpty);

      final blank = await send('POST', '/game/say', form: 'text=%20%20', as: omar);
      expect(json(blank.body)['error'], 'emptyMessage');
    });

    test('a phone that goes quiet shows as offline, and is back as soon as it calls again', () async {
      var now = DateTime(2026, 9, 28, 20);
      await host.close();
      host = LanRoomHost(preferredPort: 0, clock: () => now, presenceTick: const Duration(hours: 1));
      port = await host.open(
        const Room(
          code: 'K7Q4',
          category: GameCategory.preset(PresetCategory.movies),
          namesPerPlayer: 1,
          hostName: 'Mafdy',
          mode: GameMode.family,
        ),
      );
      await send('POST', '/', form: 'name=Omar&s0=Up', as: omar);
      await send('POST', '/', form: 'name=Nour&s0=Coco', as: nour);
      await send('POST', '/', form: 'name=Yara&s0=Heat', as: yara);
      host.update((room) => room.startFamily(Random(1)));
      for (final id in [omar, nour, yara]) {
        await send('GET', '/game', as: id);
      }

      now = now.add(const Duration(seconds: 4));
      await send('GET', '/game', as: omar);
      await send('GET', '/game', as: nour);
      now = now.add(const Duration(seconds: 4));
      host.checkPresence();
      expect(host.room.family!.away, {yara}, reason: 'Yara has been quiet for 8 seconds');

      final seen = json((await send('GET', '/game', as: omar)).body);
      expect(seen['away'], [pub(yara)]);

      await send('GET', '/game', as: yara);
      expect(host.room.family!.away, isEmpty, reason: 'one call and she is back');
    });

    test('a new browser takes back a dropped seat once the host says yes', () async {
      host.update((room) => room.startFamily(Random(1)));
      host.update((room) => room.withFamily(room.family!.withAway({nour})));
      final stranger = 'd' * 32;

      final watching = json((await send('GET', '/game', as: stranger)).body);
      expect(watching['me'], isNull);
      expect((watching['claimable']! as List<Object?>).single, {'id': pub(nour), 'name': 'Nour'});
      expect(watching.toString(), isNot(contains(nour)), reason: 'a cookie value would let anyone be Nour');

      final taken = await send('POST', '/game/claim', form: 'player=${pub(omar)}', as: stranger);
      expect(taken.status, HttpStatus.conflict, reason: 'Omar is still playing');
      expect((await send('POST', '/game/claim', form: 'player=${pub(nour)}', as: stranger)).status, HttpStatus.ok);
      expect(json((await send('GET', '/game', as: stranger)).body)['myClaim'], {
        'player': pub(nour),
        'status': 'pending',
      });

      host.update((room) => room.withFamily(room.family!.resolveClaim(stranger, approve: true)));
      final back = await send('GET', '/game', as: stranger);
      expect(json(back.body)['me'], pub(nour));
      final cookie = back.headers[HttpHeaders.setCookieHeader]!.single;
      expect(cookie, startsWith('${LanRoomHost.cookieName}=$nour'), reason: 'from now on this browser is Nour');
      expect(host.room.family!.claims, isEmpty);
      expect(host.room.family!.away, isEmpty);
    });

    test('a browser the host turned away can\'t ask for that seat again', () async {
      host.update((room) => room.startFamily(Random(1)));
      host.update((room) => room.withFamily(room.family!.withAway({nour})));
      final stranger = 'd' * 32;
      await send('POST', '/game/claim', form: 'player=${pub(nour)}', as: stranger);
      host.update((room) => room.withFamily(room.family!.resolveClaim(stranger, approve: false)));

      final again = await send('POST', '/game/claim', form: 'player=${pub(nour)}', as: stranger);
      expect(again.status, HttpStatus.conflict);
      expect(host.room.family!.pendingClaims, isEmpty);
    });

    test('a resent chat message is posted once', () async {
      host.update((room) => room.startFamily(Random(1)));
      for (var i = 0; i < 2; i++) {
        final sent = await send('POST', '/game/say', form: 'text=hi&cid=k3j9x2', as: omar);
        expect(json(sent.body)['error'], isNull);
      }
      await send('POST', '/game/say', form: 'text=hi&cid=k3j9x3', as: omar);
      expect(host.room.family!.chat, hasLength(2));
    });

    group('presence', () {
      late DateTime now;

      setUp(() async {
        now = DateTime(2026, 9, 28, 20);
        await host.close();
        host = LanRoomHost(preferredPort: 0, clock: () => now, presenceTick: const Duration(hours: 1));
        port = await host.open(
          const Room(
            code: 'K7Q4',
            category: GameCategory.preset(PresetCategory.movies),
            namesPerPlayer: 1,
            hostName: 'Mafdy',
            mode: GameMode.family,
          ),
        );
        await send('POST', '/', form: 'name=Omar&s0=Up', as: omar);
        await send('POST', '/', form: 'name=Nour&s0=Coco', as: nour);
        host.update((room) => room.startFamily(Random(1)));
        host.checkPresence();
      });

      test('a new game gives everyone a fresh start, however long the last round took', () async {
        now = now.add(const Duration(minutes: 5));
        host.update((room) => room.nextRound());
        await send('POST', '/', form: 'name=Omar&s0=Jaws', as: omar);
        await send('POST', '/', form: 'name=Nour&s0=Cars', as: nour);
        host.update((room) => room.startFamily(Random(2)));
        host.checkPresence();
        expect(host.room.family!.away, isEmpty);
      });

      test('after the host\'s phone slept, no one is marked offline until they had time to call', () async {
        now = now.add(const Duration(minutes: 1));
        host.resetPresence();
        host.checkPresence();
        expect(host.room.family!.away, isEmpty);
        now = now.add(const Duration(seconds: 7));
        host.checkPresence();
        expect(host.room.family!.away, {omar, nour});
      });
    });

    test('the family page speaks Egyptian Arabic to Arabic phones', () async {
      host.update((room) => room.startFamily(Random(1)));
      final page = await send('GET', '/', as: omar, language: 'ar-EG,ar;q=0.9');
      expect(page.body, contains('dir="rtl"'));
      expect(page.body, contains('دردشة العيلة'));
      expect(page.body, contains('مين اللي كتبه؟'));
      expect(page.body, isNot(contains('Family chat')));
      // Cards the script hides (a watcher's pickers, the pickers after a win) must stay hidden
      // even when their own style sets a display.
      expect(page.body, contains('[hidden]{display:none!important}'));
    });
  });
}
