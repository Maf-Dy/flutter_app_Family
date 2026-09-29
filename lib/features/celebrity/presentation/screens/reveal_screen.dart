import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../room/presentation/team_style.dart';
import '../../../round/presentation/widgets/paper_slip.dart';
import '../../domain/face_off_game.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/scoreboard.dart';

/// Who really wrote the name, and what the guess won or lost.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  @override
  void initState() {
    super.initState();
    final correct = context.read<CelebrityCubit>().state.game.lastGuess?.correct ?? false;
    correct ? Haptics.point() : Haptics.timeUp();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final game = context.watch<CelebrityCubit>().state.game;
    final guess = game.lastGuess!;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final team = teamName(l10n, game.team);
    final color = guess.correct ? context.gameColors.live : theme.colorScheme.error;
    // With the same name written twice, the guess can be right about the other writer.
    final writer = guess.correct ? cubit.nameOf(guess.guessedId) : guess.slip.writerName;
    final points = switch (guess.points) {
      0 => l10n.faceOffNoPoints(team),
      < 0 => l10n.faceOffLosesPoint(team),
      final won => l10n.turnScore(won, team),
    };
    final last = game.next().phase == FaceOffPhase.finished;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(l10n.teamTurn(team))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Column(
                children: [
                  Icon(guess.correct ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 72, color: color),
                  const SizedBox(height: 6),
                  Text(
                    guess.correct ? l10n.faceOffRight : l10n.faceOffWrong,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.faceOffWroteIt(writer, guess.slip.text),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            // A handwritten name: show the scribble itself, the whole point of the round.
            if (guess.slip.ink != null) ...[
              const SizedBox(height: 10),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: PaperSlip(text: guess.slip.text, ink: guess.slip.ink, tiltDegrees: -2),
                ),
              ),
            ],
            if (!guess.correct) ...[
              const SizedBox(height: 4),
              Text(
                l10n.faceOffYouSaid(cubit.nameOf(guess.guessedId)),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              points,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: teamColor(context, game.team)),
            ),
            if (guess.doubled) ...[
              const SizedBox(height: 4),
              Text(
                l10n.faceOffWasDouble,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
          child: FilledButton(onPressed: cubit.next, child: Text(last ? l10n.seeResults : l10n.nextTeam)),
        ),
      ),
    );
  }
}
