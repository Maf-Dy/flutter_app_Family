import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';
import 'ask_card.dart';

/// The wanted name, and any extra asks the host's family has saved.
class WantedCard extends StatelessWidget {
  const WantedCard({super.key, required this.game, required this.myHead});

  final FamilyGame game;
  final String? myHead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final wanted = game.wanted == null ? null : game.slip(game.wanted!);
    final saved = myHead == null ? 0 : game.bonus[myHead] ?? 0;
    if (wanted == null && saved == 0) return const SizedBox.shrink();
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.local_police_rounded, color: theme.colorScheme.onErrorContainer, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wanted != null) ...[
                    Text(
                      l10n.wantedTitle(wanted.text),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.wantedDetail,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ],
                  if (saved > 0)
                    Text(
                      l10n.wantedBonus(saved),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the game waits on: the host's own answer ("فكّك مني", a counter-catch
/// or revenge), or who everyone is waiting for.
class PendingCard extends StatefulWidget {
  const PendingCard({
    super.key,
    required this.game,
    required this.me,
    required this.onLetMeGo,
    required this.onCounter,
    required this.onPassCounter,
    required this.onRevenge,
    required this.onPassRevenge,
  });

  final FamilyGame game;

  /// The host's id, or null when watching.
  final String? me;
  final void Function({required bool use}) onLetMeGo;
  final void Function(String targetId, int slipId) onCounter;
  final VoidCallback onPassCounter;
  final void Function(int slipId) onRevenge;
  final VoidCallback onPassRevenge;

  @override
  State<PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<PendingCard> {
  String? _target;
  int? _slip;
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The name picked, or typed and matched against [targetId]'s; shows why when it can't be found.
  int? _pickedSlip(FamilyGame game, String me, String? targetId) {
    final slip = game.handwritten ? _slip : game.slipNamed(_name.text, head: game.headOf(me), targetId: targetId);
    if (slip == null) setState(() => _error = context.l10n.familyErrorUnknownName);
    return slip;
  }

  List<Widget> get _errorLine => [
    if (_error case final error?) ...[
      const SizedBox(height: 8),
      Text(
        error,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700),
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final move = game.pending;
    if (move == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final me = widget.me;
    final asker = game.nameOf(move.askerId);
    if (me == null || move.responderId != me) {
      // With secret catches, people outside the ask don't learn who was asked.
      final involved = me != null && game.headOf(me) == game.headOf(move.askerId);
      final text = game.secret && !involved
          ? l10n.pendingWaitingSomeone
          : l10n.pendingWaiting(game.nameOf(move.responderId));
      return Card(
        child: ListTile(leading: const Icon(Icons.hourglass_top_rounded), title: Text(text)),
      );
    }

    final List<Widget> body;
    switch (move.kind) {
      case PendingKind.letMeGo:
        body = [
          Text(l10n.letMeGoAsked(asker, game.slip(move.slipId)?.text ?? ''), style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.letMeGoHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => widget.onLetMeGo(use: true),
                  icon: const Icon(Icons.back_hand_rounded),
                  label: Text(l10n.letMeGoUse),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(onPressed: () => widget.onLetMeGo(use: false), child: Text(l10n.letMeGoAnswer)),
              ),
            ],
          ),
        ];
      case PendingKind.counter:
        final targets = game.counterTargetsFor(me);
        final slips = [
          for (final s in game.slips)
            if (!game.revealed.contains(s.id) && s.writerId != me) s,
        ];
        final target = targets.contains(_target) ? _target : null;
        body = [
          Text(l10n.counterTitle(asker), style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.counterHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          FamilyPicker<String>(
            label: l10n.familyWho,
            value: target,
            items: [for (final id in targets) (value: id, label: game.nameOf(id))],
            onChanged: (id) => setState(() => _target = id),
          ),
          const SizedBox(height: 10),
          NameEntry(
            game: game,
            controller: _name,
            slips: slips,
            slip: _slip,
            onSlip: (id) => setState(() => _slip = id),
          ),
          ..._errorLine,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: target == null
                      ? null
                      : () {
                          final slip = _pickedSlip(game, me, target);
                          if (slip != null) widget.onCounter(target, slip);
                        },
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.counterShoot),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: widget.onPassCounter, child: Text(l10n.passShot)),
            ],
          ),
        ];
      case PendingKind.revenge:
        final slips = [
          for (final s in game.slips)
            if (!game.revealed.contains(s.id) && s.writerId != me) s,
        ];
        body = [
          Text(l10n.revengeTitle(asker), style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.revengeHint(asker), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          NameEntry(
            game: game,
            controller: _name,
            slips: slips,
            slip: _slip,
            onSlip: (id) => setState(() => _slip = id),
          ),
          ..._errorLine,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final slip = _pickedSlip(game, me, move.askerId);
                    if (slip != null) widget.onRevenge(slip);
                  },
                  icon: const Icon(Icons.bolt_rounded),
                  label: Text(l10n.revengeTake),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: widget.onPassRevenge, child: Text(l10n.passShot)),
            ],
          ),
        ];
    }
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
      ),
    );
  }
}

/// The rumors going round, newest first, and the host's own rumor to spread.
class RumorsCard extends StatelessWidget {
  const RumorsCard({super.key, required this.game, required this.me, required this.onSpread});

  final FamilyGame game;
  final String? me;
  final VoidCallback onSpread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canSpread = me != null && game.canSpreadRumor(me!);
    if (game.rumors.isEmpty && !canSpread) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.rumorsTitle, style: theme.textTheme.titleMedium),
            for (final r in game.rumors.reversed.take(5))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.rumorLine(game.nameOf(r.targetId), game.slip(r.slipId)?.text ?? ''),
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            if (canSpread) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onSpread,
                icon: const Icon(Icons.campaign_rounded),
                label: Text(l10n.rumorSpread),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Picks who and which name for the host's rumor. Pops with the pair, or null.
class RumorDialog extends StatefulWidget {
  const RumorDialog({super.key, required this.game, required this.me});

  final FamilyGame game;
  final String me;

  @override
  State<RumorDialog> createState() => _RumorDialogState();
}

class _RumorDialogState extends State<RumorDialog> {
  String? _target;
  int? _slip;
  final _name = TextEditingController();
  bool _unknown = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _send() {
    final target = _target;
    if (target == null) return;
    final slip = widget.game.handwritten ? _slip : widget.game.slipNamed(_name.text, targetId: target);
    if (slip == null) return setState(() => _unknown = true);
    Navigator.pop(context, (target, slip));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final game = widget.game;
    final slips = [
      for (final s in game.slips)
        if (!game.revealed.contains(s.id)) s,
    ];
    return AlertDialog(
      title: Text(l10n.rumorSpread),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.rumorHint),
            const SizedBox(height: 12),
            FamilyPicker<String>(
              label: l10n.familyWho,
              value: _target,
              items: [for (final p in game.players) (value: p.id, label: p.name)],
              onChanged: (id) => setState(() => _target = id),
            ),
            const SizedBox(height: 10),
            NameEntry(
              game: game,
              controller: _name,
              slips: slips,
              slip: _slip,
              onSlip: (id) => setState(() => _slip = id),
            ),
            if (_unknown) ...[
              const SizedBox(height: 8),
              Text(l10n.familyErrorUnknownName, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _target == null ? null : _send, child: Text(l10n.rumorSend)),
      ],
    );
  }
}

/// The host's own "فكّك مني" card: ready or used.
class LetMeGoChip extends StatelessWidget {
  const LetMeGoChip({super.key, required this.game, required this.me});

  final FamilyGame game;
  final String me;

  @override
  Widget build(BuildContext context) {
    if (!game.twists.letMeGo) return const SizedBox.shrink();
    final l10n = context.l10n;
    final ready = game.hasCard(me);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Chip(
        avatar: Icon(ready ? Icons.back_hand_rounded : Icons.check_rounded, size: 18),
        label: Text(ready ? l10n.letMeGoReady : l10n.letMeGoUsed),
      ),
    );
  }
}
