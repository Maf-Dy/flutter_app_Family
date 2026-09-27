import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/game_colors.dart';

/// The home-screen bowl with slips bobbing gently inside it.
class Bowl extends StatefulWidget {
  const Bowl({super.key, this.width = 200});

  final double width;

  @override
  State<Bowl> createState() => _BowlState();
}

class _BowlState extends State<Bowl> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: Motion.bob);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.isReduced(context)) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(widget.width, widget.width * 132 / 200),
        painter: _BowlPainter(
          bob: _bob,
          bowl: Theme.of(context).colorScheme.primary,
          shine: Theme.of(context).colorScheme.onPrimary,
          colors: context.gameColors,
        ),
      ),
    );
  }
}

class _BowlPainter extends CustomPainter {
  _BowlPainter({required this.bob, required this.bowl, required this.shine, required this.colors})
    : super(repaint: bob);

  final Animation<double> bob;
  final Color bowl;
  final Color shine;
  final GameColors colors;

  // x, y, width, height, tilt in degrees, bob phase. In a 200×132 box.
  static const _slips = [
    (52.0, 22.0, 44.0, 26.0, -18.0, 0.0),
    (86.0, 8.0, 44.0, 26.0, 8.0, 0.33),
    (112.0, 26.0, 44.0, 26.0, 22.0, 0.66),
    (74.0, 34.0, 44.0, 26.0, -4.0, 0.15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);
    final paper = Paint()..color = colors.slipPaper;
    final edge = Paint()
      ..color = colors.slipEdge
      ..style = PaintingStyle.stroke;
    for (final (x, y, w, h, tilt, phase) in _slips) {
      final lift = -5 * math.sin(2 * math.pi * (bob.value + phase)).abs();
      canvas
        ..save()
        ..translate(x + w / 2, y + h / 2 + lift)
        ..rotate(tilt * math.pi / 180);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(2),
      );
      canvas
        ..drawRRect(rect, paper)
        ..drawRRect(rect, edge)
        ..restore();
    }
    final body = Path()
      ..moveTo(14, 58)
      ..lineTo(186, 58)
      ..cubicTo(186, 96, 148, 126, 100, 126)
      ..cubicTo(52, 126, 14, 96, 14, 58)
      ..close();
    final fill = Paint()..color = bowl;
    canvas
      ..drawPath(body, fill)
      ..drawOval(Rect.fromCenter(center: const Offset(100, 58), width: 172, height: 18), fill)
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 58), width: 160, height: 11),
        Paint()..color = shine.withValues(alpha: 0.18),
      )
      ..drawPath(
        Path()
          ..moveTo(40, 80)
          ..cubicTo(50, 98, 70, 110, 92, 112),
        Paint()
          ..color = shine.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_BowlPainter old) => old.bowl != bowl || old.colors != colors || old.shine != shine;
}

/// Small bowl next to the lobby count. A slip drops into it each time [count] grows.
class BowlCount extends StatefulWidget {
  const BowlCount({super.key, required this.count});

  final int count;

  @override
  State<BowlCount> createState() => _BowlCountState();
}

class _BowlCountState extends State<BowlCount> with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(vsync: this, duration: Motion.drop);

  @override
  void didUpdateWidget(BowlCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count && !Motion.isReduced(context)) _drop.forward(from: 0);
  }

  @override
  void dispose() {
    _drop.dispose();
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
    );
  }
}
