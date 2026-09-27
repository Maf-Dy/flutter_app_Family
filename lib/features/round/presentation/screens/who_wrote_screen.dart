import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/theme/game_colors.dart';
import '../../round_route.dart';
import '../state/round_cubit.dart';
import '../widgets/confetti.dart';
import '../widgets/paper_slip.dart';
import '../widgets/reveal_card.dart';

/// Optional, after the game: each slip turns over to show who wrote it.
class WhoWroteScreen extends StatefulWidget {
  const WhoWroteScreen({super.key, required this.players});

  /// Player ids in join order, for colours.
  final List<String> players;

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
      appBar: AppBar(title: const Text('Who wrote what?')),
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
                      state.allRevealed ? 'That\'s all of them!' : 'Tap a name, or reveal them all.',
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
                      return Semantics(
                        button: !revealed,
                        label: revealed
                            ? '${slip.text}, written by ${slip.writerName}'
                            : '${slip.text}. Tap to reveal who wrote it',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: revealed ? null : () => _reveal(i),
                          child: Row(
                            children: [
                              Expanded(
                                child: PaperSlip(text: slip.text, tiltDegrees: slipTilt(i) / 2),
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
                          onPressed: () => Navigator.of(context).pop(RoundExit.newRound),
                          child: const Text('New round, same room'),
                        )
                      : FilledButton(onPressed: _revealAll, child: const Text('Reveal all')),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(RoundExit.endGame),
                    child: const Text('End game'),
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
