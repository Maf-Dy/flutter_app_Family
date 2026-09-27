import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/shared_axis.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../../domain/network_access.dart';
import '../../domain/room_host.dart';
import '../state/room_cubit.dart';
import 'lobby_screen.dart';
import 'new_room_screen.dart';

/// One hosting session: pick settings, then the lobby. Leaving it closes the room.
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RoomCubit(network: context.read<NetworkAccess>(), createHost: context.read<RoomHostFactory>())..start(),
      child: const _RoomFlow(),
    );
  }
}

class _RoomFlow extends StatefulWidget {
  const _RoomFlow();

  @override
  State<_RoomFlow> createState() => _RoomFlowState();
}

class _RoomFlowState extends State<_RoomFlow> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from Settings (hotspot turned on by hand) should update the screen.
    _lifecycle = AppLifecycleListener(onResume: () => context.read<RoomCubit>().refreshConnection());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomCubit, RoomState>(
      listenWhen: (previous, current) => current.openFailed,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t open the room. Close other apps that share on Wi-Fi and try again.')),
      ),
      buildWhen: (previous, current) => previous.stage != current.stage,
      builder: (context, state) => PopScope<Object?>(
        canPop: state.stage == RoomStage.setup,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final cubit = context.read<RoomCubit>();
          if (await _confirmClose(context, cubit.state) && context.mounted) await cubit.closeRoom();
        },
        child: StageSwitcher(
          position: state.stage.index,
          child: switch (state.stage) {
            RoomStage.setup => const NewRoomScreen(key: ValueKey(RoomStage.setup)),
            RoomStage.lobby => const KeepScreenOn(key: ValueKey(RoomStage.lobby), child: LobbyScreen()),
          },
        ),
      ),
    );
  }

  Future<bool> _confirmClose(BuildContext context, RoomState state) async {
    if (state.room?.players.isEmpty ?? true) return true;
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close the room?'),
        content: const Text('Friends\' pages stop working and the names in the bowl are cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep open')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close room')),
        ],
      ),
    );
    return close ?? false;
  }
}
