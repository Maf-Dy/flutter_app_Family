import 'package:family_game/features/family/domain/family_game.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

/// The host's family screen, at phone portrait and landscape, in both text directions.
void main() {
  const sizes = {'portrait': Size(360, 800), 'landscape': Size(800, 360)};

  late FakeNetwork network;
  late FakeRoomHost host;

  setUp(() => network = FakeNetwork(address: '192.168.1.23'));
  tearDown(() => network.dispose());

  Future<void> pumpApp(WidgetTester tester, {required Size size, TextDirection? direction, Locale? locale}) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        network: network,
        createHost: () => host = FakeRoomHost(),
        direction: direction,
        locale: locale ?? const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Opens a dropdown and picks [item] from its menu.
  Future<void> pick<T>(WidgetTester tester, String item) async {
    await tapVisible(tester, find.byType(DropdownButton<T>));
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  /// Types a name from memory, as players do: no list of names to pick from.
  Future<void> typeName(WidgetTester tester, String name) async {
    final field = find.byKey(const ValueKey('family-name'));
    await tester.ensureVisible(field);
    await tester.enterText(field, name);
    await tester.pumpAndSettle();
  }

  /// A friend's move, as if it came from their browser.
  void friendMove(FamilyGame Function(FamilyGame game) move) =>
      host.update((room) => room.withFamily(move(room.family!)));

  int slipOf(String writer) => host.room.family!.slips.firstWhere((s) => s.writerId == writer).id;

  /// New room in family mode, two friends and the host's own name in, then play.
  Future<void> openFamilyRoom(WidgetTester tester, {bool hostPlays = true}) async {
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Family online'));
    expect(find.text('Family chat'), findsNothing, reason: 'families back ideas instead of chatting');
    await tapVisible(tester, find.text('Open room'));
    host
      ..join('a', 'Omar', ['Messi'])
      ..join('b', 'Nour', ['Fairuz']);
    if (!hostPlays) host.join('c', 'Yara', ['Adele']);
    await tester.pumpAndSettle();
    if (hostPlays) {
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Umm Kulthum');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, find.text("Let's play"));
    expect(host.room.family, isNotNull);
  }

  /// Whoever's turn it is asks the host wrongly, so the turn comes to the host.
  Future<void> handTurnToHost(WidgetTester tester) async {
    final game = host.room.family!;
    if (game.turn != Player.hostId) {
      final asker = game.turn;
      final other = asker == 'a' ? 'b' : 'a';
      friendMove((g) => g.guess(asker, Player.hostId, slipOf(other)));
      await tester.pumpAndSettle();
    }
    expect(host.room.family!.turn, Player.hostId);
  }

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final direction in TextDirection.values) {
      testWidgets('the host plays a family game to the end: $sizeName, ${direction.name}', (tester) async {
        await pumpApp(tester, size: size, direction: direction);
        await openFamilyRoom(tester);
        await handTurnToHost(tester);
        expect(find.textContaining("Your family's turn!"), findsOneWidget);

        // Asking with an empty picker explains itself.
        await tapVisible(tester, find.text('Ask!'));
        expect(find.text('Pick a person and a name first.'), findsOneWidget);

        // The host catches Omar: he joins and it stays the host's turn.
        await pick<String>(tester, 'Omar');
        await typeName(tester, 'Messi');
        await tapVisible(tester, find.text('Ask!'));
        expect(host.room.family!.headOf('a'), Player.hostId);
        expect(find.textContaining('caught Omar'), findsOneWidget);

        // Omar, now family, backs an idea; the host sees it, and there's no chat.
        friendMove((g) => g.suggest('a', 'b', slipOf('b')));
        await tester.pumpAndSettle();
        expect(find.text('Nour wrote “Fairuz”?'), findsOneWidget);
        expect(find.text('Only your family sees this'), findsNothing);
        expect(find.text('Fairuz'), findsNothing, reason: 'names not out yet stay off the board');

        // The host takes the family's idea and wins.
        await tapVisible(tester, find.text('Use'));
        await tapVisible(tester, find.text('Ask!'));
        expect(host.room.family!.isOver, isTrue);
        expect(find.text('Your family won!'), findsOneWidget);

        await tapVisible(tester, find.byTooltip('Share this night'));
        expect(find.text('Share'), findsWidgets);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('New round, same room'));
        expect(find.text("Bowl's empty"), findsOneWidget);
        expect(host.room.family, isNull);
        expect(host.room.round, 2);
      });
    }
  }

  testWidgets('a host who put no name in watches, and can leave back to the lobby', (tester) async {
    await pumpApp(tester, size: sizes['portrait']!);
    await openFamilyRoom(tester, hostPlays: false);
    expect(find.textContaining("You're watching"), findsOneWidget);
    expect(find.text('Ask!'), findsNothing);
    expect(find.text('Suggest to the family'), findsNothing);
    expect(find.text('Families'), findsOneWidget);

    // A friend's guess shows up on the board.
    final game = host.room.family!;
    final asker = game.turn;
    final target = game.players.firstWhere((p) => p.id != asker).id;
    friendMove((g) => g.guess(asker, target, slipOf(target)));
    await tester.pumpAndSettle();
    expect(find.textContaining('caught ${game.nameOf(target)}'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave this game?'), findsOneWidget);
    await tapVisible(tester, find.text('Leave'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(host.room.family, isNull, reason: 'friends go back to the join form');
    expect(host.room.isCollecting, isTrue);
    expect(host.room.slipCount, 3, reason: 'the names stay in the bowl');
  });

  testWidgets('a member suggests instead of asking, and there is no chat', (tester) async {
    await pumpApp(tester, size: sizes['portrait']!);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Family online'));
    await tapVisible(tester, find.text('Open room'));
    expect(host.room.familyChat, isFalse);
    host
      ..join('a', 'Omar', ['Messi'])
      ..join('b', 'Nour', ['Fairuz']);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Umm Kulthum');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text("Let's play"));

    // Omar catches the host, so the host is a member of Omar's family.
    var game = host.room.family!;
    if (game.turn != 'a') {
      friendMove((g) => g.guess(g.turn, 'a', slipOf(g.turn == 'b' ? Player.hostId : 'b')));
      game = host.room.family!;
    }
    expect(game.turn, 'a');
    friendMove((g) => g.guess('a', Player.hostId, slipOf(Player.hostId)));
    await tester.pumpAndSettle();

    expect(find.text("Omar's family"), findsWidgets);
    expect(find.textContaining('Omar makes the guess.'), findsOneWidget);
    expect(find.text('Ask!'), findsNothing);
    expect(find.text('Only your family sees this'), findsNothing, reason: 'there is no chat');

    await pick<String>(tester, 'Nour');
    await typeName(tester, 'Fairuz');
    await tapVisible(tester, find.text('Suggest to the family'));
    final ideas = host.room.family!.suggestionsFor('a');
    expect(ideas.single.voters, {Player.hostId});
    expect(find.text('Backed'), findsOneWidget);
    await tapVisible(tester, find.text('Backed'));
    expect(host.room.family!.suggestionsFor('a'), isEmpty);
  });

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    testWidgets('Egyptian Arabic, right to left, fits: $sizeName', (tester) async {
      await pumpApp(tester, size: size, locale: const Locale('ar'));
      await tapVisible(tester, find.text('افتح قعدة'));
      await tapVisible(tester, find.text('العيلة أونلاين'));
      await tapVisible(tester, find.text('افتح القعدة'));
      host
        ..join('a', 'عمر', ['محمد صلاح'])
        ..join('b', 'نور', ['أبو تريكة']);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'أم كلثوم');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('يلا بينا'));
      await handTurnToHost(tester);
      expect(find.textContaining('دور عيلتك!'), findsOneWidget);
      await pick<String>(tester, 'عمر');
      await typeName(tester, 'محمد صلاح');
      await tapVisible(tester, find.text('اسأل!'));
      await pick<String>(tester, 'نور');
      await typeName(tester, 'أبو تريكة');
      await tapVisible(tester, find.text('اسأل!'));
      expect(find.text('عيلتك كسبت يا وحوش!'), findsOneWidget);
      expect(find.text('دور جديد، نفس القعدة'), findsOneWidget);
    });
  }

  group('when phones drop out', () {
    void away(Set<String> ids) => friendMove((g) => g.withAway(ids));

    testWidgets('the host lets a friend on a new phone back in, and can turn a stranger away', (tester) async {
      await pumpApp(tester, size: sizes['portrait']!);
      await openFamilyRoom(tester);
      away({'a'});
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.wifi_off_rounded), findsWidgets, reason: 'Omar is marked offline');

      friendMove((g) => g.claimSeat('x', 'a'));
      await tester.pumpAndSettle();
      expect(find.text('Someone wants back in as Omar'), findsOneWidget);
      await tapVisible(tester, find.text('Let them in'));
      expect(host.room.family!.claimOf('x')!.status, ClaimStatus.approved);
      expect(find.text('Someone wants back in as Omar'), findsNothing);

      friendMove((g) => g.claimSeat('y', 'a'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Not them'));
      expect(host.room.family!.claimOf('y')!.status, ClaimStatus.denied);
    });

    testWidgets('a family whose phones all dropped can be skipped, never automatically', (tester) async {
      await pumpApp(tester, size: sizes['portrait']!);
      await openFamilyRoom(tester);
      var game = host.room.family!;
      if (game.turn == Player.hostId) {
        // The host asks Omar wrongly, which hands Omar the turn.
        await pick<String>(tester, 'Omar');
        await typeName(tester, 'Fairuz');
        await tapVisible(tester, find.text('Ask!'));
        game = host.room.family!;
      }
      final stuck = game.turn;
      away({stuck});
      await tester.pumpAndSettle();
      expect(find.text("${game.nameOf(stuck)}'s family is offline."), findsOneWidget);
      expect(host.room.family!.turn, stuck, reason: 'nobody is skipped by the app itself');
      await tapVisible(tester, find.text('Skip their turn'));
      expect(host.room.family!.turn, isNot(stuck));
      expect(find.text('Skip their turn'), findsNothing);
    });

    testWidgets('the host asks for their family while its head is offline', (tester) async {
      await pumpApp(tester, size: sizes['portrait']!);
      await openFamilyRoom(tester);
      // Omar catches the host, so the host is in Omar's family, and it's Omar's turn again.
      var game = host.room.family!;
      if (game.turn != 'a') {
        friendMove((g) => g.guess(g.turn, 'a', slipOf(g.turn == 'b' ? Player.hostId : 'b')));
        game = host.room.family!;
      }
      friendMove((g) => g.guess('a', Player.hostId, slipOf(Player.hostId)));
      await tester.pumpAndSettle();
      expect(find.text('Ask!'), findsNothing);

      away({'a'});
      await tester.pumpAndSettle();
      expect(find.text("Your family's turn! Omar is offline, so you ask."), findsOneWidget);
      await pick<String>(tester, 'Nour');
      await typeName(tester, 'Fairuz');
      await tapVisible(tester, find.text('Ask!'));
      expect(host.room.family!.isOver, isTrue);
      expect(host.room.family!.winner, 'a', reason: 'the family is still Omar\'s');
    });

    testWidgets('the join code is one tap away, for anyone who has to scan back in', (tester) async {
      await pumpApp(tester, size: sizes['portrait']!);
      await openFamilyRoom(tester);
      await tester.tap(find.byTooltip('Show the join code'));
      await tester.pumpAndSettle();
      expect(find.text('Anyone who dropped out can scan this to get back in.'), findsOneWidget);
      expect(find.text(host.room.code), findsOneWidget);
    });
  });
}
