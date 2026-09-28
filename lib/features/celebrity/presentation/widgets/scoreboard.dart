import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/face_off_game.dart';
import '../../../room/presentation/team_style.dart';

/// Points per team. The leading team is highlighted.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.game});

  final FaceOffGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final leaders = game.leaders;
    final best = game.scores.reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            for (final (i, total) in game.scores.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(radius: 7, backgroundColor: teamColor(context, i)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        teamName(l10n, i),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: leaders.contains(i) && best > 0 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$total',
                        textAlign: TextAlign.end,
                        // Keep a minus sign in front in right-to-left languages too.
                        textDirection: TextDirection.ltr,
                        semanticsLabel: '${l10n.total} $total',
                        style: theme.textTheme.titleLarge,
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
