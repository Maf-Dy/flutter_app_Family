import 'package:flutter/foundation.dart';

enum AppLanguage { system, english, arabic }

/// Choices the host keeps between games.
@immutable
final class AppSettings {
  const AppSettings({this.hostName = '', this.language = AppLanguage.system, this.soundEffects = true});

  static const maxNameLength = 30;

  /// Empty until the host picks one; the UI then shows a translated "You".
  final String hostName;
  final AppLanguage language;

  /// Drumrolls, cheers and sad trombones on this phone.
  final bool soundEffects;

  AppSettings copyWith({String? hostName, AppLanguage? language, bool? soundEffects}) => AppSettings(
    hostName: hostName ?? this.hostName,
    language: language ?? this.language,
    soundEffects: soundEffects ?? this.soundEffects,
  );
}

abstract interface class SettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
