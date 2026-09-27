import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/room.dart';

/// Who has joined, and whether their names are in. Never shows what they wrote.
class PlayersList extends StatelessWidget {
  const PlayersList({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final hostJoined = room.host != null;
    return Column(
      children: [
        for (final (i, player) in room.players.indexed)
          _Arrive(
            key: ValueKey(player.id),
            child: _PlayerRow(name: player.name, joinIndex: i, status: _status(player)),
          ),
        if (!hostJoined)
          _PlayerRow(name: 'You', joinIndex: room.players.length, status: (label: 'Waiting', done: false)),
      ],
    );
  }

  ({String label, bool done}) _status(Player player) {
    if (!player.hasSubmitted) return (label: 'Waiting', done: false);
    if (player.isHost && player.secrets.length < room.namesPerPlayer) {
      return (label: '${player.secrets.length} of ${room.namesPerPlayer}', done: false);
    }
    return (label: 'Name in', done: true);
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.name, required this.joinIndex, required this.status});

  final String name;
  final int joinIndex;
  final ({String label, bool done}) status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = context.gameColors;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            PlayerAvatar(name: name, joinIndex: joinIndex),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status.done ? game.liveContainer : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                status.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: status.done ? game.live : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Springs a row in the first time it is built.
class _Arrive extends StatelessWidget {
  const _Arrive({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.settle),
      curve: Motion.spring,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
      ),
      child: child,
    );
  }
}
