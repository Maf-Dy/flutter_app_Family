import 'package:family_game/features/round/presentation/screens/round_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  late FakeNetwork network;

  setUp(() => network = FakeNetwork(address: '192.168.1.23'));
  tearDown(() => network.dispose());

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(360, 800),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(network: network, createHost: FakeRoomHost.new, locale: locale));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openPassPhone(WidgetTester tester) async {
    await tapVisible(tester, find.text('Pass the phone'));
    await tapVisible(tester, find.text('Start'));
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> takeTurn(WidgetTester tester, String name, String secret, {int names = 1}) async {
    await tester.enterText(field('Your name'), name);
    for (var i = 1; i <= names; i++) {
      await tester.enterText(field('Name $i'), names == 1 ? secret : '$secret $i');
    }
    await tapVisible(tester, find.text('Into the bowl'));
  }

  Future<void> hold(WidgetTester tester, Finder finder, Duration duration) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(finder));
    // Frame by frame, as a real screen draws while the bar fills.
    for (var held = Duration.zero; held < duration; held += const Duration(milliseconds: 50)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('three people take turns, then a held start and a yes open the Classic round', (tester) async {
    await pumpApp(tester);
    await openPassPhone(tester);

    // The phone's owner goes first, with their saved name filled in.
    expect(find.text('Your turn'), findsOneWidget);
    expect(tester.widget<TextField>(field('Your name')).controller!.text, 'Mafdy');
    await tester.enterText(field('Name 1'), 'Mohamed Salah');
    await tapVisible(tester, find.text('Into the bowl'));

    expect(find.text("Mafdy's names are in the bowl!"), findsOneWidget);
    expect(find.text('Mohamed Salah'), findsNothing);
    expect(find.text('1 in. At least 3 needed to play.'), findsOneWidget);
    expect(find.text('Hold to start the game'), findsNothing);

    await tapVisible(tester, find.text("I'm next"));
    expect(tester.widget<TextField>(field('Your name')).controller!.text, isEmpty);
    await takeTurn(tester, 'Sara', 'Abou Trika');
    await tapVisible(tester, find.text("I'm next"));
    await takeTurn(tester, 'Omar', 'Messi');

    // A quick tap does nothing.
    await tapVisible(tester, find.text('Hold to start the game'));
    expect(find.text('Is everyone in?'), findsNothing);
    await hold(tester, find.text('Hold to start the game'), const Duration(milliseconds: 800));
    expect(find.text('Is everyone in?'), findsNothing);

    await hold(tester, find.text('Hold to start the game'), const Duration(milliseconds: 2100));
    expect(find.text('Is everyone in?'), findsOneWidget);
    expect(find.text('3 players. Once you start, nobody can add names.'), findsOneWidget);
    await tapVisible(tester, find.text('No, keep passing'));
    expect(find.text('Is everyone in?'), findsNothing);
    expect(find.text("Omar's names are in the bowl!"), findsOneWidget);

    await hold(tester, find.text('Hold to start the game'), const Duration(milliseconds: 2100));
    await tapVisible(tester, find.text('Yes, start the game'));
    expect(find.text('Give the phone to whoever reads the names out'), findsOneWidget);

    await tapVisible(tester, find.text('Start reading'));
    expect(find.byType(RoundScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a secret name hides itself once you move to the next box', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Pass the phone'));
    await tapVisible(tester, find.byTooltip('More names'));
    await tapVisible(tester, find.text('Start'));

    EditableText editable(String label) =>
        tester.widget<EditableText>(find.descendant(of: field(label), matching: find.byType(EditableText)));

    await tester.tap(field('Name 1'));
    await tester.enterText(field('Name 1'), 'Mohamed Salah');
    await tester.pump();
    expect(editable('Name 1').obscureText, isFalse);

    await tester.tap(field('Name 2'));
    await tester.pump();
    expect(editable('Name 1').obscureText, isTrue);
    expect(editable('Name 2').obscureText, isFalse);
  });

  testWidgets('leaving the app mid-turn wipes the secret names', (tester) async {
    await pumpApp(tester);
    await openPassPhone(tester);
    await tester.enterText(field('Name 1'), 'Mohamed Salah');
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(tester.widget<TextField>(field('Name 1')).controller!.text, isEmpty);
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  });

  testWidgets('a repeated player name is refused, and back from a turn returns to the hand-off', (tester) async {
    await pumpApp(tester);
    await openPassPhone(tester);
    await takeTurn(tester, 'Sara', 'Salah');
    await tapVisible(tester, find.text("I'm next"));
    await takeTurn(tester, 'sara', 'Messi');
    expect(find.text('sara is already in. Add a letter, like "sara M".'), findsOneWidget);
    expect(find.text('Your turn'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("Sara's names are in the bowl!"), findsOneWidget);

    // Back on the hand-off asks before throwing the names away.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Stop passing?'), findsOneWidget);
    await tapVisible(tester, find.text('Keep going'));
    expect(find.text("Sara's names are in the bowl!"), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Stop'));
    expect(find.text('Pass the phone'), findsWidgets);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Face-off needs four and goes straight to the teams', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Pass the phone'));
    await tapVisible(tester, find.text('Face-off'));
    expect(find.text('Players choose'), findsNothing);
    await tapVisible(tester, find.text('Start'));
    for (final (i, name) in ['Sara', 'Omar', 'Nour', 'Karim'].indexed) {
      if (i > 0) await tapVisible(tester, find.text("I'm next"));
      await takeTurn(tester, name, 'Secret $name', names: 3);
    }
    await hold(tester, find.text('Hold to start the game'), const Duration(milliseconds: 2100));
    await tapVisible(tester, find.text('Yes, start the game'));
    expect(find.text('Give the phone to whoever reads the names out'), findsNothing);
    expect(find.text('Sara'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final (label, size) in [('portrait', const Size(360, 800)), ('landscape', const Size(800, 360))]) {
    testWidgets('every step draws in Egyptian Arabic, $label', (tester) async {
      await pumpApp(tester, locale: const Locale('ar'), size: size);
      await tapVisible(tester, find.text('عدّي الموبايل'));
      await tapVisible(tester, find.text('يلا نبدأ'));
      for (final (i, name) in ['سارة', 'عمر', 'نور'].indexed) {
        if (i > 0) await tapVisible(tester, find.text('الدور عليا'));
        await tester.enterText(find.byType(TextField).first, name);
        await tester.enterText(find.byType(TextField).last, 'سر $name');
        await tapVisible(tester, find.text('ارميهم في الطبق'));
      }
      await hold(tester, find.text('اضغط كتير عشان نبدأ'), const Duration(milliseconds: 2100));
      await tapVisible(tester, find.text('أيوه، يلا نلعب'));
      expect(find.text('ادّي الموبايل للي هيقرا الأسامي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
