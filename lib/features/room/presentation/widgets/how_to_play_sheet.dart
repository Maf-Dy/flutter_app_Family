import 'package:flutter/material.dart';

Future<void> showHowToPlay(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => const _HowToPlay());

class _HowToPlay extends StatelessWidget {
  const _HowToPlay();

  static const _steps = [
    'Everyone scans the QR code and secretly writes a name from the category.',
    'The host reads all the names aloud, once or twice.',
    'Put the phone down. Take turns asking someone “Did you write …?” Guess right and they join your family. The last family standing wins.',
    'Afterwards, tap “Who wrote what?” to see them all.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How to play', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final (i, step) in _steps.indexed)
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
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
          ],
        ),
      ),
    );
  }
}
