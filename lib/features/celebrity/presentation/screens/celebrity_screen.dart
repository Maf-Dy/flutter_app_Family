import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/shared_axis.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../../celebrity_route.dart';
import '../../domain/face_off_game.dart';
import '../state/celebrity_cubit.dart';
import 'pick_screen.dart';
import 'results_screen.dart';
import 'reveal_screen.dart';
import 'teams_screen.dart';

/// A face-off from teams to results. Pops with a [GameExit], or null to go back to the lobby.
class CelebrityScreen extends StatelessWidget {
  const CelebrityScreen({super.key, required this.args});

  final CelebrityArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CelebrityCubit(args),
      child: KeepScreenOn(child: _Flow(args: args)),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({required this.args});

  final CelebrityArgs args;

  @override
  Widget build(BuildContext context) {
    final (phase, step) = context.select((CelebrityCubit c) => (c.state.game.phase, c.state.step));
    return PopScope<Object?>(
      canPop: phase == FaceOffPhase.finished,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave(context) && context.mounted) Navigator.of(context).pop();
      },
      child: StageSwitcher(
        position: step,
        child: switch (phase) {
          FaceOffPhase.teams => TeamsScreen(key: ValueKey(step)),
          FaceOffPhase.pick => PickScreen(key: ValueKey(step)),
          FaceOffPhase.reveal => RevealScreen(key: ValueKey(step)),
          FaceOffPhase.finished => ResultsScreen(key: ValueKey(step), category: args.category),
        },
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveGameTitle),
        content: Text(l10n.leaveGameBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.stay)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.leave)),
        ],
      ),
    );
    return leave ?? false;
  }
}
