import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A button that only fires after being held down for [holdFor], so a stray
/// tap can't start the game. The bar fills while it is held and drains when
/// let go early. Screen readers get it as a long-press action.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onHeld,
    required this.color,
    this.holdFor = const Duration(seconds: 2),
  });

  final String label;

  /// Read out by screen readers, e.g. "Press and hold".
  final String hint;
  final VoidCallback onHeld;

  /// Text, outline and fill colour.
  final Color color;
  final Duration holdFor;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: widget.holdFor)
    ..addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _progress.value = 0;
      widget.onHeld();
    });

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Offset _downAt = Offset.zero;

  void _press() => _progress.forward();

  void _release() {
    if (_progress.isAnimating && _progress.status == AnimationStatus.forward) {
      _progress.animateBack(0, duration: const Duration(milliseconds: 250));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: widget.color.withValues(alpha: 0.8), width: 1.5),
    );
    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      onLongPress: widget.onHeld,
      excludeSemantics: true,
      // Raw pointer events: a tap recogniser inside a scrolling page waits for
      // the scroll to lose before it reports the press, and would never fill.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _downAt = event.position;
          _press();
        },
        onPointerMove: (event) {
          // Scrolling the page is not holding the button.
          if ((event.position - _downAt).distance > kTouchSlop) _release();
        },
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 220),
          child: DecoratedBox(
            decoration: ShapeDecoration(shape: shape),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: _progress.value,
                        child: ColoredBox(color: widget.color.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, color: widget.color, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(color: widget.color, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
