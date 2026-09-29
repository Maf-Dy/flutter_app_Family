import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';
import '../../domain/night_awards.dart';

String awardTitle(AppLocalizations l10n, AwardKind kind) => switch (kind) {
  AwardKind.worstLiar => l10n.awardWorstLiar,
  AwardKind.pokerFace => l10n.awardPokerFace,
  AwardKind.wronged => l10n.awardWronged,
  AwardKind.detective => l10n.awardDetective,
};

String awardDetail(AppLocalizations l10n, NightAward award) => switch (award.kind) {
  AwardKind.worstLiar => l10n.awardWorstLiarDetail,
  AwardKind.pokerFace => l10n.awardPokerFaceDetail,
  AwardKind.wronged => l10n.awardWrongedDetail(award.count),
  AwardKind.detective => l10n.awardDetectiveDetail(award.count),
};

/// The end of the night: the awards, then who caught whom.
class NightAwardsCard extends StatelessWidget {
  const NightAwardsCard({super.key, required this.game, required this.colorOf});

  final FamilyGame game;
  final Color Function(String playerId) colorOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final awards = nightAwards(game);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.awardsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final award in awards)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(awardTitle(l10n, award.kind), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(awardDetail(l10n, award)),
                trailing: Text(
                  game.nameOf(award.playerId),
                  style: theme.textTheme.titleSmall?.copyWith(color: colorOf(award.playerId)),
                ),
              ),
            const Divider(),
            Text(l10n.familyTreeTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FamilyTreeView(game: game, colorOf: colorOf),
          ],
        ),
      ),
    );
  }
}

/// Who caught whom: each player sits under the one who brought them into the family, the winner on top.
class FamilyTreeView extends StatelessWidget {
  const FamilyTreeView({super.key, required this.game, required this.colorOf, this.ink});

  final FamilyGame game;
  final Color Function(String playerId) colorOf;

  /// Text colour, for drawing on the share card's paper.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final muted = ink ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in familyTreeLines(game))
          Padding(
            padding: EdgeInsetsDirectional.only(start: 18.0 * line.depth, bottom: 4),
            child: Row(
              children: [
                if (line.depth == 0) const Text('👑 ') else Text('└ ', style: TextStyle(color: muted)),
                CircleAvatar(radius: 5, backgroundColor: colorOf(line.playerId)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    game.nameOf(line.playerId),
                    style: TextStyle(fontWeight: FontWeight.w800, color: ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
