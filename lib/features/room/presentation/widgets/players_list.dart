import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/room.dart';
import '../../../../core/l10n/l10n.dart';
import '../team_style.dart';

/// Who has joined, and whether their names are in. Never shows what they wrote.
class PlayersList extends StatelessWidget {
  const PlayersList({super.key, required this.room, this.onRemove});

  final Room room;

  /// Takes a friend out of the room after the host confirms. Null hides the option.
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    final hostJoined = room.host != null;
    return Column(
      children: [
        for (final (i, player) in room.players.indexed)
          _Arrive(
            key: ValueKey(player.id),
            child: _PlayerRow(
              name: player.isHost ? context.l10n.youSuffix(player.name) : player.name,
              team: room.playersPickTeams ? player.team : null,
              joinIndex: i,
              status: _status(context.l10n, player),
              onTap: onRemove == null || player.isHost || !room.isCollecting
                  ? null
                  : () => _confirmRemove(context, player),
            ),
          ),
        if (!hostJoined)
          _PlayerRow(
            name: context.l10n.youSuffix(room.hostName),
            joinIndex: room.players.length,
            status: (label: context.l10n.waiting, done: false),
          ),
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, Player player) async {
    final l10n = context.l10n;
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removePlayerTitle(player.name)),
        content: Text(l10n.removePlayerBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.stay)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.removePlayer)),
        ],
      ),
    );
    if (remove ?? false) onRemove?.call(player.id);
  }

  ({String label, bool done}) _status(AppLocalizations l10n, Player player) {
    if (!player.hasSubmitted) return (label: l10n.waiting, done: false);
    if (player.isHost && player.secrets.length < room.namesPerPlayer) {
      return (label: l10n.secretsOf(player.secrets.length, room.namesPerPlayer), done: false);
    }
    return (label: l10n.nameIn, done: true);
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.name, required this.joinIndex, required this.status, this.team, this.onTap});

  final String name;
  final VoidCallback? onTap;

  /// The team the player picked, shown when players choose their teams.
  final int? team;
  final int joinIndex;
  final ({String label, bool done}) status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = context.gameColors;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    if (team case final team?)
                      Text(
                        teamName(context.l10n, team),
                        style: theme.textTheme.labelMedium?.copyWith(color: teamColor(context, team)),
                      ),
                  ],
                ),
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
