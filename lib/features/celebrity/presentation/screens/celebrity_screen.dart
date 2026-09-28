import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/shared_axis.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../../celebrity_route.dart';
import '../../domain/celebrity_game.dart';
import '../state/celebrity_cubit.dart';
import 'hand_off_screen.dart';
import 'results_screen.dart';
import 'intro_screen.dart';
import 'teams_screen.dart';
import 'turn_over_screen.dart';
import 'turn_screen.dart';

/// A team race from teams to results. Pops with a [GameExit], or null to go back to the lobby.
class CelebrityScreen extends StatelessWidget {
  const CelebrityScreen({super.key, required this.args});

  final CelebrityArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CelebrityCubit(args),
      child: KeepScreenOn(
        child: _PauseWhenHidden(child: _Flow(args: args)),
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({required this.args});

  final CelebrityArgs args;

  @override
  Widget build(BuildContext context) {
    final (phase, step) = context.select((CelebrityCubit c) => (c.state.game.phase, c.state.step));
    return BlocListener<CelebrityCubit, CelebrityState>(
      listenWhen: (previous, current) =>
          current.game.phase == CelebrityPhase.playing && current.secondsLeft != previous.secondsLeft ||
          current.game.phase == CelebrityPhase.turnOver && previous.game.phase == CelebrityPhase.playing,
      listener: (context, state) {
        if (state.game.phase == CelebrityPhase.turnOver) {
          if (!state.game.bowlEmpty) Haptics.timeUp();
        } else if (state.secondsLeft <= 5) {
          Haptics.countdown();
        }
      },
      child: PopScope<Object?>(
        canPop: phase == CelebrityPhase.finished,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          // The clock stops while the host decides; staying shows the pause screen.
          context.read<CelebrityCubit>().pause();
          if (await _confirmLeave(context) && context.mounted) Navigator.of(context).pop();
        },
        child: StageSwitcher(
          position: step,
          child: switch (phase) {
            CelebrityPhase.teams => TeamsScreen(key: ValueKey(step)),
            CelebrityPhase.intro => IntroScreen(key: ValueKey(step)),
            CelebrityPhase.handOff => HandOffScreen(key: ValueKey(step)),
            CelebrityPhase.playing => TurnScreen(key: ValueKey(step), turnSeconds: args.setup.turnSeconds),
            CelebrityPhase.turnOver => TurnOverScreen(key: ValueKey(step)),
            CelebrityPhase.finished => ResultsScreen(key: ValueKey(step), category: args.category),
          },
        ),
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

/// Stops the turn clock when the app goes to the background, e.g. a phone call.
class _PauseWhenHidden extends StatefulWidget {
  const _PauseWhenHidden({required this.child});

  final Widget child;

  @override
  State<_PauseWhenHidden> createState() => _PauseWhenHiddenState();
}

class _PauseWhenHiddenState extends State<_PauseWhenHidden> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onHide: () => context.read<CelebrityCubit>().pause(),
  );

  @override
  void initState() {
    super.initState();
    _listener;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
