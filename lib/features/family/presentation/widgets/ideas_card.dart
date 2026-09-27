import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';

/// The family's ideas for the next guess, most backed first. The host can back
/// one idea at a time and, as head on the family's turn, pick one to ask.
class IdeasCard extends StatelessWidget {
  const IdeasCard({
    super.key,
    required this.game,
    required this.me,
    required this.myHead,
    required this.canAsk,
    required this.onBack,
    required this.onUnback,
    required this.onUse,
  });

  final FamilyGame game;
  final String me;
  final String myHead;
  final bool canAsk;
  final void Function(Suggestion idea) onBack;
  final VoidCallback onUnback;
  final void Function(Suggestion idea) onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final ideas = game.suggestionsFor(myHead);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.familyIdeas, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (ideas.isEmpty)
              Text(
                l10n.familyNoIdeas,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            for (final idea in ideas)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _IdeaRow(
                  text: l10n.familyIdea(game.nameOf(idea.targetId), game.slip(idea.slipId)?.text ?? ''),
                  backers: l10n.familyBackers(idea.voters.length),
                  mine: idea.voters.contains(me),
                  onToggle: () => idea.voters.contains(me) ? onUnback() : onBack(idea),
                  onUse: canAsk ? () => onUse(idea) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IdeaRow extends StatelessWidget {
  const _IdeaRow({required this.text, required this.backers, required this.mine, required this.onToggle, this.onUse});

  final String text;
  final String backers;
  final bool mine;
  final VoidCallback onToggle;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(backers, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (mine)
            FilledButton.tonalIcon(
              onPressed: onToggle,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l10n.familyBacked),
            )
          else
            OutlinedButton(onPressed: onToggle, child: Text(l10n.familyBackIt)),
          if (onUse != null) ...[
            const SizedBox(width: 6),
            FilledButton(onPressed: onUse, child: Text(l10n.familyUseIdea)),
          ],
        ],
      ),
    );
  }
}
