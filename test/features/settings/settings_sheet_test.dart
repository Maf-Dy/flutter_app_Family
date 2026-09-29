import 'package:family_game/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  test('sound effects are on until turned off', () {
    expect(const AppSettings().soundEffects, isTrue);
    expect(const AppSettings().copyWith(soundEffects: false).soundEffects, isFalse);
    expect(const AppSettings(soundEffects: false).copyWith(hostName: 'Mafdy').soundEffects, isFalse);
  });

  testWidgets('the settings sheet turns sound effects off and saves it', (tester) async {
    final network = FakeNetwork();
    addTearDown(network.dispose);
    final store = FakeSettingsStore();
    await tester.pumpWidget(testApp(network: network, createHost: FakeRoomHost.new, settingsStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, 'Sound effects');
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(store.saved.soundEffects, isFalse);
    expect(store.saved.hostName, 'Mafdy', reason: 'the rest of the settings are kept');
  });

  testWidgets('shows in Arabic', (tester) async {
    final network = FakeNetwork();
    addTearDown(network.dispose);
    await tester.pumpWidget(testApp(network: network, createHost: FakeRoomHost.new, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('المؤثرات الصوتية'), findsOneWidget);
  });
}
