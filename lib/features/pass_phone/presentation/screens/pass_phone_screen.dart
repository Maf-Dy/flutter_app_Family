import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/shared_axis.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/game_exit.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../state/pass_phone_cubit.dart';
import 'pass_setup_screen.dart';
import 'passed_screen.dart';
import 'reader_screen.dart';
import 'your_turn_screen.dart';

/// Pass the phone: one phone goes round the table, then the game plays on it.
class PassPhoneScreen extends StatelessWidget {
  const PassPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => PassPhoneCubit(), child: const _Flow());
  }
}

class _Flow extends StatelessWidget {
  const _Flow();

  @override
  Widget build(BuildContext context) {
    final (stage, step) = context.select((PassPhoneCubit c) => (c.state.stage, c.state.step));
    return PopScope<Object?>(
      canPop: stage == PassStage.setup,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _back(context);
      },
      child: KeepScreenOn(
        child: StageSwitcher(
          position: step,
          child: switch (stage) {
            PassStage.setup => PassSetupScreen(key: ValueKey(step)),
            PassStage.typing => YourTurnScreen(key: ValueKey(step)),
            PassStage.passed => PassedScreen(key: ValueKey(step), onStart: () => _everyoneIn(context)),
            PassStage.reader => ReaderScreen(key: ValueKey(step), onStart: () => _play(context)),
          },
        ),
      ),
    );
  }

  /// Back from someone's turn returns to the hand-off; anywhere else, stopping asks first.
  Future<void> _back(BuildContext context) async {
    final cubit = context.read<PassPhoneCubit>();
    final state = cubit.state;
    final bowl = state.bowl;
    switch (state.stage) {
      case PassStage.setup:
        return;
      case PassStage.reader:
        cubit.backToPassing();
      case PassStage.typing when bowl != null && bowl.playersIn.isNotEmpty:
        cubit.cancelTurn();
      case PassStage.typing when bowl == null || bowl.players.isEmpty:
        cubit.stop();
      case PassStage.typing || PassStage.passed:
        if (await _confirmStop(context)) cubit.stop();
    }
  }

  Future<bool> _confirmStop(BuildContext context) async {
    final l10n = context.l10n;
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.passStopTitle),
        content: Text(l10n.passStopBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.passKeepGoing)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.passStop)),
        ],
      ),
    );
    return stop ?? false;
  }

  /// Classic hands the phone to a reader first; Team race goes straight to the teams.
  void _everyoneIn(BuildContext context) {
    final cubit = context.read<PassPhoneCubit>();
    if (cubit.celebrityArgs() != null) {
      unawaited(_play(context));
    } else {
      cubit.everyoneIn();
    }
  }

  Future<void> _play(BuildContext context) async {
    final cubit = context.read<PassPhoneCubit>();
    final start = switch ((cubit.roundArgs(), cubit.celebrityArgs())) {
      (final round?, _) => (AppRoutes.round, round as Object),
      (_, final race?) => (AppRoutes.celebrity, race as Object),
      _ => null,
    };
    if (start == null) return;
    unawaited(Haptics.start());
    final exit = await Navigator.of(context).pushNamed<GameExit>(start.$1, arguments: start.$2);
    if (!context.mounted) return;
    if (exit == GameExit.endGame) {
      Navigator.of(context).pop();
      return;
    }
    cubit.afterGame(exit);
  }
}
