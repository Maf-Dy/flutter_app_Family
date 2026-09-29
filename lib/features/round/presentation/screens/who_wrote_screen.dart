import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/theme/game_colors.dart';
import '../state/round_cubit.dart';
import '../widgets/confetti.dart';
import '../widgets/paper_slip.dart';
import '../widgets/reveal_card.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/game_exit.dart';
import '../../../../core/widgets/share_card.dart';
import '../../../room/domain/room.dart';
import '../../../room/presentation/category_label.dart';

/// Optional, after the game: each slip turns over to show who wrote it.
class WhoWroteScreen extends StatefulWidget {
  const WhoWroteScreen({super.key, required this.players, required this.category});

  /// Player ids in join order, for colours.
  final List<String> players;
  final GameCategory category;

  @override
  State<WhoWroteScreen> createState() => _WhoWroteScreenState();
}

class _WhoWroteScreenState extends State<WhoWroteScreen> {
  Timer? _revealing;

  @override
  void dispose() {
    _revealing?.cancel();
    super.dispose();
  }

  void _reveal(int index) {
    final cubit = context.read<RoundCubit>();
    if (cubit.state.revealed.contains(index)) return;
    Haptics.tick();
    cubit.reveal(index);
  }

  void _share(RoundState state) {
    const shown = 8;
    final l10n = context.l10n;
    showShareCard(
      context,
      ShareCard(
        title: l10n.whoWroteWhat,
        subtitle: categoryLabel(l10n, widget.category),
        rows: [
          for (final slip in state.slips.take(shown))
            (
              label: slip.text,
              value: slip.writerName,
              color: context.gameColors.player(widget.players.indexOf(slip.writerId)),
            ),
        ],
        more: state.slips.length - shown,
      ),
    );
  }

  /// One slip at a time, so the table gets its "ahh, it was you!" moments.
  void _revealAll() {
    final cubit = context.read<RoundCubit>();
    if (Motion.isReduced(context)) {
      for (var i = 0; i < cubit.state.slips.length; i++) {
        cubit.reveal(i);
      }
      return;
    }
    _revealing?.cancel();
    void step() {
      final hidden = [
        for (var i = 0; i < cubit.state.slips.length; i++)
          if (!cubit.state.revealed.contains(i)) i,
      ];
      if (hidden.isEmpty || !mounted) return _revealing?.cancel();
      _reveal(hidden.first);
    }

    step();
    _revealing = Timer.periodic(Motion.revealGap, (_) => step());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoundCubit>().state;
    final theme = Theme.of(context);
    final game = context.gameColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.whoWroteWhat),
        actions: [
          if (state.allRevealed)
            IconButton(
              tooltip: context.l10n.shareThisNight,
              onPressed: () => _share(state),
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.standard),
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
                    child: Text(
                      state.allRevealed ? context.l10n.thatsAll : context.l10n.whoWroteHint,
                      key: ValueKey(state.allRevealed),
                      style: state.allRevealed
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: state.slips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final slip = state.slips[i];
                      final revealed = state.revealed.contains(i);
                      final color = game.player(widget.players.indexOf(slip.writerId));
                      final name = slip.ink == null ? slip.text : context.l10n.handwrittenName;
                      return Semantics(
                        button: !revealed,
                        label: revealed
                            ? context.l10n.writtenBy(name, slip.writerName)
                            : context.l10n.tapToReveal(name),
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: revealed ? null : () => _reveal(i),
                          child: Row(
                            children: [
                              Expanded(
                                child: PaperSlip(text: slip.text, ink: slip.ink, tiltDegrees: slipTilt(i) / 2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RevealCard(
                                  revealed: revealed,
                                  front: _Face(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Text(
                                      '?',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  // The writer's colour fills the card.
                                  back: _Face(
                                    color: color,
                                    child: Text(
                                      slip.writerName,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: game.onPlayer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: state.allRevealed
                      ? FilledButton(
                          onPressed: () => Navigator.of(context).pop(GameExit.newRound),
                          child: Text(context.l10n.newRoundSameRoom),
                        )
                      : FilledButton(onPressed: _revealAll, child: Text(context.l10n.revealAll)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(GameExit.endGame),
                    child: Text(context.l10n.endGame),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(child: ConfettiBurst(fire: state.allRevealed)),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
