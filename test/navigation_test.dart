import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

/// Moving between screens fast, the way a real thumb does: double taps,
/// dialogs dismissed without an answer, back pressed mid-transition.
void main() {
  late FakeNetwork network;
  late FakeRoomHost host;

  Future<void> pumpApp(WidgetTester tester, {bool reducedMotion = true}) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(network: network, createHost: () => host = FakeRoomHost(), reducedMotion: reducedMotion),
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

  group('custom category dialog', () {
    for (final (how, close) in <(String, Future<void> Function(WidgetTester))>[
      ('Cancel', (tester) => tester.tap(find.text('Cancel'))),
      ('tapping outside', (tester) => tester.tapAt(const Offset(10, 10))),
      ('back', (tester) => tester.binding.handlePopRoute()),
      ('Use with nothing typed', (tester) => tester.tap(find.text('Use'))),
    ]) {
      testWidgets('closing it by $how with no name keeps the old category', (tester) async {
        await pumpApp(tester);
        await tapVisible(tester, find.text('Host a room'));
        await tapVisible(tester, find.text('Your own…'));
        expect(find.byType(AlertDialog), findsOneWidget);
        await close(tester);
        // Pump through the dialog's closing animation frame by frame: the text
        // field is still drawn while it fades out.
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('New room'), findsOneWidget);
      });
    }
  });

  Future<void> playClassicToReveal(WidgetTester tester) async {
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Open room'));
    host
      ..join('a', 'Omar', ['Lionel Messi'])
      ..join('b', 'Nour', ['Fairuz']);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Salah');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Start reading'));
    for (var i = 0; i < 2; i++) {
      await tapVisible(tester, find.text('Next name'));
    }
    await tapVisible(tester, find.text('Done reading'));
    await tapVisible(tester, find.text('Who wrote what?'));
    await tapVisible(tester, find.text('Reveal all'));
  }

  Future<void> doubleTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('double-tapping End game lands on Home, not an empty screen', (tester) async {
    await pumpApp(tester);
    await playClassicToReveal(tester);
    await doubleTap(tester, find.text('End game'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Host a room'), findsOneWidget);
  });

  testWidgets('double-tapping New round stays in the lobby', (tester) async {
    await pumpApp(tester);
    await playClassicToReveal(tester);
    await doubleTap(tester, find.text('New round, same room'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Omar'), findsOneWidget);
    expect(host.room.round, 2);
  });

  testWidgets('flipping between the hotspot steps quickly keeps the codes drawn', (tester) async {
    network = FakeNetwork();
    // Motion on, as on a real phone. Looping animations never settle, so step frames.
    await tester.pumpWidget(
      testApp(network: network, createHost: () => host = FakeRoomHost(), reducedMotion: false),
    );
    Future<void> frames(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await frames(10);
    await tester.tap(find.text('Host a room'));
    await frames(20);
    await tester.tap(find.text('Open room'));
    await frames(20);
    await tester.tap(find.text('Create hotspot'));
    await frames(20);
    for (final step in ['Open the game', 'Join the Wi-Fi', 'Open the game', 'Join the Wi-Fi']) {
      await tester.tap(find.text(step));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await frames(20);
    expect(tester.takeException(), isNull);
    expect(find.text('AndroidShare_1234'), findsOneWidget);
  });
}
