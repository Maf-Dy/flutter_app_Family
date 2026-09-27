import 'package:flutter/foundation.dart';

enum AppLanguage { system, english, arabic }

/// Choices the host keeps between games.
@immutable
final class AppSettings {
  const AppSettings({this.hostName = '', this.language = AppLanguage.system});

  static const maxNameLength = 30;

  /// Empty until the host picks one; the UI then shows a translated "You".
  final String hostName;
  final AppLanguage language;

  AppSettings copyWith({String? hostName, AppLanguage? language}) =>
      AppSettings(hostName: hostName ?? this.hostName, language: language ?? this.language);
}

abstract interface class SettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
