import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/shared_axis.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../../round_route.dart';
import '../state/round_cubit.dart';
import 'names_board_screen.dart';
import 'read_aloud_screen.dart';
import 'who_wrote_screen.dart';

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

class _RoundFlow extends StatelessWidget {
  const _RoundFlow({required this.args});

  final RoundArgs args;

  @override
  Widget build(BuildContext context) {
    final stage = context.select((RoundCubit cubit) => cubit.state.stage);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final cubit = context.read<RoundCubit>();
        if (cubit.state.stage == RoundStage.reveal) return cubit.backToBoard();
        if (await _confirmLeave(context) && context.mounted) Navigator.of(context).pop();
      },
      child: StageSwitcher(
        position: stage.index,
        child: switch (stage) {
          RoundStage.reading => const ReadAloudScreen(key: ValueKey(RoundStage.reading)),
          RoundStage.board => const NamesBoardScreen(key: ValueKey(RoundStage.board)),
          RoundStage.reveal => WhoWroteScreen(key: const ValueKey(RoundStage.reveal), players: args.players),
        },
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this round?'),
        content: const Text('The names stay in the bowl, and friends can change them again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    return leave ?? false;
  }
}
