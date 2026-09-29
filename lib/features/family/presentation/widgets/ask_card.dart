import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';
import '../../../round/presentation/widgets/paper_slip.dart';

/// "Who wrote which name?" pickers, and the button that asks (the head, on the
/// family's turn) or suggests the idea to the family (everyone else).
class AskCard extends StatelessWidget {
  const AskCard({
    super.key,
    required this.game,
    required this.myHead,
    required this.canAsk,
    required this.target,
    required this.slip,
    this.me,
    required this.onTarget,
    required this.onSlip,
    required this.onSubmit,
    this.error,
  });

  final FamilyGame game;
  final String myHead;

  /// The host's own id: names they wrote aren't offered, they already know those.
  final String? me;

  /// The host heads the family and it's their turn: the button asks for real.
  final bool canAsk;
  final String? target;
  final int? slip;
  final ValueChanged<String?> onTarget;
  final ValueChanged<int?> onSlip;
  final VoidCallback onSubmit;

  /// Shown under the pickers, e.g. when one of them is empty.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final people = game.askableFor(myHead);
    final names = [
      for (final s in game.hiddenSlips)
        if (s.writerId != me) s,
    ];
    // A friend's move can take a choice off the table; never hand the dropdown a value it doesn't list.
    final target = people.any((p) => p.id == this.target) ? this.target : null;
    final slip = names.any((s) => s.id == this.slip) ? this.slip : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Picker<String>(
              label: l10n.familyWho,
              value: target,
              items: [for (final p in people) (value: p.id, label: p.name)],
              onChanged: onTarget,
            ),
            const SizedBox(height: 10),
            _Picker<int>(
              label: l10n.familyWhich,
              value: slip,
              items: [for (final s in names) (value: s.id, label: s.text)],
              inks: {for (final s in names) s.id: ?s.ink},
              onChanged: onSlip,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (canAsk)
              FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: Text(l10n.familyAsk),
              )
            else
              FilledButton.tonalIcon(
                onPressed: onSubmit,
                icon: const Icon(Icons.lightbulb_rounded),
                label: Text(l10n.familySuggest),
              ),
          ],
        ),
      ),
    );
  }
}

class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.inks = const {},
  });

  final String label;
  final T? value;
  final List<({T value, String label})> items;

  /// Handwritten names, shown as their drawing instead of the label.
  final Map<T, SlipInk> inks;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 6, 8, 6)),
      isEmpty: value == null,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item.value,
                child: SlipLabel(
                  text: item.label,
                  ink: inks[item.value],
                  inkHeight: 34,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
