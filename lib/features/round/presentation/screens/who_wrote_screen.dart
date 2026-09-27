import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../round_route.dart';
import '../state/round_cubit.dart';
import '../widgets/flip.dart';
import '../widgets/paper_slip.dart';

/// Optional, after the game: each slip turns over to show who wrote it.
class WhoWroteScreen extends StatefulWidget {
  const WhoWroteScreen({super.key, required this.players});

  /// Player ids in join order, for avatar colours.
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
      final next = [
        for (var i = 0; i < cubit.state.slips.length; i++) i,
      ].where((i) => !cubit.state.revealed.contains(i));
      if (next.isEmpty || !mounted) return _revealing?.cancel();
      _reveal(next.first);
    }

    step();
    _revealing = Timer.periodic(Motion.revealGap, (_) => step());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoundCubit>().state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Who wrote what?')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Tap a name, or reveal them all.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                            child: FlipCard(
                              showBack: revealed,
                              front: _Face(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Text(
                                  '?',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              back: _Face(
                                color: theme.colorScheme.surfaceContainerLowest,
                                outline: theme.colorScheme.outlineVariant,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PlayerAvatar(
                                      name: slip.writerName,
                                      joinIndex: widget.players.indexOf(slip.writerId),
                                      size: 26,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        slip.writerName,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
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
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.color, required this.child, this.outline});

  final Color color;
  final Color? outline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: outline == null ? null : Border.all(color: outline!),
      ),
      child: child,
    );
  }
}
