import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../core/widgets/bowl.dart';
import '../../../../core/l10n/l10n.dart';

/// The moment reading starts: the bowl shakes and blank slips fly out into a
/// deck, then [onDone] hands over to the first name. Tap to skip.
class ShuffleIntro extends StatefulWidget {
  const ShuffleIntro({super.key, required this.count, required this.onDone});

  /// How many names are in the bowl.
  final int count;
  final VoidCallback onDone;

  @override
  State<ShuffleIntro> createState() => _ShuffleIntroState();
}

class _ShuffleIntroState extends State<ShuffleIntro> with SingleTickerProviderStateMixin {
  static const _shake = Interval(0.06, 0.42);
  static const _fadeOut = Interval(0.86, 1);

  /// When the first slip leaves the bowl.
  static const _takeOff = 0.34;

  late final AnimationController _clock = AnimationController(vsync: this, duration: Motion.shuffle);
  bool _buzzed = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _clock
      ..addListener(() {
        if (!_buzzed && _clock.value >= _takeOff) {
          _buzzed = true;
          Haptics.nameIn();
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flying = math.min(widget.count, 7);
    return Scaffold(
      body: Semantics(
        label: context.l10n.shuffling(widget.count),
        button: true,
        hint: context.l10n.tapToSkip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final bowlWidth = math.min(220.0, box.maxWidth * 0.6);
                final bowlHeight = bowlWidth * 132 / 200;
                final mouth = Offset(box.maxWidth / 2, box.maxHeight * 0.62 - bowlHeight * 0.1);
                final deck = Offset(box.maxWidth / 2, box.maxHeight * 0.26);
                return AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) {
                    final t = _clock.value;
                    final shake = _shake.transform(t);
                    final rock = math.sin(shake * math.pi * 6) * 0.1 * (1 - shake);
                    return Opacity(
                      opacity: 1 - _fadeOut.transform(t),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Slips first, so they rise from behind the bowl's rim.
                          for (var i = 0; i < flying; i++) _flyingSlip(i, flying, t, mouth, deck),
                          Positioned(
                            left: mouth.dx - bowlWidth / 2,
                            top: mouth.dy - bowlHeight * 0.35,
                            child: Transform.rotate(
                              angle: rock,
                              alignment: Alignment.bottomCenter,
                              child: Bowl(width: bowlWidth, full: t < _takeOff + 0.12),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 32,
                            child: Text(
                              context.l10n.shuffling(widget.count),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _flyingSlip(int i, int total, double t, Offset from, Offset to) {
    final start = _takeOff + i * 0.05;
    final progress = Curves.easeOutCubic.transform(Interval(start, math.min(start + 0.34, 1)).transform(t));
    if (progress == 0) return const SizedBox.shrink();
    final spread = i - (total - 1) / 2;
    final arc = math.sin(progress * math.pi);
    final position = Offset.lerp(from, to + Offset(0, -i * 3.0), progress)! + Offset(spread * 26 * arc, -70 * arc);
    final angle = spread * 0.5 * (1 - progress) + (i.isEven ? -0.04 : 0.05) * progress;
    return Positioned(
      left: position.dx - 55,
      top: position.dy - 18,
      child: Transform.rotate(angle: angle, child: const _BlankSlip()),
    );
  }
}

/// A slip seen from the back: no text, so nothing leaks before it is read.
class _BlankSlip extends StatelessWidget {
  const _BlankSlip();

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return Container(
      width: 110,
      height: 36,
      decoration: BoxDecoration(
        color: colors.slipPaper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: colors.slipEdge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
      ),
    );
  }
}
