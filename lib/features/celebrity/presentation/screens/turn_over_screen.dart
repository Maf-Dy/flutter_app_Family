import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/scoreboard.dart';
import '../../../room/presentation/team_style.dart';

class TurnOverScreen extends StatelessWidget {
  const TurnOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final state = context.watch<CelebrityCubit>().state;
    final game = state.game;
    final carries = game.bowlEmpty && !game.isLastRound && state.secondsLeft > 0;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final next = !game.bowlEmpty
        ? l10n.nextTeam
        : game.isLastRound
        ? l10n.seeResults
        : l10n.nextRound;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(game.bowlEmpty ? l10n.bowlEmptied : l10n.timesUp)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Text(
                l10n.turnScore(game.turnPoints, teamName(l10n, game.team)),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(color: teamColor(context, game.team)),
              ),
            ),
            if (carries) ...[
              const SizedBox(height: 12),
              Text(
                l10n.carryOnTurn(teamName(l10n, game.team), state.secondsLeft),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 20),
            Scoreboard(game: game),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: cubit.nextTurn, child: Text(next)),
        ),
      ),
    );
  }
}
