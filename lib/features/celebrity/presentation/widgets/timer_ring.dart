import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';

/// The turn clock: a ring that empties, turning red for the last seconds.
class TimerRing extends StatelessWidget {
  const TimerRing({super.key, required this.secondsLeft, required this.total, this.size = 84});

  final int secondsLeft;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = secondsLeft <= 5;
    final color = urgent ? scheme.error : scheme.primary;
    return Semantics(
      label: context.l10n.secondsLeft(secondsLeft),
      liveRegion: urgent,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: total == 0 ? 0 : secondsLeft / total),
        duration: Motion.of(context, const Duration(milliseconds: 900)),
        builder: (context, fraction, _) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(fraction: fraction, color: color, track: scheme.surfaceContainerHighest),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Text(
                '$secondsLeft',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.color, required this.track});

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.09;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(stroke / 2), 0, math.pi * 2, false, paint..color = track);
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2 * fraction, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.track != track;
}
