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
                    child: current == null
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
                      onPressed: game.bowl.length > 1 ? cubit.skip : null,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 64)),
                      child: Text(l10n.skip),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: () {
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
