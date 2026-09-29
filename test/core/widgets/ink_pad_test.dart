import 'package:family_game/core/l10n/l10n.dart';
import 'package:family_game/core/theme/app_theme.dart';
import 'package:family_game/core/widgets/ink_pad.dart';
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

  testWidgets('writing on the pad makes a small PNG, and Clear wipes it', (tester) async {
    final ink = InkController();
    addTearDown(ink.dispose);
    await pump(tester, InkPad(controller: ink, label: 'Name 1'));
    expect(find.text('Write the name here with your finger'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);

    // A vertical stroke inside a scrolling list still writes instead of scrolling.
    await tester.drag(find.byType(InkPad), const Offset(0, 40));
    await tester.drag(find.byType(InkPad), const Offset(90, 10));
    await tester.pumpAndSettle();
    expect(ink.strokes, hasLength(2));
    expect(find.text('Write the name here with your finger'), findsNothing);

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
  });

  testWidgets('a hidden pad covers the ink and asks to be tapped', (tester) async {
    final ink = InkController()..begin(const Offset(20, 20));
    addTearDown(ink.dispose);
    var revealed = false;
    await pump(
      tester,
      InkPad(controller: ink, hidden: true, onReveal: () => revealed = true),
      locale: const Locale('ar'),
    );
    expect(find.text('متخبي. دوس عشان تشوفه تاني'), findsOneWidget);
    await tester.drag(find.byType(InkPad), const Offset(60, 0));
    expect(ink.strokes, hasLength(1), reason: 'nothing is drawn on a covered pad');
    await tester.tap(find.byType(InkPad));
    expect(revealed, isTrue);
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
