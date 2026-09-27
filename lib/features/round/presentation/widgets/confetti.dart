import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/game_colors.dart';

/// A one-shot burst of paper confetti, fired each time [fire] turns true.
/// Draws nothing with reduced motion, and never takes taps.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.fire});

  final bool fire;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: Motion.confetti);
  List<_Piece> _pieces = const [];

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fire && !oldWidget.fire && !Motion.isReduced(context)) {
      final random = math.Random();
      final colors = [...context.gameColors.players, context.gameColors.slipPaper];
      _pieces = [
        for (var i = 0; i < 90; i++)
          _Piece(
            x: 0.2 + random.nextDouble() * 0.6,
            vx: (random.nextDouble() - 0.5) * 1.1,
            vy: -(0.55 + random.nextDouble() * 0.6),
            spin: (random.nextDouble() - 0.5) * 16,
            width: 6 + random.nextDouble() * 6,
            color: colors[random.nextInt(colors.length)],
          ),
      ];
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
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(clock: _clock, pieces: _pieces),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.width,
    required this.color,
  });

  /// Start position as a fraction of the width; velocities in screen heights per second.
  final double x;
  final double vx;
  final double vy;
  final double spin;
  final double width;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.clock, required this.pieces}) : super(repaint: clock);

  final Animation<double> clock;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    if (clock.value == 0 || clock.isCompleted) return;
    final seconds = clock.value * Motion.confetti.inMilliseconds / 1000;
    const gravity = 1.4;
    final fade = (1 - clock.value) * 3;
    final paint = Paint();
    for (final piece in pieces) {
      final x = (piece.x + piece.vx * seconds * 0.5) * size.width;
      // Launched up from the lower middle of the screen, then falling back down.
      final y = size.height * (0.75 + piece.vy * seconds + 0.5 * gravity * seconds * seconds);
      paint.color = piece.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.spin * seconds)
        ..drawRect(Rect.fromCenter(center: Offset.zero, width: piece.width, height: piece.width * 0.6), paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.pieces != pieces;
}
