import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';

/// The "who wrote it" card. When [revealed] turns true it builds suspense
/// (a small shrink and wobble), flips over, and lands with a pop.
class RevealCard extends StatefulWidget {
  const RevealCard({super.key, required this.revealed, required this.front, required this.back});

  final bool revealed;
  final Widget front;
  final Widget back;

  @override
  State<RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<RevealCard> with SingleTickerProviderStateMixin {
  static const _suspense = Interval(0, 0.3);
  static const _turn = Interval(0.3, 0.75, curve: Curves.easeInOutCubic);
  static const _land = Interval(0.75, 1);

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Motion.reveal,
    value: widget.revealed ? 1 : 0,
  );

  @override
  void didUpdateWidget(RevealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed == oldWidget.revealed) return;
    if (!widget.revealed) {
      _clock.value = 0;
    } else if (Motion.isReduced(context)) {
      _clock.value = 1;
    } else {
      _clock.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final t = _clock.value;
        final suspense = _suspense.transform(t);
        final turn = _turn.transform(t);
        final land = _land.transform(t);
        final scale = 1 - 0.06 * math.sin(suspense * math.pi) + 0.08 * math.sin(land * math.pi);
        final wobble = math.sin(suspense * math.pi * 4) * 0.035 * (1 - suspense);
        final showBack = turn >= 0.5;
        return Transform.rotate(
          angle: wobble,
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(turn * math.pi + (showBack ? math.pi : 0)),
              child: showBack ? widget.back : widget.front,
            ),
          ),
        );
      },
    );
  }
}
