import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';

/// Whose turn it is, or who won. Loud when it's the host's family's turn.
class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key, required this.game, required this.me});

  final FamilyGame game;

  /// The host's id in the game, or null when watching.
  final String? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final myHead = me == null ? null : game.headOf(me!);
    final winner = game.winner;
    final myTurn = winner == null && myHead != null && (game.secret ? game.turnPlayer == me : game.turn == myHead);

    final (Color bg, Color fg, IconData icon, String text) = switch (winner) {
      final w? => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.emoji_events_rounded,
        w == myHead ? l10n.familyYouWon : l10n.familyWon(game.nameOf(w)),
      ),
      null when myTurn && game.secret => (
        scheme.primary,
        scheme.onPrimary,
        Icons.campaign_rounded,
        l10n.familyTurnYouAsk,
      ),
      null when myTurn => (
        scheme.primary,
        scheme.onPrimary,
        Icons.campaign_rounded,
        me != myHead && game.canAsk(me!)
            ? l10n.familyActingHead(game.nameOf(myHead))
            : '${l10n.familyTurnYours} ${me == myHead ? l10n.familyYouAsk : l10n.familyHeadAsks(game.nameOf(myHead))}',
      ),
      null when game.turnStalled && game.pending == null => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        Icons.wifi_off_rounded,
        l10n.familyAwayTurn(game.nameOf(game.asker)),
      ),
      null => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        Icons.hourglass_top_rounded,
        game.secret ? l10n.familyTurnPlayer(game.nameOf(game.asker)) : l10n.familyTurnOther(game.nameOf(game.turn)),
      ),
    };

    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: fg, size: winner == null ? 26 : 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: (winner == null ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
