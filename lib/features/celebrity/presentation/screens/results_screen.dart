import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../core/router/game_exit.dart';
import '../../../../core/widgets/share_card.dart';
import '../../../room/domain/room.dart';
import '../../../room/presentation/category_label.dart';
import '../../../round/presentation/widgets/confetti.dart';
import '../../domain/face_off_game.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/scoreboard.dart';
import '../../../room/presentation/team_style.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.category});

  final GameCategory category;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // Fires on the frame after the screen appears, so the burst plays once.
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _celebrate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<CelebrityCubit>().state.game;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final leaders = game.leaders;
    final headline = leaders.length == 1 ? l10n.winnerIs(teamName(l10n, leaders.single)) : l10n.itsADraw;

    void share() => showShareCard(
      context,
      ShareCard(
        title: headline,
        subtitle: categoryLabel(l10n, widget.category),
        rows: [
          for (final (i, total) in game.scores.indexed)
            (label: teamName(l10n, i), value: '$total', color: teamColor(context, i)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.seeResults),
        actions: [
          IconButton(tooltip: l10n.shareThisNight, onPressed: share, icon: const Icon(Icons.ios_share_rounded)),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Icon(Icons.emoji_events_rounded, size: 72, color: theme.colorScheme.tertiary),
                const SizedBox(height: 8),
                Text(headline, textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                const SizedBox(height: 20),
                Scoreboard(game: game),
                const SizedBox(height: 24),
                Text(l10n.faceOffWhoWroteWhat, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                _WhoWroteWhat(game: game),
              ],
            ),
          ),
          Positioned.fill(child: ConfettiBurst(fire: _celebrate)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(GameExit.newRound),
                child: Text(l10n.newRoundSameRoom),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(GameExit.endGame), child: Text(l10n.endGame)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every name with its writer, and how the team that guessed it did.
class _WhoWroteWhat extends StatelessWidget {
  const _WhoWroteWhat({required this.game});

  final FaceOffGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<CelebrityCubit>();
    // In the order they were played; a name nobody could guess comes last.
    final rows = <({Slip slip, FaceOffGuess? guess})>[
      for (final g in game.guesses) (slip: g.slip, guess: g),
      for (final slip in game.slips)
        if (game.guessFor(slip) == null) (slip: slip, guess: null),
    ];
    return Card(
      child: Column(
        children: [
          for (final (slip: slip, guess: guess) in rows)
            ListTile(
              leading: guess == null
                  ? const Icon(Icons.remove_rounded)
                  : Icon(
                      guess.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: guess.correct ? context.gameColors.live : theme.colorScheme.error,
                      semanticLabel: guess.correct ? l10n.faceOffRight : l10n.faceOffWrong,
                    ),
              title: Text(l10n.faceOffWroteIt(slip.writerName, slip.text)),
              subtitle: guess == null
                  ? null
                  : Text(
                      [
                        l10n.faceOffTeamSaid(teamName(l10n, guess.team), cubit.nameOf(guess.guessedId)),
                        if (guess.doubled) l10n.faceOffDoubleShort,
                      ].join(' · '),
                    ),
            ),
        ],
      ),
    );
  }
}
