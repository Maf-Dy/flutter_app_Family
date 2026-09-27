import 'package:flutter/material.dart';

import 'motion.dart';

/// Material shared-axis X: the new page slides in from the end while fading in,
/// the old one slides toward the start while fading out. Reversed on back.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.isReduced(context)) return child;
    return _SharedAxis(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
  }
}

class _SharedAxis extends StatelessWidget {
  const _SharedAxis({required this.animation, required this.secondaryAnimation, required this.child});

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, child) {
        final entering = Motion.emphasized.transform(animation.value);
        final leaving = Motion.emphasized.transform(secondaryAnimation.value);
        final dx = ((1 - entering) - leaving) * Motion.axisShift * direction;
        return Opacity(
          opacity: (entering * (1 - leaving)).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
      child: child,
    );
  }
}

/// Shared-axis switch between stages of one screen (for example "read aloud"
/// to "names on the table"). Moving to a higher [position] slides forward,
/// a lower one slides back. [child] must carry a key that changes per stage.
class StageSwitcher extends StatefulWidget {
  const StageSwitcher({super.key, required this.position, required this.child});

  final int position;
  final Widget child;

  @override
  State<StageSwitcher> createState() => _StageSwitcherState();
}

class _StageSwitcherState extends State<StageSwitcher> {
  bool _forward = true;

  @override
  void didUpdateWidget(StageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) _forward = widget.position > oldWidget.position;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final direction = (_forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
    final current = widget.child;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.page),
      switchInCurve: Motion.emphasized,
      switchOutCurve: Motion.emphasized.flipped,
      layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (stage, animation) {
        final incoming = stage.key == current.key;
        final shift = (incoming ? direction : -direction) * Motion.axisShift;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, stage) => Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset((1 - animation.value) * shift, 0), child: stage),
          ),
          child: stage,
        );
      },
      child: current,
    );
  }
}
