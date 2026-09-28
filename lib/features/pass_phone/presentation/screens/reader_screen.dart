import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/bowl.dart';
import '../state/pass_phone_cubit.dart';

/// Classic: the phone goes to whoever reads the names out.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final count = context.select((PassPhoneCubit c) => c.state.bowl?.slipCount ?? 0);
    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Bowl(width: 140),
                  const SizedBox(height: 12),
                  Text(
                    l10n.inTheBowl(count),
                    style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.passReaderTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(color: scheme.onPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.passReaderDetail,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.onPrimary,
                      foregroundColor: scheme.primary,
                      minimumSize: const Size(220, 56),
                    ),
                    child: Text(l10n.startReading),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: context.read<PassPhoneCubit>().backToPassing,
                    style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
                    child: Text(l10n.back),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
