import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';

/// Turns [child] over on the Y axis when it first appears. Give it a new key to
/// flip again (the read-aloud slip does, once per name).
class FlipIn extends StatelessWidget {
  const FlipIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: Motion.of(context, Motion.flip),
      curve: Motion.emphasized,
      builder: (context, turn, child) => Opacity(
        opacity: 1 - turn * 0.8,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(turn * math.pi / 2),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A two-sided card that turns from [front] to [back] when [showBack] becomes true.
class FlipCard extends StatelessWidget {
  const FlipCard({super.key, required this.showBack, required this.front, required this.back});

  final bool showBack;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: showBack ? 1 : 0),
      duration: Motion.of(context, Motion.settle),
      curve: Motion.emphasized,
      builder: (context, turn, _) {
        final backVisible = turn >= 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(turn * math.pi + (backVisible ? math.pi : 0)),
          child: backVisible ? back : front,
        );
      },
    );
  }
}
