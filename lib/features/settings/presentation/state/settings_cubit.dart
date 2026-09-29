import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/app_settings.dart';

/// App-wide choices: the host's name, the language and sound. Lives for the whole app.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._store, AppSettings initial) : super(initial);

  final SettingsStore _store;

  /// Null follows the phone's language.
  Locale? get locale => switch (state.language) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.arabic => const Locale('ar'),
  };

  Future<void> setHostName(String name) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final limited = clean.length > AppSettings.maxNameLength ? clean.substring(0, AppSettings.maxNameLength) : clean;
    if (limited == state.hostName) return;
    emit(state.copyWith(hostName: limited));
    await _store.save(state);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == state.language) return;
    emit(state.copyWith(language: language));
    await _store.save(state);
  }

  Future<void> setSoundEffects(bool on) async {
    if (on == state.soundEffects) return;
    emit(state.copyWith(soundEffects: on));
    await _store.save(state);
  }
}
