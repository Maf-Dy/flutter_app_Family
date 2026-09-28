import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../core/widgets/bowl.dart';
import '../../../room/domain/room.dart';
import '../state/pass_phone_cubit.dart';
import '../widgets/hold_button.dart';

/// Someone's names just went in. Nothing secret is on screen, only who is in,
/// and the phone goes to whoever is next. Starting the game takes a long press
/// and then a yes, so it can't happen by accident.
class PassedScreen extends StatelessWidget {
  const PassedScreen({super.key, required this.onStart});

  /// Called once the table has confirmed everyone is in.
  final VoidCallback onStart;

  Future<void> _confirmStart(BuildContext context, List<Player> players) async {
    final l10n = context.l10n;
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.passEveryoneInTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.passEveryoneInBody(players.length)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final p in players) Chip(label: Text(p.name))]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.passKeepPassing)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.passYesStart)),
        ],
      ),
    );
    if ((start ?? false) && context.mounted) onStart();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PassPhoneCubit>().state;
    final bowl = state.bowl!;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final game = context.gameColors;
    final lastName = state.lastName ?? '';
    final lastIndex = bowl.players.indexWhere((p) => Room.matchKey(p.name) == Room.matchKey(lastName));
    final color = game.player(lastIndex < 0 ? 0 : lastIndex);
    final onColor = game.onPlayer;
    final playersIn = bowl.playersIn;

    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Bowl(width: 140),
                  const SizedBox(height: 16),
                  Text(
                    l10n.passNamesIn(lastName),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(color: onColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.passToNext,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(color: onColor.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: context.read<PassPhoneCubit>().next,
                    style: FilledButton.styleFrom(
                      backgroundColor: onColor,
                      foregroundColor: color,
                      minimumSize: const Size(220, 56),
                    ),
                    child: Text(l10n.passImNext),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final p in playersIn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: onColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(p.name, style: theme.textTheme.labelLarge?.copyWith(color: onColor)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bowl.canStart)
                    HoldButton(
                      label: l10n.passHoldToStart,
                      hint: l10n.passHoldHint,
                      color: onColor,
                      onHeld: () => _confirmStart(context, playersIn),
                    )
                  else
                    Text(
                      l10n.passNeedMore(playersIn.length, bowl.requiredPlayers),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: onColor.withValues(alpha: 0.85)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
