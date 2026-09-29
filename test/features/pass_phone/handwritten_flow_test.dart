import 'package:family_game/core/widgets/ink_pad.dart';
import 'package:family_game/features/round/presentation/screens/round_screen.dart';
import 'package:family_game/features/round/presentation/widgets/paper_slip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  late FakeNetwork network;

  setUp(() => network = FakeNetwork(address: '192.168.1.23'));
  tearDown(() => network.dispose());

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Turning strokes into a PNG is real engine work, so it runs outside the fake clock.
  Future<void> dropInBowl(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Into the bowl'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Into the bowl'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  Future<void> write(WidgetTester tester, {int pad = 0}) async {
    final finder = find.byType(InkPad).at(pad);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.drag(finder, const Offset(80, 12));
    await tester.pumpAndSettle();
  }

  testWidgets('with "Write by hand" on, everyone writes with a finger and the reader sees the scribbles', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(network: network, createHost: FakeRoomHost.new));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Pass the phone'));
    await tapVisible(tester, find.byTooltip('More names'));
    expect(find.text('Off. Names are typed.'), findsOneWidget);
    await tapVisible(tester, find.text('Write by hand'));
    expect(find.textContaining('disguise yours'), findsOneWidget);
    await tapVisible(tester, find.text('Start'));

    // Two pads, no text boxes for the names.
    expect(find.byType(InkPad), findsNWidgets(2));
    expect(find.widgetWithText(TextField, 'Name 1'), findsNothing);

    // Nothing drawn yet: that is a missing name.
    await dropInBowl(tester);
    expect(find.text('Write every name on its slip first.'), findsOneWidget);

    // The first drawing covers itself once the second pad is opened.
    await write(tester);
    expect(find.text('Hidden. Tap to see it again'), findsNothing);
    await tapVisible(tester, find.byType(InkPad).at(1));
    expect(find.text('Hidden. Tap to see it again'), findsOneWidget);
    await write(tester, pad: 1);

    // Leaving the app mid-turn wipes the drawings.
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    await dropInBowl(tester);
    expect(find.text('Write every name on its slip first.'), findsOneWidget);

    Future<void> takeTurn(String? name) async {
      if (name != null) await tester.enterText(find.widgetWithText(TextField, 'Your name'), name);
      // Opens the first pad again if it is covered.
      await tapVisible(tester, find.byType(InkPad).first);
      await write(tester);
      await tapVisible(tester, find.byType(InkPad).at(1));
      await write(tester, pad: 1);
      await dropInBowl(tester);
    }

    await takeTurn(null);
    expect(find.text("Mafdy's names are in the bowl!"), findsOneWidget);
    for (final name in ['Sara', 'Omar']) {
      await tapVisible(tester, find.text("I'm next"));
      await takeTurn(name);
    }
    expect(find.text("Omar's names are in the bowl!"), findsOneWidget);

    final start = find.text('Hold to start the game');
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(start));
    for (var held = 0; held < 2100; held += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Yes, start the game'));
    await tapVisible(tester, find.text('Start reading'));
    expect(find.byType(RoundScreen), findsOneWidget);

    // Every slip read out is the drawing itself.
    final slips = tester.widgetList<PaperSlip>(find.byType(PaperSlip));
    expect(slips, isNotEmpty);
    expect(slips.every((s) => s.ink != null), isTrue);
    expect(find.descendant(of: find.byType(PaperSlip), matching: find.byType(Image)), findsWidgets);
    expect(find.text(SlipInk.marker), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
