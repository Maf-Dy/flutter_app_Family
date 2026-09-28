import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';

/// Someone on a new phone asks to take back a dropped player's seat. Only the
/// host can tell whether it's really them, so the host decides.
class ClaimCard extends StatelessWidget {
  const ClaimCard({super.key, required this.game, required this.claim, required this.onResolve});

  final FamilyGame game;
  final SeatClaim claim;
  final void Function({required bool approve}) onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = game.nameOf(claim.playerId);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.familyClaimTitle(name), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.familyClaimBody(name), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(onPressed: () => onResolve(approve: false), child: Text(l10n.familyClaimDeny)),
                FilledButton(onPressed: () => onResolve(approve: true), child: Text(l10n.familyClaimAllow)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The family whose turn it is has dropped out entirely: wait, or skip them.
/// The game never skips anyone by itself.
class AwayTurnCard extends StatelessWidget {
  const AwayTurnCard({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.familyAwayTurnHelp,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onSkip, child: Text(l10n.familySkipTurn)),
        ],
      ),
    );
  }
}
