import 'package:family_game/core/l10n/l10n.dart';
import 'package:family_game/core/theme/app_theme.dart';
import 'package:family_game/core/widgets/ink_pad.dart';
import 'package:family_game/features/room/presentation/widgets/host_secret_field.dart';
import 'package:family_game/features/round/presentation/widgets/paper_slip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/ink.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListView(padding: const EdgeInsets.all(16), children: [child]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Where the pad takes ink (not its buttons).
  Finder padArea() => find.descendant(of: find.byType(InkPad), matching: find.byType(CustomPaint)).first;

  TextButton button(WidgetTester tester, String label) => tester.widget<TextButton>(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is TextButton)),
  );

  testWidgets('writing on the pad makes a small PNG, and Clear wipes it', (tester) async {
    final ink = InkController();
    addTearDown(ink.dispose);
    await pump(tester, InkPad(controller: ink, label: 'Name 1'));
    expect(find.text('Write the name here with your finger'), findsOneWidget);
    expect(button(tester, 'Clear').onPressed, isNull, reason: 'nothing to clear yet');
    expect(button(tester, 'Undo').onPressed, isNull);

    // A vertical stroke inside a scrolling list still writes instead of scrolling.
    await tester.drag(padArea(), const Offset(0, 40));
    await tester.drag(padArea(), const Offset(90, 10));
    await tester.pumpAndSettle();
    expect(ink.strokes, hasLength(2));
    expect(find.text('Write the name here with your finger'), findsNothing);
    expect(button(tester, 'Clear').onPressed, isNotNull);

    final drawing = (await tester.runAsync(ink.toInk))!;
    expect(drawing.png.sublist(1, 4), 'PNG'.codeUnits);
    expect(drawing.width, lessThanOrEqualTo(SlipInk.maxWidth));
    expect(drawing.height, lessThanOrEqualTo(SlipInk.maxHeight));
    expect(drawing.width, lessThan(SlipInk.maxWidth), reason: 'cropped to the ink');
    expect(drawing.png.length, lessThan(SlipInk.maxBytes));

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(ink.isEmpty, isTrue);
    expect(await tester.runAsync(ink.toInk), isNull);
    expect(button(tester, 'Clear').onPressed, isNull);
  });

  testWidgets('Undo takes back the last stroke only', (tester) async {
    final ink = InkController();
    addTearDown(ink.dispose);
    await pump(tester, InkPad(controller: ink), locale: const Locale('ar'));
    await tester.drag(padArea(), const Offset(80, 0));
    await tester.drag(padArea(), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(ink.strokes, hasLength(2));
    final first = ink.strokes.first;

    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(ink.strokes, [first]);
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(ink.isEmpty, isTrue);
    expect(button(tester, 'تراجع').onPressed, isNull);
    expect(button(tester, 'امسح').onPressed, isNull);
  });

  testWidgets('a tap without moving draws nothing on an empty pad, a dot next to ink', (tester) async {
    final ink = InkController();
    addTearDown(ink.dispose);
    await pump(tester, InkPad(controller: ink));
    final pad = padArea();
    await tester.tap(pad);
    await tester.pumpAndSettle();
    expect(ink.isEmpty, isTrue);

    // A shaky finger that barely moves is still a tap.
    await tester.dragFrom(tester.getCenter(pad), const Offset(3, 2));
    await tester.pumpAndSettle();
    expect(ink.isEmpty, isTrue);

    await tester.drag(pad, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(ink.strokes, hasLength(1));
    await tester.tapAt(tester.getCenter(pad) + const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(ink.strokes, hasLength(2), reason: 'the dot of a letter');
    expect(ink.strokes.last, hasLength(1));
  });

  testWidgets('on a phone the pad is full width and tall, and big drawings shrink to fit a slip', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ink = InkController();
    addTearDown(ink.dispose);
    await pump(tester, InkPad(controller: ink));
    final size = tester.getSize(padArea());
    expect(size.width, greaterThanOrEqualTo(320));
    expect(size.height, greaterThanOrEqualTo(InkPad.minHeight - 4));

    // Top to bottom, corner to corner.
    final rect = tester.getRect(padArea());
    await tester.dragFrom(rect.topLeft + const Offset(4, 4), rect.size.bottomRight(Offset.zero) - const Offset(8, 8));
    await tester.pumpAndSettle();
    final drawing = (await tester.runAsync(ink.toInk))!;
    expect(drawing.width, lessThanOrEqualTo(SlipInk.maxWidth));
    expect(drawing.height, lessThanOrEqualTo(SlipInk.maxHeight));
    expect(drawing.height, greaterThan(SlipInk.maxHeight * 0.9), reason: 'shrunk, not cut off');
  });

  testWidgets('a hidden pad covers the ink; only its button opens it, and that tap draws nothing', (tester) async {
    final ink = InkController()..begin(const Offset(20, 20));
    addTearDown(ink.dispose);
    var revealed = false;
    await pump(
      tester,
      InkPad(controller: ink, hidden: true, onReveal: () => revealed = true),
      locale: const Locale('ar'),
    );
    expect(find.text('متخبي عشان محدش يبص'), findsOneWidget);
    await tester.drag(find.byType(InkPad), const Offset(60, 0));
    expect(ink.strokes, hasLength(1), reason: 'nothing is drawn on a covered pad');
    await tester.tapAt(tester.getTopLeft(find.byType(InkPad)) + const Offset(40, 60));
    expect(revealed, isFalse, reason: 'a tap on the cover is not the button');
    expect(button(tester, 'تراجع').onPressed, isNull, reason: 'no undoing what you cannot see');
    await tester.tap(find.text('ورّي'));
    expect(revealed, isTrue);
    expect(ink.strokes, hasLength(1));
  });

  testWidgets('opening an empty covered pad with "Tap to write" leaves no mark', (tester) async {
    final ink = InkController();
    addTearDown(ink.dispose);
    var hidden = true;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) =>
            InkPad(controller: ink, hidden: hidden, onReveal: () => setState(() => hidden = false)),
      ),
    );
    await tester.tap(find.text('Tap to write'));
    await tester.pumpAndSettle();
    expect(hidden, isFalse);
    expect(find.text('Tap to write'), findsNothing);
    expect(ink.isEmpty, isTrue);

    // Then writing works.
    await tester.drag(padArea(), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(ink.strokes, hasLength(1));
  });

  testWidgets("the host's pad in the lobby is full width, and drops the drawing in the bowl", (tester) async {
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SlipInk? dropped;
    await pump(
      tester,
      HostInkField(
        label: 'Your secret name',
        onSubmit: (ink) {
          dropped = ink;
          return true;
        },
      ),
    );
    expect(tester.getSize(padArea()).width, greaterThanOrEqualTo(320));
    await tester.drag(padArea(), const Offset(100, 20));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Drop in the bowl'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(dropped, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a handwritten slip shows the drawing, a typed one its text', (tester) async {
    final semantics = tester.ensureSemantics();
    final ink = SlipInk.tryParse(tinyPng)!;
    await pump(
      tester,
      Column(
        children: [
          PaperSlip(text: SlipInk.marker, ink: ink, large: true),
          const PaperSlip(text: 'Mohamed Salah'),
        ],
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as MemoryImage).bytes, ink.png);
    expect(find.text(SlipInk.marker), findsNothing);
    expect(find.text('Mohamed Salah'), findsOneWidget);
    expect(tester.getSemantics(find.byType(Image)).label, 'A handwritten name');
    semantics.dispose();
  });
}
