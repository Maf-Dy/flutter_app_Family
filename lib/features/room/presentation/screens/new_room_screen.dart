import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/state/settings_cubit.dart';
import '../../domain/room.dart';
import '../category_label.dart';
import '../state/room_cubit.dart';
import '../widgets/section_label.dart';
import '../widgets/select_chip.dart';

class NewRoomScreen extends StatefulWidget {
  const NewRoomScreen({super.key});

  @override
  State<NewRoomScreen> createState() => _NewRoomScreenState();
}

class _NewRoomScreenState extends State<NewRoomScreen> {
  late final _name = TextEditingController(text: context.read<SettingsCubit>().state.hostName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final settings = context.read<SettingsCubit>();
    final hostName = _name.text.trim();
    await settings.setHostName(hostName);
    if (!mounted) return;
    await context.read<RoomCubit>().openRoom(hostName: hostName.isEmpty ? context.l10n.you : hostName);
  }

  Future<void> _pickCustomCategory(GameCategory current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: current.custom ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customCategoryTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: GameCategory.maxCustomLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.customCategoryHint, counterText: ''),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.use)),
        ],
      ),
    );
    controller.dispose();
    final clean = Room.tidy(text ?? '');
    if (clean.isNotEmpty && mounted) context.read<RoomCubit>().selectCategory(GameCategory.custom(clean));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoomCubit>().state;
    final cubit = context.read<RoomCubit>();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final custom = state.category.custom;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newRoom)),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                maxLength: AppSettings.maxNameLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.yourName,
                  hintText: l10n.yourNameHint,
                  counterText: '',
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SectionLabel(l10n.category),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in PresetCategory.values)
                    SelectChip(
                      label: categoryLabel(l10n, GameCategory.preset(preset)),
                      selected: state.category.preset == preset,
                      onTap: () => cubit.selectCategory(GameCategory.preset(preset)),
                    ),
                  SelectChip(
                    label: custom ?? l10n.categoryCustom,
                    selected: custom != null,
                    onTap: () => _pickCustomCategory(state.category),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionLabel(l10n.namesPerPlayer),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.namesPerPlayerDetail,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: l10n.fewerNames,
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
                          semanticsLabel: l10n.namesPerPlayerValue(state.namesPerPlayer),
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: l10n.moreNames,
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
              SectionLabel(l10n.rules),
              const SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  value: state.allowDuplicates,
                  onChanged: cubit.setAllowDuplicates,
                  title: Text(l10n.sameNameTwice, style: theme.textTheme.titleMedium),
                  subtitle: Text(state.allowDuplicates ? l10n.sameNameTwiceOn : l10n.sameNameTwiceOff),
                ),
              ),
              const SizedBox(height: 28),
              SectionLabel(l10n.connection),
              const SizedBox(height: 10),
              _ConnectionSummary(connection: state.connection),
              const SizedBox(height: 10),
              Text(
                l10n.connectionNote,
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
            onPressed: state.opening ? null : _open,
            child: state.opening
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.openRoom),
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
    final l10n = context.l10n;
    final (icon, ok, title, detail) = switch (connection) {
      ConnectionChecking() => (Icons.wifi_find_rounded, false, l10n.checkingWifi, l10n.oneMoment),
      ConnectionReady() => (Icons.wifi_rounded, true, l10n.connected, l10n.connectedDetail),
      ConnectionStartingHotspot() => (Icons.wifi_tethering_rounded, false, l10n.startingHotspot, l10n.oneMoment),
      ConnectionAppHotspot() => (Icons.wifi_tethering_rounded, true, l10n.hotspotIsOn, l10n.hotspotIsOnDetail),
      ConnectionMissing(canCreateHotspot: true) => (
        Icons.wifi_off_rounded,
        false,
        l10n.noWifiHere,
        l10n.noWifiCanCreate,
      ),
      ConnectionMissing() => (Icons.wifi_off_rounded, false, l10n.noWifiHere, l10n.noWifiCannotCreate),
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
