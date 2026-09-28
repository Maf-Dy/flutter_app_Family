import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../round/presentation/widgets/flip.dart';
import '../../../round/presentation/widgets/paper_slip.dart';
import '../state/celebrity_cubit.dart';
import '../../../room/presentation/team_style.dart';
import '../widgets/timer_ring.dart';
import 'round_intro_screen.dart';

/// The clue-giver's screen: the clock, the name, and two big buttons.
class TurnScreen extends StatelessWidget {
  const TurnScreen({super.key, required this.turnSeconds});

  final int turnSeconds;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final state = context.watch<CelebrityCubit>().state;
    final game = state.game;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final current = game.current;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(roundTitle(l10n, game.round)),
        actions: [
          IconButton(
            tooltip: state.paused ? l10n.resumeTurn : l10n.pauseTurn,
            onPressed: state.paused ? cubit.resume : cubit.pause,
            icon: Icon(state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Chip(
              avatar: CircleAvatar(backgroundColor: teamColor(context, game.team)),
              // Keep the plus sign in front in right-to-left languages too.
              label: Text('+${game.turnPoints}', textDirection: TextDirection.ltr),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            TimerRing(secondsLeft: state.secondsLeft, total: turnSeconds),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: state.paused
                        ? _Paused(onResume: cubit.resume)
                        : current == null
                        ? const SizedBox.shrink()
                        : FlipIn(
                            key: ValueKey((game.bowl.length, current.text, current.writerId)),
                            child: Semantics(
                              liveRegion: true,
                              child: PaperSlip(text: current.text, tiltDegrees: -2, large: true),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Text(
              l10n.namesLeft(game.bowl.length),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonal(
                      onPressed: game.bowl.length > 1 && !state.paused ? cubit.skip : null,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 64)),
                      child: Text(l10n.skip),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: state.paused
                          ? null
                          : () {
                              Haptics.point();
                              cubit.gotIt();
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 64),
                        backgroundColor: context.gameColors.live,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.gotItGuess),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands in for the name while the clock is stopped, so nobody peeks at it.
class _Paused extends StatelessWidget {
  const _Paused({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.pause_circle_rounded, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(l10n.turnPaused, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(l10n.turnPausedBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.resumeTurn),
        ),
      ],
    );
  }
}
