// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_app5/NamesPage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app5/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('List count: 0'), findsOneWidget);
    expect(find.text('List count: 1'), findsNothing);
    expect(find.byKey(Key('TextField1')), findsOneWidget);

    // Tap the '+' icon and trigger a frame.

    await tester.tap(find.byKey(Key('TextField1')));
    await tester.pump(Duration(milliseconds: 1500));
    await tester.enterText(find.byKey(Key('TextField1')), "text");

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(Duration(milliseconds: 1500));

    // await tester.pumpWidget(find.byKey(Key('Scaffold2')));
  });
}
