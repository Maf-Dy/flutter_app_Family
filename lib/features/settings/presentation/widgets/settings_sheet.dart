import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/app_settings.dart';
import '../state/settings_cubit.dart';

Future<void> showSettings(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => BlocProvider.value(value: context.read<SettingsCubit>(), child: const _SettingsSheet()),
);

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final _name = TextEditingController(text: context.read<SettingsCubit>().state.hostName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() {
    context.read<SettingsCubit>().setHostName(_name.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = context.select((SettingsCubit cubit) => cubit.state.language);
    final soundEffects = context.select((SettingsCubit cubit) => cubit.state.soundEffects);
    return PopScope<Object?>(
      onPopInvokedWithResult: (_, _) => context.read<SettingsCubit>().setHostName(_name.text),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.settings, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  maxLength: AppSettings.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _close(),
                  decoration: InputDecoration(labelText: l10n.yourName, hintText: l10n.yourNameHint, counterText: ''),
                ),
                const SizedBox(height: 20),
                Text(l10n.language, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                RadioGroup<AppLanguage>(
                  groupValue: language,
                  onChanged: (value) {
                    if (value != null) context.read<SettingsCubit>().setLanguage(value);
                  },
                  child: Column(
                    children: [
                      for (final (value, label) in [
                        (AppLanguage.system, l10n.languageSystem),
                        (AppLanguage.english, l10n.languageEnglish),
                        (AppLanguage.arabic, l10n.languageArabic),
                      ])
                        RadioListTile<AppLanguage>(value: value, title: Text(label), contentPadding: EdgeInsets.zero),
                    ],
                  ),
                ),
                SwitchListTile(
                  value: soundEffects,
                  onChanged: context.read<SettingsCubit>().setSoundEffects,
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: Text(l10n.soundEffects),
                  subtitle: Text(l10n.soundEffectsDetail),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _close, child: Text(l10n.done)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
