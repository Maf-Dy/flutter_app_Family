import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// The team race rules in six short lines, shown before the first round.
class HowToPlayCard extends StatelessWidget {
  const HowToPlayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rules = [
      (Icons.emoji_food_beverage_rounded, l10n.howToPlayBowl),
      (Icons.timer_rounded, l10n.howToPlayTurn),
      (Icons.redo_rounded, l10n.howToPlaySkip),
      (Icons.emoji_events_rounded, l10n.howToPlayWin),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.howToPlay, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final (icon, text) in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
