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

  /// A friend's move, as if it came from their browser.
  void friendMove(FamilyGame Function(FamilyGame game) move) =>
      host.update((room) => room.withFamily(move(room.family!)));

  int slipOf(String writer) => host.room.family!.slips.firstWhere((s) => s.writerId == writer).id;

  /// New room in family mode, two friends and the host's own name in, then play.
  Future<void> openFamilyRoom(WidgetTester tester, {bool hostPlays = true}) async {
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Family online'));
    expect(find.text('Family chat'), findsOneWidget, reason: 'the chat switch shows only for this mode');
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
        await pick<int>(tester, 'Messi');
        await tapVisible(tester, find.text('Ask!'));
        expect(host.room.family!.headOf('a'), Player.hostId);
        expect(find.textContaining('caught Omar'), findsOneWidget);

        // Omar, now family, backs an idea and chats; the host sees both.
        friendMove((g) => g.suggest('a', 'b', slipOf('b')).say('a', 'It was Nour!'));
        await tester.pumpAndSettle();
        expect(find.text('Nour wrote “Fairuz”?'), findsOneWidget);
        expect(find.text('It was Nour!'), findsOneWidget);
        await tester.ensureVisible(find.widgetWithText(TextField, 'Only your family sees this'));
        await tester.enterText(find.widgetWithText(TextField, 'Only your family sees this'), 'On it');
        await tapVisible(tester, find.byTooltip('Send'));
        expect(host.room.family!.chatFor(Player.hostId).map((m) => m.text), ['It was Nour!', 'On it']);

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

  testWidgets('a member suggests instead of asking, and turning chat off hides it', (tester) async {
    await pumpApp(tester, size: sizes['portrait']!);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Family online'));
    await tapVisible(tester, find.text('Family chat'));
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
    expect(find.text('Only your family sees this'), findsNothing, reason: 'chat is off in this room');

    await pick<String>(tester, 'Nour');
    await pick<int>(tester, 'Fairuz');
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
      await pick<int>(tester, 'محمد صلاح');
      await tapVisible(tester, find.text('اسأل!'));
      await pick<String>(tester, 'نور');
      await pick<int>(tester, 'أبو تريكة');
      await tapVisible(tester, find.text('اسأل!'));
      expect(find.text('عيلتك كسبت يا وحوش!'), findsOneWidget);
      expect(find.text('دور جديد، نفس القعدة'), findsOneWidget);
    });
  }
}
