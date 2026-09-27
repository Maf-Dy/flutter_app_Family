import 'package:family_game/core/l10n/l10n.dart';
import 'package:family_game/core/theme/app_theme.dart';
import 'package:family_game/core/widgets/share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, ShareCard card, {Locale locale = const Locale('en')}) async {
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
        home: Scaffold(body: Center(child: card)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a long custom category fits on the card', (tester) async {
    await pumpCard(
      tester,
      const ShareCard(
        title: 'Purple team wins!',
        subtitle: 'Teachers from school who gave us homework',
        rows: [(label: 'Purple team', value: '12', color: Colors.purple)],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names and long writer names fit on the card', (tester) async {
    await pumpCard(
      tester,
      ShareCard(
        title: 'Who wrote what?',
        subtitle: 'Anything goes',
        rows: [
          (label: 'W' * 60, value: 'M' * 30, color: Colors.orange),
          (label: 'Umm Kulthum', value: 'Mohamed Abdelrahman Elsayed', color: null),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
