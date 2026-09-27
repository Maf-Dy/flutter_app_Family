import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/room.dart';
import '../../domain/room_beacon.dart';
import '../category_label.dart';
import '../state/nearby_rooms_cubit.dart';

/// "Join a game": the rooms hosted on this Wi-Fi. Joining opens the same page
/// the host's QR code does, in the browser.
class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NearbyRoomsCubit(context.read<RoomFinder>()),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.joinGame)),
        body: SafeArea(
          child: BlocBuilder<NearbyRoomsCubit, NearbyRoomsState>(
            builder: (context, state) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: switch (state) {
                  NearbyRoomsState(failed: true) => _Message(text: context.l10n.cannotLookForGames),
                  NearbyRoomsState(rooms: []) => const _Searching(),
                  NearbyRoomsState(:final rooms) => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: rooms.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => i < rooms.length
                        ? _RoomTile(room: rooms[i])
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              context.l10n.lookingForGamesHelp,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(context.l10n.lookingForGames, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            context.l10n.lookingForGamesHelp,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.tertiary),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final NearbyRoom room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final a = room.announcement;
    final mode = switch (a.mode) {
      GameMode.classic => l10n.modeClassic,
      GameMode.celebrity => l10n.modeCelebrity,
      GameMode.family => l10n.modeFamily,
    };
    final status = a.open ? l10n.nearbyRoomPlayers(a.players) : l10n.nearbyRoomPlaying;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nearbyRoomTitle(a.hostName), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${categoryLabel(l10n, a.category)} · $mode',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${l10n.roomCodeLabel(a.code)} · $status',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _open(context), child: Text(l10n.joinRoomButton)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.cannotOpenRoom(room.joinUrl.toString());
    final opened = await context.read<OpenRoomLink>()(room.joinUrl);
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
