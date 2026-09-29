import 'package:family_game/features/room/domain/network_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

/// Every screen at phone portrait and landscape, in both text directions.
/// Layout overflow fails a widget test, so these also guard against clipping.
void main() {
  const sizes = {'portrait': Size(360, 800), 'landscape': Size(800, 360)};
  const directions = [TextDirection.ltr, TextDirection.rtl];

  late FakeNetwork network;
  late FakeRoomHost host;

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    required TextDirection direction,
    bool dark = false,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(network: network, createHost: () => host = FakeRoomHost(), direction: direction, dark: dark),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() => network = FakeNetwork(address: '192.168.1.23'));
  tearDown(() => network.dispose());

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final direction in directions) {
      testWidgets('whole game flow fits: $sizeName, ${direction.name}', (tester) async {
        await pumpApp(tester, size: size, direction: direction);

        // Home
        expect(find.text('Who wrote\nwhat?'), findsOneWidget);
        await tapVisible(tester, find.text('Host a room'));

        // New room
        expect(find.text('New room'), findsOneWidget);
        await tapVisible(tester, find.text('Movies'));
        await tapVisible(tester, find.byTooltip('More names'));
        expect(find.text('Connected'), findsOneWidget);
        await tapVisible(tester, find.text('Open room'));

        // Lobby
        expect(find.textContaining('Room open'), findsOneWidget);
        expect(find.text('http://192.168.1.23:8182'.replaceFirst('http://', '')), findsOneWidget);
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Start reading')).onPressed, isNull);
        host
          ..join('a', 'Omar', ['Lionel Messi', 'Adele'])
          ..join('b', 'Nour', ['Fairuz', 'Mr. Bean']);
        await tester.pumpAndSettle();
        expect(find.text('4 in the bowl'), findsOneWidget);
        expect(find.text('Omar'), findsOneWidget);
        expect(find.text('Lionel Messi'), findsNothing, reason: 'the host never sees what friends wrote');

        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Umm Kulthum');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Salah');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('6 in the bowl'), findsOneWidget);
        await tapVisible(tester, find.text('Start reading'));

        // Read aloud, twice through
        expect(find.text('Read aloud'), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          await tapVisible(tester, find.text('Next name'));
        }
        expect(find.text('6 / 6'), findsOneWidget);
        await tapVisible(tester, find.text('Read again'));
        expect(find.text('1 / 6'), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          await tapVisible(tester, find.text('Next name'));
        }
        await tapVisible(tester, find.text('Done reading'));

        // Names on the table
        expect(find.text('Names on the table'), findsOneWidget);
        expect(find.text('Lionel Messi'), findsNothing, reason: 'the slips lie folded: the game is played from memory');
        await tapVisible(tester, find.text('Who wrote what?'));

        // Who wrote what
        expect(find.text('Nour'), findsNothing);
        await tapVisible(tester, find.text('Reveal all'));
        await tapVisible(tester, find.text('New round, same room'));

        // Back in the lobby with an empty bowl and the same players
        expect(find.text('Bowl\'s empty'), findsOneWidget);
        expect(find.text('Omar'), findsOneWidget);
        expect(host.room.round, 2);
      });

      testWidgets('no Wi-Fi: create hotspot, then two codes ($sizeName, ${direction.name})', (tester) async {
        network = FakeNetwork();
        await pumpApp(tester, size: size, direction: direction, dark: true);
        await tapVisible(tester, find.text('Host a room'));
        expect(find.text('No Wi-Fi here'), findsOneWidget);
        await tapVisible(tester, find.text('Open room'));

        expect(find.text('No Wi-Fi around'), findsOneWidget);
        await tapVisible(tester, find.text('Create hotspot'));
        expect(find.text('Join the Wi-Fi'), findsOneWidget);
        expect(find.text('AndroidShare_1234'), findsOneWidget);
        await tapVisible(tester, find.text('Next'));
        expect(find.text('THEN SCAN THIS'), findsOneWidget);
      });
    }
  }

  testWidgets('hotspot failure explains itself and offers Settings', (tester) async {
    network = FakeNetwork(hotspotResult: const HotspotFailed(HotspotFailure.permissionBlocked));
    await pumpApp(tester, size: sizes['portrait']!, direction: TextDirection.ltr);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Open room'));
    await tapVisible(tester, find.text('Create hotspot'));
    expect(find.textContaining('Allow it in Settings'), findsOneWidget);
    await tapVisible(tester, find.text('Open settings'));
    expect(network.settingsCalls, 1);
  });

  testWidgets('a link that does not open explains why and offers the hotspot', (tester) async {
    network = FakeNetwork(address: '192.168.1.23', onWifi: true, reachable: false);
    await pumpApp(tester, size: sizes['portrait']!, direction: TextDirection.ltr);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Open room'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('couldn\'t open its own link'), findsOneWidget);

    await tapVisible(tester, find.text('Link not opening?'));
    expect(find.textContaining('guest Wi-Fi'), findsOneWidget);
    await tapVisible(tester, find.text('Use a hotspot instead'));
    expect(find.text('Join the Wi-Fi'), findsOneWidget);
    expect(find.textContaining('doesn\'t show in your phone\'s Hotspot settings'), findsOneWidget);
  });

  testWidgets('closing a room with players asks first', (tester) async {
    await pumpApp(tester, size: sizes['portrait']!, direction: TextDirection.ltr);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Open room'));
    host.join('a', 'Omar', ['Messi']);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Close room'));
    expect(find.text('Close the room?'), findsOneWidget);
    await tapVisible(tester, find.text('Close room'));
    // The pop callback resumes outside the test's fake clock; let it finish.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('New room'), findsOneWidget);
    expect(host.closed, isTrue);
  });

  testWidgets('animations run without errors when motion is on', (tester) async {
    tester.view
      ..physicalSize = sizes['portrait']!
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(network: network, createHost: () => host = FakeRoomHost(), reducedMotion: false));
    // Looping animations never settle, so step frames instead of pumpAndSettle.
    Future<void> frames([int count = 40]) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> tapAndRun(String text) async {
      await tester.tap(find.text(text));
      await frames();
    }

    await frames();
    await tapAndRun('Host a room');
    await tapAndRun('Open room');
    host
      ..join('a', 'Omar', ['Messi'])
      ..join('b', 'Nour', ['Fairuz'])
      ..join('c', 'Yara', ['Adele']);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Omar\'s name is in'), findsOneWidget, reason: 'arrivals are announced one at a time');
    await frames(160);
    expect(find.text('3 in the bowl'), findsOneWidget);
    expect(find.textContaining('name is in'), findsNothing, reason: 'every banner has come and gone');

    await tester.tap(find.text('Start reading'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Shuffling 3 names…'), findsOneWidget);
    await frames();
    expect(find.text('Read aloud'), findsOneWidget);
    await tapAndRun('Next name');
    await tapAndRun('Next name');
    await tapAndRun('Done reading');
    await tapAndRun('Who wrote what?');
    await tapAndRun('Reveal all');
    await frames(40);
    expect(find.text('That\'s all of them!'), findsOneWidget);
    expect(find.text('New round, same room'), findsOneWidget);
    await tapAndRun('New round, same room');
    expect(find.text('Bowl\'s empty'), findsOneWidget);
  });

  testWidgets('tapping the shuffle skips straight to the first name', (tester) async {
    tester.view
      ..physicalSize = sizes['portrait']!
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(network: network, createHost: () => host = FakeRoomHost(), reducedMotion: false));
    Future<void> frames(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.tap(find.text('Host a room'));
    await frames(20);
    await tester.tap(find.text('Open room'));
    await frames(20);
    host
      ..join('a', 'Omar', ['Messi'])
      ..join('b', 'Nour', ['Fairuz'])
      ..join('c', 'Yara', ['Adele']);
    await frames(120);
    await tester.tap(find.text('Start reading'));
    // Wait out the page transition (it ignores taps), but not the shuffle itself.
    await frames(10);
    expect(find.text('Shuffling 3 names…'), findsOneWidget);
    await tester.tap(find.text('Shuffling 3 names…'));
    await frames(12);
    expect(find.text('Shuffling 3 names…'), findsNothing);
    expect(find.text('Read aloud'), findsOneWidget);
  });

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    testWidgets('Egyptian Arabic, right to left, fits: $sizeName', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(network: network, createHost: () => host = FakeRoomHost(), locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();
      expect(find.text('مين كتب\nإيه؟'), findsOneWidget);
      await tapVisible(tester, find.text('افتح قعدة'));
      await tapVisible(tester, find.text('لعيبة كورة'));
      await tapVisible(tester, find.byType(Switch).first);
      expect(find.textContaining('ممنوع'), findsOneWidget);
      await tapVisible(tester, find.text('افتح القعدة'));
      host
        ..join('a', 'عمر', ['محمد صلاح'])
        ..join('b', 'نور', ['أبو تريكة']);
      await tester.pumpAndSettle();
      expect(find.text('اسمين في الطبق'), findsOneWidget);
      expect(find.text('Mafdy (إنت)'), findsOneWidget, reason: 'the host appears under their chosen name');

      // Same name twice is off: the host is told, and the field keeps the text.
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'ابو تريكه');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('حد سبقك'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'حسام حسن');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('ناقص واحد كمان ونبدأ'), findsNothing);

      await tapVisible(tester, find.text('يلا نقرا'));
      expect(find.text('اقرا بصوت عالي'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tapVisible(tester, find.text('اللي بعده'));
      }
      await tapVisible(tester, find.text('خلصنا قراية'));
      await tapVisible(tester, find.text('مين كتب إيه؟'));
      await tapVisible(tester, find.text('افضح الكل'));
      expect(find.text('دور جديد، نفس القعدة'), findsOneWidget);
    });
  }

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final direction in directions) {
      testWidgets('face-off plays to the end: $sizeName, ${direction.name}', (tester) async {
        await pumpApp(tester, size: size, direction: direction);
        await tapVisible(tester, find.text('Host a room'));
        await tapVisible(tester, find.text('Face-off'));
        await tapVisible(tester, find.text('I arrange'));
        await tapVisible(tester, find.text('Open room'));
        host
          ..join('a', 'Omar', ['Messi', 'Salah', 'Zidane'])
          ..join('b', 'Nour', ['Fairuz', 'Amr Diab', 'Sherine'])
          ..join('c', 'Yara', ['Adele', 'Shakira', 'Beyonce'])
          ..join('d', 'Sami', ['Mr. Bean', 'Adel Imam', 'Chaplin']);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text("Let's play"));

        // Teams: moving Omar leaves his team with one player, so the game can't start; moving him back fixes it.
        expect(find.text('Purple team'), findsOneWidget);
        await tapVisible(tester, find.widgetWithText(ActionChip, 'Omar'));
        expect(find.text('Needs at least 2 players, so the other team has someone to choose from.'), findsOneWidget);
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, "Let's play")).onPressed, isNull);
        await tapVisible(tester, find.widgetWithText(ActionChip, 'Omar'));
        expect(find.text('How to play'), findsOneWidget);
        await tapVisible(tester, find.text("Let's play"));

        // Face-off starts at 3 names each; each name comes out once, and the first guess is a double bet.
        for (var i = 0; i < 12; i++) {
          expect(find.text('Who on the other team wrote it?'), findsOneWidget);
          expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Pick who wrote it')).onPressed, isNull);
          await tapVisible(tester, find.byType(ChoiceChip).first);
          if (i == 0) await tapVisible(tester, find.text('Bet double'));
          await tapVisible(tester, find.textContaining('wrote it!'));
          // Right or wrong only: who wrote it stays secret until the results.
          expect(find.textContaining(RegExp(r'^(Right|Wrong)!$')), findsOneWidget);
          expect(find.textContaining('wrote \u201c'), findsNothing);
          expect(find.textContaining('said'), findsNothing);
          expect(find.text('Who wrote what stays secret until the end.'), findsOneWidget);
          if (i == 0) expect(find.text('It was a double bet.'), findsOneWidget);
          await tapVisible(tester, find.text(i < 11 ? 'Next team' : 'See results'));
        }
        expect(find.textContaining(RegExp('wins!|draw')), findsOneWidget);
        // The results reveal every writer, and how the guessing team did.
        await tester.scrollUntilVisible(find.text('Who wrote what'), 200, scrollable: find.byType(Scrollable).first);
        await tester.scrollUntilVisible(
          find.text('Omar wrote \u201cMessi\u201d'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining(' said '), findsWidgets);
        expect(find.textContaining('double bet'), findsWidgets);
        await tapVisible(tester, find.byTooltip('Share this night'));
        expect(find.text('Share'), findsWidgets);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('New round, same room'));
        expect(find.text("Bowl's empty"), findsOneWidget);
      });
    }
  }
}
