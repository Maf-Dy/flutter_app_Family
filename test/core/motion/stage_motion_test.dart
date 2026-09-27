import 'dart:async';

import 'package:family_game/core/motion/shared_axis.dart';
import 'package:family_game/core/motion/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screens that change stage quickly: a stage coming back while its old copy
/// is still fading out used to stop the screen from drawing at all.
void main() {
  Widget stage(String name, {VoidCallback? onTap}) => Scaffold(
    key: ValueKey(name),
    body: Center(child: TextButton(onPressed: onTap, child: Text(name))),
  );

  Future<void> pumpStage(WidgetTester tester, int position, Widget child) =>
      tester.pumpWidget(MaterialApp(home: StageSwitcher(position: position, child: child)));

  testWidgets('a stage can come back while its old copy is still leaving', (tester) async {
    await pumpStage(tester, 0, stage('setup'));
    await pumpStage(tester, 1, stage('lobby'));
    await tester.pump(const Duration(milliseconds: 50));
    await pumpStage(tester, 0, stage('setup'));
    await tester.pump(const Duration(milliseconds: 50));
    await pumpStage(tester, 1, stage('lobby'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('lobby'), findsOneWidget);
    expect(find.text('setup'), findsNothing);
  });

  testWidgets('a snack bar shown while stages swap does not break leaving the screen', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final position = ValueNotifier(0);
    addTearDown(position.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('home')),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => ValueListenableBuilder(
            valueListenable: position,
            builder: (context, position, _) =>
                StageSwitcher(position: position, child: position == 0 ? stage('setup') : stage('lobby')),
          ),
        ),
      ),
    );
    unawaited(navigator.currentState!.pushNamed('/room'));
    await tester.pumpAndSettle();
    ScaffoldMessenger.of(tester.element(find.text('setup'))).showSnackBar(const SnackBar(content: Text('Link copied')));
    await tester.pump();
    position.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Link copied'), findsNWidgets(2), reason: 'both stages show the snack bar mid-swap');
    // Leaving mid-swap flies the page's heroes, the snack bars among them.
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a fade switch survives A, B, A in quick succession', (tester) async {
    Future<void> show(String text) => tester.pumpWidget(
      MaterialApp(
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: Motion.fadeSwitch,
          child: Text(text, key: ValueKey(text)),
        ),
      ),
    );
    for (final text in ['one', 'two', 'one', 'two', 'one']) {
      await show(text);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsNothing);
  });
}
