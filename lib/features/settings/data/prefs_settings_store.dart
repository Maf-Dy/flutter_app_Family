import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Keeps [AppSettings] in the platform's plain preferences; nothing here is sensitive.
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync();

  static const _hostNameKey = 'settings.hostName';
  static const _languageKey = 'settings.language';

  final SharedPreferencesAsync _prefs;

  @override
  Future<AppSettings> load() async {
    try {
      final language = await _prefs.getString(_languageKey);
      return AppSettings(
        hostName: await _prefs.getString(_hostNameKey) ?? '',
        language: AppLanguage.values.asNameMap()[language] ?? AppLanguage.system,
      );
    } catch (error) {
      // Unreadable preferences must not stop the game from starting.
      debugPrint('PrefsSettingsStore: using defaults ($error)');
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      await _prefs.setString(_hostNameKey, settings.hostName);
      await _prefs.setString(_languageKey, settings.language.name);
    } catch (error) {
      debugPrint('PrefsSettingsStore: could not save ($error)');
    }
  }
}
