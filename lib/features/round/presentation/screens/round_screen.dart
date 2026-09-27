import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/motion/shared_axis.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../../round_route.dart';
import '../state/round_cubit.dart';
import '../widgets/shuffle_intro.dart';
import 'names_board_screen.dart';
import 'read_aloud_screen.dart';
import 'who_wrote_screen.dart';
import '../../../../core/l10n/l10n.dart';

/// One round at the table. Pops with a [RoundExit], or null to go back to the lobby.
class RoundScreen extends StatelessWidget {
  const RoundScreen({super.key, required this.args});

  final RoundArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoundCubit(args.slips),
      child: KeepScreenOn(child: _RoundFlow(args: args)),
    );
  }
}

class _RoundFlow extends StatefulWidget {
  const _RoundFlow({required this.args});

  final RoundArgs args;

  @override
  State<_RoundFlow> createState() => _RoundFlowState();
}

class _RoundFlowState extends State<_RoundFlow> {
  /// The bowl-shaking intro plays once per round, before the first name.
  bool _shuffling = true;

  RoundArgs get args => widget.args;

  @override
  Widget build(BuildContext context) {
    final stage = context.select((RoundCubit cubit) => cubit.state.stage);
    final showIntro = _shuffling && !Motion.isReduced(context);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final cubit = context.read<RoundCubit>();
        if (cubit.state.stage == RoundStage.reveal) return cubit.backToBoard();
        if (await _confirmLeave(context) && context.mounted) Navigator.of(context).pop();
      },
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.standard),
        child: showIntro
            ? ShuffleIntro(
                key: const ValueKey('shuffle'),
                count: args.slips.length,
                onDone: () => setState(() => _shuffling = false),
              )
            : StageSwitcher(
                key: const ValueKey('stages'),
                position: stage.index,
                child: switch (stage) {
                  RoundStage.reading => const ReadAloudScreen(key: ValueKey(RoundStage.reading)),
                  RoundStage.board => const NamesBoardScreen(key: ValueKey(RoundStage.board)),
                  RoundStage.reveal => WhoWroteScreen(key: const ValueKey(RoundStage.reveal), players: args.players),
                },
              ),
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.leaveRoundTitle),
        content: Text(context.l10n.leaveRoundBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.stay)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.leave)),
        ],
      ),
    );
    return leave ?? false;
  }
}
