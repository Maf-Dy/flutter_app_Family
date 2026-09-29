import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/safe_pop.dart';
import '../../domain/room.dart';
import 'select_chip.dart';

// Room settings shared by "Host a room" and "Pass the phone".

/// Owns its text controller, so the field can still draw while the dialog
/// fades out after it has been closed.
class CustomCategoryDialog extends StatefulWidget {
  const CustomCategoryDialog({super.key, required this.initial});

  final String initial;

  @override
  State<CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<CustomCategoryDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.customCategoryTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: GameCategory.maxCustomLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.customCategoryHint, counterText: ''),
        onSubmitted: (value) => context.popRoute(value),
      ),
      actions: [
        TextButton(onPressed: () => context.popRoute(), child: Text(l10n.cancel)),
        TextButton(onPressed: () => context.popRoute(_controller.text), child: Text(l10n.use)),
      ],
    );
  }
}

class ModeOption extends StatelessWidget {
  const ModeOption({
    super.key,
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

class TeamSettings extends StatelessWidget {
  const TeamSettings({super.key, required this.setup, required this.onChanged, this.picks = TeamPick.values});

  final TeamSetup setup;
  final ValueChanged<TeamSetup> onChanged;

  /// The ways of picking teams on offer; one phone can't let friends choose.
  final List<TeamPick> picks;

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
                  if (picks.contains(pick))
                    SelectChip(
                      label: label,
                      selected: setup.pick == pick,
                      onTap: () => onChanged(setup.copyWith(pick: pick)),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NamesPerPlayerCard extends StatelessWidget {
  const NamesPerPlayerCard({
    super.key,
    required this.count,
    required this.onChanged,
    this.max = Room.maxNamesPerPlayer,
  });

  final int count;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
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
              onPressed: count > 1 ? () => onChanged(count - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                semanticsLabel: l10n.namesPerPlayerValue(count),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            IconButton.filledTonal(
              tooltip: l10n.moreNames,
              onPressed: count < max ? () => onChanged(count + 1) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// The family game's house rules, each a switch.
class FamilyTwistsCard extends StatelessWidget {
  const FamilyTwistsCard({super.key, required this.twists, required this.onChanged});

  final FamilyTwists twists;
  final ValueChanged<FamilyTwists> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rules = [
      (l10n.twistSecret, l10n.twistSecretDetail, twists.secretCatches, (bool on) => twists.copyWith(secretCatches: on)),
      (l10n.twistCounter, l10n.twistCounterDetail, twists.counterCatch, (bool on) => twists.copyWith(counterCatch: on)),
      (l10n.twistWanted, l10n.twistWantedDetail, twists.wanted, (bool on) => twists.copyWith(wanted: on)),
      (l10n.twistRevenge, l10n.twistRevengeDetail, twists.revenge, (bool on) => twists.copyWith(revenge: on)),
      (l10n.twistRumors, l10n.twistRumorsDetail, twists.rumors, (bool on) => twists.copyWith(rumors: on)),
      (l10n.twistLetMeGo, l10n.twistLetMeGoDetail, twists.letMeGo, (bool on) => twists.copyWith(letMeGo: on)),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              l10n.twistsNote,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (final (title, detail, on, change) in rules)
            SwitchListTile(
              value: on,
              onChanged: (value) => onChanged(change(value)),
              title: Text(title, style: theme.textTheme.titleMedium),
              subtitle: Text(detail),
            ),
        ],
      ),
    );
  }
}
