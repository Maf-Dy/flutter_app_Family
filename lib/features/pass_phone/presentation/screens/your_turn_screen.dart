import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/platform/secure_screen.dart';
import '../../../../core/widgets/ink_pad.dart';
import '../../../room/domain/room.dart';
import '../../../room/presentation/category_label.dart';
import '../../../room/presentation/widgets/section_label.dart';
import '../../../room/presentation/widgets/select_chip.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/state/settings_cubit.dart';
import '../../domain/pass_bowl.dart';
import '../state/pass_phone_cubit.dart';
import '../widgets/secret_slip_field.dart';

/// One person's turn: their name and their secret names, typed (or, in a
/// handwritten game, written with a finger) in private.
///
/// Kept out of screenshots, and the secret names are wiped if the phone leaves the app mid-turn.
/// Like typed slips, a drawing hides as soon as you move on to the next one.
class YourTurnScreen extends StatefulWidget {
  const YourTurnScreen({super.key});

  @override
  State<YourTurnScreen> createState() => _YourTurnScreenState();
}

class _YourTurnScreenState extends State<YourTurnScreen> {
  late final PassBowl _bowl = context.read<PassPhoneCubit>().state.bowl!;

  /// The very first player is usually the phone's owner.
  late final _name = TextEditingController(
    text: _bowl.players.isEmpty ? context.read<SettingsCubit>().state.hostName : '',
  );
  late final _secrets = [for (var i = 0; i < _bowl.room.namesPerPlayer; i++) TextEditingController()];
  late final _inks = [
    if (_bowl.room.handwritten)
      for (var i = 0; i < _bowl.room.namesPerPlayer; i++) InkController(),
  ];

  /// The one drawing on show; the others are covered.
  int? _open = 0;
  bool _submitting = false;
  late final AppLifecycleListener _lifecycle;
  PassError? _error;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _wipeSecrets);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _name.dispose();
    for (final c in _secrets) {
      c.dispose();
    }
    for (final c in _inks) {
      c.dispose();
    }
    super.dispose();
  }

  void _wipeSecrets() {
    for (final c in _secrets) {
      c.clear();
    }
    for (final c in _inks) {
      c.clear();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _showInk(int? index) {
    if (_open != index) setState(() => _open = index);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final cubit = context.read<PassPhoneCubit>();
    PassError? error;
    if (_inks.isEmpty) {
      error = cubit.submit(name: _name.text, secrets: [for (final c in _secrets) c.text]);
    } else {
      _submitting = true;
      final inks = await Future.wait([for (final c in _inks) c.toInk()]);
      _submitting = false;
      if (!mounted) return;
      error = cubit.submit(name: _name.text, inks: inks);
    }
    if (error == null) {
      unawaited(Haptics.nameIn());
      return;
    }
    setState(() => _error = error);
  }

  String _errorText(AppLocalizations l10n, PassError error) => switch (error) {
    PassError.missingName => l10n.passErrorMissingName,
    PassError.nameTaken => l10n.passErrorNameTaken(Room.tidy(_name.text)),
    PassError.missingSecret => _inks.isEmpty ? l10n.passErrorMissingSecret : l10n.inkMissing,
    PassError.tooLong => l10n.passErrorTooLong,
    PassError.duplicate => l10n.duplicateHostSecret,
    PassError.full => l10n.passErrorFull,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final error = _error;
    final waiting = _bowl.waiting;
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.passYourTurn)),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                '${categoryLabel(l10n, _bowl.room.category)} · ${l10n.namesPerPlayerValue(_bowl.room.namesPerPlayer)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.passPrivate,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              if (waiting.isNotEmpty) ...[
                SectionLabel(l10n.passTapYourName),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in waiting)
                      SelectChip(
                        label: p.name,
                        selected: Room.matchKey(_name.text) == Room.matchKey(p.name),
                        onTap: () => setState(() => _name.text = p.name),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _name,
                maxLength: AppSettings.maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onTap: () => _showInk(null),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.yourName,
                  counterText: '',
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SectionLabel(l10n.passSecretNames),
              const SizedBox(height: 10),
              for (final (i, ink) in _inks.indexed) ...[
                InkPad(
                  controller: ink,
                  label: l10n.passSecretN(i + 1),
                  hidden: _open != i,
                  onReveal: () => _showInk(i),
                ),
                const SizedBox(height: 12),
              ],
              if (_inks.isEmpty)
                for (final (i, controller) in _secrets.indexed) ...[
                  SecretSlipField(
                    controller: controller,
                    label: l10n.passSecretN(i + 1),
                    textInputAction: i == _secrets.length - 1 ? TextInputAction.done : TextInputAction.next,
                    onSubmitted: i == _secrets.length - 1 ? (_) => _submit() : null,
                  ),
                  const SizedBox(height: 12),
                ],
              if (error != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorText(l10n, error),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.move_to_inbox_rounded),
              label: Text(l10n.passIntoBowl),
            ),
          ),
        ),
      ),
    );
  }
}
