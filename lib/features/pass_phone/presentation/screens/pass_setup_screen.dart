import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../room/domain/room.dart';
import '../../../room/presentation/category_label.dart';
import '../../../room/presentation/widgets/room_options.dart';
import '../../../room/presentation/widgets/section_label.dart';
import '../../../room/presentation/widgets/select_chip.dart';
import '../state/pass_phone_cubit.dart';

/// The game's settings. No list of players: everyone adds their own name on their turn.
class PassSetupScreen extends StatelessWidget {
  const PassSetupScreen({super.key});

  Future<void> _pickCustomCategory(BuildContext context, GameCategory current) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => CustomCategoryDialog(initial: current.custom ?? ''),
    );
    final clean = Room.tidy(text ?? '');
    if (clean.isNotEmpty && context.mounted) context.read<PassPhoneCubit>().selectCategory(GameCategory.custom(clean));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PassPhoneCubit>().state;
    final cubit = context.read<PassPhoneCubit>();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final custom = state.category.custom;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.passSetupTitle)),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.passSetupNote,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              SectionLabel(l10n.gameMode),
              const SizedBox(height: 10),
              for (final (mode, title, detail, icon) in [
                (GameMode.classic, l10n.modeClassic, l10n.modeClassicDetail, Icons.local_dining_rounded),
                (GameMode.celebrity, l10n.modeCelebrity, l10n.modeCelebrityDetail, Icons.timer_rounded),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ModeOption(
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
                TeamSettings(
                  setup: state.teamSetup,
                  onChanged: cubit.setTeamSetup,
                  picks: const [TeamPick.random, TeamPick.host],
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
                    onTap: () => _pickCustomCategory(context, state.category),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionLabel(l10n.namesPerPlayer),
              const SizedBox(height: 10),
              NamesPerPlayerCard(
                count: state.namesPerPlayer,
                max: Room.maxNamesFor(state.mode),
                onChanged: cubit.setNamesPerPlayer,
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: cubit.begin, child: Text(l10n.passBegin)),
        ),
      ),
    );
  }
}
