import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../state/celebrity_cubit.dart';
import '../../../room/presentation/team_style.dart';

/// Between turns: the screen turns the team's colour and names who takes the phone.
class HandOffScreen extends StatelessWidget {
  const HandOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final game = context.watch<CelebrityCubit>().state.game;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final color = teamColor(context, game.team);
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.teamTurn(teamName(l10n, game.team)),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(color: onColor),
                ),
                const SizedBox(height: 24),
                Text(l10n.passPhoneTo, style: theme.textTheme.titleMedium?.copyWith(color: onColor)),
                Text(
                  cubit.nameOf(game.giverId),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(color: onColor),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.giverHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: onColor.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: cubit.startTurn,
                  style: FilledButton.styleFrom(
                    backgroundColor: onColor,
                    foregroundColor: color,
                    minimumSize: const Size(200, 56),
                  ),
                  child: Text(l10n.imReady),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
