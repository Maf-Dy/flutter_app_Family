import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';

Future<void> showHowToPlay(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => const _HowToPlay());

class _HowToPlay extends StatelessWidget {
  const _HowToPlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final steps = [l10n.howToPlayStep1, l10n.howToPlayStep2, l10n.howToPlayStep3, l10n.howToPlayStep4];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.howToPlay, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final (i, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text('${i + 1}', style: theme.textTheme.labelMedium),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.gotIt)),
          ],
        ),
      ),
    );
  }
}
