import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/how_to_play_card.dart';

/// Before the first turn: the rule and how to play.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.modeCelebrity)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.record_voice_over_rounded, size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(l10n.roundDescribe, textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(l10n.roundDescribeDetail, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 20),
                  const HowToPlayCard(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: context.read<CelebrityCubit>().toHandOff, child: Text(l10n.startRound)),
        ),
      ),
    );
  }
}
