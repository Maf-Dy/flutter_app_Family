import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/game_colors.dart';

/// Small bowl next to the lobby count. A slip drops into it each time [count]
/// grows, and it wobbles once when the room becomes [ready] to start.
class BowlCount extends StatefulWidget {
  const BowlCount({super.key, required this.count, required this.ready});

  final int count;
  final bool ready;

  @override
  State<BowlCount> createState() => _BowlCountState();
}

class _BowlCountState extends State<BowlCount> with TickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(vsync: this, duration: Motion.drop);
  late final AnimationController _wobble = AnimationController(vsync: this, duration: Motion.wobble);

  @override
  void didUpdateWidget(BowlCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Motion.isReduced(context)) return;
    if (widget.count > oldWidget.count) _drop.forward(from: 0);
    if (widget.ready && !oldWidget.ready) _wobble.forward(from: 0);
  }

  @override
  void dispose() {
    _drop.dispose();
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.gameColors;
    Widget slip(double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 22,
        height: 14,
        decoration: BoxDecoration(
          color: colors.slipPaper,
          border: Border.all(color: colors.slipEdge),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (context, child) {
          final t = _wobble.value;
          // A decaying side-to-side rock, like a bowl set down on the table.
          final angle = math.sin(t * math.pi * 5) * 0.14 * (1 - t);
          return Transform.rotate(angle: angle, alignment: Alignment.bottomCenter, child: child);
        },
        child: SizedBox(
          width: 74,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: 18, top: 4, child: slip(-0.24)),
              Positioned(left: 34, top: 2, child: slip(0.2)),
              AnimatedBuilder(
                animation: _drop,
                builder: (context, child) {
                  final t = Motion.emphasized.transform(_drop.value);
                  if (_drop.value == 0 || _drop.isCompleted) return const SizedBox.shrink();
                  return Positioned(
                    left: 26,
                    top: -44 + 58 * t,
                    child: Opacity(opacity: t < 0.8 ? 1 : ((1 - t) / 0.2).clamp(0.0, 1.0), child: slip(-0.5 + 0.7 * t)),
                  );
                },
              ),
              Positioned(
                left: 4,
                right: 4,
                top: 18,
                bottom: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(40)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
