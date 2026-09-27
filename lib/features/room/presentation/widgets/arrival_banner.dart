import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/game_colors.dart';
import '../../domain/room.dart';
import '../state/room_cubit.dart';
import '../../../../core/l10n/l10n.dart';

/// Pops a "Lina's name is in" banner in the player's colour each time a friend
/// drops their names in the bowl. Several arrivals queue up and show in turn.
class ArrivalBanners extends StatefulWidget {
  const ArrivalBanners({super.key});

  @override
  State<ArrivalBanners> createState() => _ArrivalBannersState();
}

typedef _Arrival = ({String name, int joinIndex});

class _ArrivalBannersState extends State<ArrivalBanners> with SingleTickerProviderStateMixin {
  late final AnimationController _life;
  final _queue = <_Arrival>[];
  _Arrival? _current;
  Room? _lastRoom;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(vsync: this, duration: Motion.banner)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _showNext();
      });
    _lastRoom = context.read<RoomCubit>().state.room;
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  /// Friends whose names just landed: new players, or returning players in a new round.
  static List<_Arrival> _arrivals(Room? before, Room? after) => [
    if (after != null)
      for (final (i, player) in after.players.indexed)
        if (!player.isHost && player.hasSubmitted && !(before?.playerById(player.id)?.hasSubmitted ?? false))
          (name: player.name, joinIndex: i),
  ];

  void _onRoom(Room? room) {
    final arrivals = _arrivals(_lastRoom, room);
    _lastRoom = room;
    if (arrivals.isEmpty) return;
    _queue.addAll(arrivals);
    if (_current == null) _showNext();
  }

  void _showNext() {
    setState(() => _current = _queue.isEmpty ? null : _queue.removeAt(0));
    if (_current != null) _life.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return BlocListener<RoomCubit, RoomState>(
      listenWhen: (previous, next) => previous.room != next.room,
      listener: (context, state) => _onRoom(state.room),
      child: current == null
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: _life,
              builder: (context, child) {
                final reduced = Motion.isReduced(context);
                final t = _life.value;
                final enter = reduced ? 1.0 : Motion.spring.transform(const Interval(0, 0.18).transform(t));
                final leave = reduced ? 0.0 : Curves.easeIn.transform(const Interval(0.85, 1).transform(t));
                return Opacity(
                  opacity: (1 - leave).clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(0, (enter - 1) * 64 - leave * 24), child: child),
                );
              },
              child: _Banner(key: ValueKey(current), arrival: current),
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.arrival});

  final _Arrival arrival;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final color = game.player(arrival.joinIndex);
    final initial = arrival.name.characters.first.toUpperCase();
    return Semantics(
      liveRegion: true,
      label: context.l10n.arrival(arrival.name),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: game.onPlayer,
              child: Text(
                initial,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.l10n.arrival(arrival.name),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: game.onPlayer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
