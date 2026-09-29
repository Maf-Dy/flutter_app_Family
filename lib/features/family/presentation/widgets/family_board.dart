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

  /// The members as [me] sees them: with secret catches, only their own family's are known.

  final FamilyGame game;
  final String head;
  final FamilyColors colors;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final members = [head, ...game.membersSeenBy(me, head).where((id) => id != head)];
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
    final myHead = me == null || game.player(me!) == null ? null : game.headOf(me!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.familyFamilies, style: theme.textTheme.titleMedium),
            for (final head in game.familyHeadsSeenBy(me)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if ((game.secret ? head == game.headSeenBy(me, game.turnPlayer) : head == game.turn) &&
                      !game.isOver) ...[
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
            // Only names already out show: remembering the rest is the game. All of them show at the end.
            if (!game.isOver) ...[
              Text(
                l10n.boardHintHidden,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slip in game.slips)
                  if (game.isOver || game.writerShownTo(me, slip.id))
                    _SlipChip(
                      text: game.writerShownTo(me, slip.id)
                          ? '${slip.text} · ${game.nameOf(slip.writerId)}'
                          : slip.text,
                      out: game.writerShownTo(me, slip.id),
                      wanted: slip.id == game.wanted && !game.isOver,
                      ink: slip.ink,
                      writer: game.writerShownTo(me, slip.id) ? game.nameOf(slip.writerId) : null,
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
                  child: _EventLine(game: game, event: e, seen: game.seesEvent(me, e), myHead: myHead),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One guess on the board, in words. Guesses the viewer isn't allowed to see
/// (secret catches) only say that someone asked.
class _EventLine extends StatelessWidget {
  const _EventLine({required this.game, required this.event, required this.seen, required this.myHead});

  final FamilyGame game;
  final GuessEvent event;
  final bool seen;
  final String? myHead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final paper = context.gameColors;
    final e = event;
    final asker = game.nameOf(e.askerId);
    final target = game.nameOf(e.targetId);
    final (IconData icon, Color color, String text) = switch (e) {
      _ when !seen => (Icons.help_rounded, theme.colorScheme.onSurfaceVariant, l10n.familyEventSecret(asker)),
      GuessEvent(blocked: true) => (
        Icons.back_hand_rounded,
        theme.colorScheme.tertiary,
        l10n.familyEventBlocked(asker, target),
      ),
      _ => (
        e.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
        e.correct ? paper.live : theme.colorScheme.error,
        [
          switch (e.kind) {
            AskKind.counter => l10n.familyEventCounterTag,
            AskKind.revenge => l10n.familyEventRevengeTag,
            AskKind.ask => '',
          },
          (e.correct ? l10n.familyEventCorrect : l10n.familyEventWrong)(asker, target, game.slip(e.slipId)?.text ?? ''),
          if (e.wantedCaught) l10n.familyEventWantedTag,
        ].where((part) => part.isNotEmpty).join(' '),
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        if ((seen ? game.slip(e.slipId)?.ink : null) case final ink?) ...[
          SlipLabel(text: '', ink: ink, inkHeight: 26),
          const SizedBox(width: 6),
        ],
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _SlipChip extends StatelessWidget {
  const _SlipChip({
    required this.text,
    required this.out,
    required this.paper,
    this.wanted = false,
    this.ink,
    this.writer,
  });

  final String text;

  /// A handwritten name: the drawing shows instead of [text], then the [writer] once caught.
  final SlipInk? ink;
  final String? writer;
  final bool out;
  final GameColors paper;

  /// The wanted name: drawn with a red border.
  final bool wanted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: out ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: paper.slipPaper,
          border: Border.all(
            color: wanted ? Theme.of(context).colorScheme.error : paper.slipEdge,
            width: wanted ? 2 : 1,
          ),
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
