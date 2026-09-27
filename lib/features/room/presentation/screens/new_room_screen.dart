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
              SectionLabel(l10n.gameMode),
              const SizedBox(height: 10),
              for (final (mode, title, detail, icon) in [
                (GameMode.classic, l10n.modeClassic, l10n.modeClassicDetail, Icons.local_dining_rounded),
                (GameMode.celebrity, l10n.modeCelebrity, l10n.modeCelebrityDetail, Icons.timer_rounded),
                (GameMode.family, l10n.modeFamily, l10n.modeFamilyDetail, Icons.diversity_3_rounded),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ModeOption(
                    title: title,
                    detail: detail,
                    icon: icon,
                    selected: state.mode == mode,
                    onTap: () => cubit.setMode(mode),
                  ),
                ),
              if (state.mode == GameMode.celebrity) ...[
                const SizedBox(height: 16),
                SectionLabel(l10n.teams),
                const SizedBox(height: 10),
                _TeamSettings(setup: state.teamSetup, onChanged: cubit.setTeamSetup),
              ],
              if (state.mode == GameMode.family) ...[
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    value: state.familyChat,
                    onChanged: cubit.setFamilyChat,
                    title: Text(l10n.familyChatSwitch, style: theme.textTheme.titleMedium),
                    subtitle: Text(state.familyChat ? l10n.familyChatOn : l10n.familyChatOff),
                  ),
                ),
              ],
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

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.title,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamSettings extends StatelessWidget {
  const _TeamSettings({required this.setup, required this.onChanged});

  final TeamSetup setup;
  final ValueChanged<TeamSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.teamCount, style: theme.textTheme.titleMedium)),
                IconButton.filledTonal(
                  tooltip: l10n.fewerTeams,
                  onPressed: setup.count > TeamSetup.minTeams
                      ? () => onChanged(setup.copyWith(count: setup.count - 1))
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 36,
                  child: Text('${setup.count}', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.moreTeams,
                  onPressed: setup.count < TeamSetup.maxTeams
                      ? () => onChanged(setup.copyWith(count: setup.count + 1))
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.teamPickLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (pick, label) in [
                  (TeamPick.random, l10n.teamPickRandom),
                  (TeamPick.players, l10n.teamPickPlayers),
                  (TeamPick.host, l10n.teamPickHost),
                ])
                  SelectChip(
                    label: label,
                    selected: setup.pick == pick,
                    onTap: () => onChanged(setup.copyWith(pick: pick)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.turnLength, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final seconds in TeamSetup.turnChoices)
                  SelectChip(
                    label: l10n.secondsShort(seconds),
                    selected: setup.turnSeconds == seconds,
                    onTap: () => onChanged(setup.copyWith(turnSeconds: seconds)),
                  ),
              ],
            ),
          ],
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
