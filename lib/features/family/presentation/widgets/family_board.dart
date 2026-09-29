import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/family_game.dart';
import '../../../round/presentation/widgets/paper_slip.dart';
import '../family_style.dart';

/// One family's members, head first with a crown.
class FamilyMembers extends StatelessWidget {
  const FamilyMembers({super.key, required this.game, required this.head, required this.colors, this.me});

  final FamilyGame game;
  final String head;
  final FamilyColors colors;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final members = [head, ...game.membersOf(head).where((id) => id != head)];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in members)
          Opacity(
            opacity: game.isAway(id) ? 0.6 : 1,
            child: Chip(
              avatar: PlayerAvatar(name: game.nameOf(id), joinIndex: colors.indexOf(id), size: 24),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(id == me ? l10n.youSuffix(game.nameOf(id)) : game.nameOf(id))),
                  if (id == head) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.workspace_premium_rounded, size: 18, semanticLabel: l10n.familyHead),
                  ],
                  if (game.isAway(id)) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.wifi_off_rounded, size: 16, semanticLabel: l10n.familyOffline),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// What everyone can see: the families, the names (with who wrote the ones
/// that are out), and the last few guesses.
class FamilyBoard extends StatelessWidget {
  const FamilyBoard({super.key, required this.game, required this.colors, this.me});

  final FamilyGame game;
  final FamilyColors colors;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final paper = context.gameColors;
    final events = game.events.reversed.take(6).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.familyFamilies, style: theme.textTheme.titleMedium),
            for (final head in game.familyHeads) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (head == game.turn && !game.isOver) ...[
                    Icon(Icons.play_arrow_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 2),
                  ],
                  Expanded(
                    child: Text(
                      l10n.familyOf(game.nameOf(head)),
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FamilyMembers(game: game, head: head, colors: colors, me: me),
            ],
            const SizedBox(height: 18),
            Text(l10n.familyNames, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slip in game.slips)
                  _SlipChip(
                    text: game.revealed.contains(slip.id) ? '${slip.text} · ${game.nameOf(slip.writerId)}' : slip.text,
                    ink: slip.ink,
                    writer: game.revealed.contains(slip.id) ? game.nameOf(slip.writerId) : null,
                    out: game.revealed.contains(slip.id),
                    paper: paper,
                  ),
              ],
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(l10n.familyLastGuesses, style: theme.textTheme.titleMedium),
              for (final e in events)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        e.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 18,
                        color: e.correct ? paper.live : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      if (game.slip(e.slipId)?.ink case final ink?) ...[
                        SlipLabel(text: '', ink: ink, inkHeight: 26),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          (e.correct ? l10n.familyEventCorrect : l10n.familyEventWrong)(
                            game.nameOf(e.askerId),
                            game.nameOf(e.targetId),
                            game.slip(e.slipId)?.text ?? '',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlipChip extends StatelessWidget {
  const _SlipChip({required this.text, required this.out, required this.paper, this.ink, this.writer});

  final String text;

  /// A handwritten name: the drawing shows instead of [text], then the [writer] once caught.
  final SlipInk? ink;
  final String? writer;
  final bool out;
  final GameColors paper;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: out ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: paper.slipPaper,
          border: Border.all(color: paper.slipEdge),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ink == null
            ? Text(
                text,
                style: TextStyle(
                  color: paper.slipInk,
                  fontWeight: FontWeight.w700,
                  decoration: out ? TextDecoration.lineThrough : null,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SlipLabel(
                    text: text,
                    ink: ink,
                    inkHeight: 32,
                    style: TextStyle(color: paper.slipInk),
                  ),
                  if (writer != null)
                    Text(
                      ' · $writer',
                      style: TextStyle(color: paper.slipInk, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
      ),
    );
  }
}
