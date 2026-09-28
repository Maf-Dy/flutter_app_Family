import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/celebrity_game.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/how_to_play_card.dart';
import '../widgets/scoreboard.dart';

String roundTitle(AppLocalizations l10n, CelebrityRound round) => switch (round) {
  CelebrityRound.describe => l10n.roundDescribe,
  CelebrityRound.oneWord => l10n.roundOneWord,
  CelebrityRound.actOut => l10n.roundActOut,
};

class RoundIntroScreen extends StatelessWidget {
  const RoundIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<CelebrityCubit>().state.game;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (icon, detail) = switch (game.round) {
      CelebrityRound.describe => (Icons.record_voice_over_rounded, l10n.roundDescribeDetail),
      CelebrityRound.oneWord => (Icons.looks_one_rounded, l10n.roundOneWordDetail),
      CelebrityRound.actOut => (Icons.theater_comedy_rounded, l10n.roundActOutDetail),
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roundOf(game.round.index + 1))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Icon(icon, size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(roundTitle(l10n, game.round), textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(detail, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  if (game.round == CelebrityRound.describe) ...[const SizedBox(height: 20), const HowToPlayCard()],
                  if (game.round != CelebrityRound.describe) ...[const SizedBox(height: 20), Scoreboard(game: game)],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: context.read<CelebrityCubit>().toHandOff, child: Text(l10n.startRound)),
        ),
      ),
    );
  }
}
