import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/game_colors.dart';
import '../../domain/room.dart';
import '../state/room_cubit.dart';
import '../widgets/section_label.dart';
import '../widgets/select_chip.dart';

class NewRoomScreen extends StatelessWidget {
  const NewRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoomCubit>().state;
    final cubit = context.read<RoomCubit>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New room')),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in RoomState.categories)
                    SelectChip(
                      label: category,
                      selected: state.category == category,
                      onTap: () => cubit.selectCategory(category),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const SectionLabel('Names per player'),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'More names, longer game',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Fewer names',
                        onPressed: state.namesPerPlayer > 1
                            ? () => cubit.setNamesPerPlayer(state.namesPerPlayer - 1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${state.namesPerPlayer}',
                          textAlign: TextAlign.center,
                          semanticsLabel: '${state.namesPerPlayer} names per player',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'More names',
                        onPressed: state.namesPerPlayer < Room.maxNamesPerPlayer
                            ? () => cubit.setNamesPerPlayer(state.namesPerPlayer + 1)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SectionLabel('Connection'),
              const SizedBox(height: 10),
              _ConnectionSummary(connection: state.connection),
              const SizedBox(height: 10),
              Text(
                'Checked automatically. Nothing goes over the internet; the room lives on this phone.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: state.opening ? null : cubit.openRoom,
            child: state.opening
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Open room'),
          ),
        ),
      ),
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.connection});

  final Connection connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = context.gameColors;
    final (icon, ok, title, detail) = switch (connection) {
      ConnectionChecking() => (Icons.wifi_find_rounded, false, 'Checking Wi-Fi…', 'One moment.'),
      ConnectionReady() => (
        Icons.wifi_rounded,
        true,
        'Connected',
        'Friends join the same Wi-Fi, or your hotspot, and scan the code.',
      ),
      ConnectionAppHotspot() => (
        Icons.wifi_tethering_rounded,
        true,
        'Hotspot is on',
        'Friends scan the Wi-Fi code first, then the game code.',
      ),
      ConnectionMissing(canCreateHotspot: true) => (
        Icons.wifi_off_rounded,
        false,
        'No Wi-Fi here',
        'No problem. The app can make its own hotspot for the room.',
      ),
      ConnectionMissing() => (
        Icons.wifi_off_rounded,
        false,
        'No Wi-Fi here',
        'Turn on Wi-Fi or your phone\'s hotspot. You can do it after opening the room.',
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ok ? game.liveContainer : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: ok ? game.live : theme.colorScheme.tertiary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
