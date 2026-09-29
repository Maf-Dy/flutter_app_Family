import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../features/room/domain/slip_ink.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';

/// The strokes on an [InkPad]. Points are kept in drawing units: the full pad
/// is [SlipInk.maxWidth] x [SlipInk.maxHeight], whatever size it shows at.
class InkController extends ChangeNotifier {
  static const strokeWidth = 12.0;

  final _strokes = <List<Offset>>[];

  List<List<Offset>> get strokes => List.unmodifiable(_strokes);
  bool get isEmpty => _strokes.isEmpty;

  void begin(Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  void extend(Offset point) {
    if (_strokes.isEmpty) return begin(point);
    _strokes.last.add(point);
    notifyListeners();
  }

  void clear() {
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  /// The drawing as a PNG, cropped to the ink, or null when nothing is drawn.
  Future<SlipInk?> toInk() async {
    if (_strokes.isEmpty) return null;
    final full = Rect.fromLTWH(0, 0, SlipInk.maxWidth.toDouble(), SlipInk.maxHeight.toDouble());
    var bounds = Rect.fromPoints(_strokes.first.first, _strokes.first.first);
    for (final stroke in _strokes) {
      for (final p in stroke) {
        bounds = bounds.expandToInclude(Rect.fromPoints(p, p));
      }
    }
    bounds = bounds.inflate(strokeWidth).intersect(full);
    final left = bounds.left.floorToDouble();
    final top = bounds.top.floorToDouble();
    final width = math.max(1, (bounds.right - left).ceil()).clamp(1, SlipInk.maxWidth);
    final height = math.max(1, (bounds.bottom - top).ceil()).clamp(1, SlipInk.maxHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..translate(-left, -top);
    paintStrokes(canvas, _strokes, scale: 1, color: Colors.black);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes == null ? null : SlipInk.tryParse(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  /// Draws [strokes] as thick, round ink, [scale] times the drawing units.
  static void paintStrokes(Canvas canvas, List<List<Offset>> strokes, {required double scale, required Color color}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first * scale, strokeWidth * scale / 2, Paint()..color = color);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx * scale, stroke.first.dy * scale);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }
}

/// A paper slip to write a name on with a finger, with a Clear button.
///
/// When [hidden], the ink is covered so the table can't read it; tapping the
/// cover calls [onReveal].
class InkPad extends StatelessWidget {
  const InkPad({
    super.key,
    required this.controller,
    this.label,
    this.hidden = false,
    this.onReveal,
    this.onStrokeStart,
  });

  final InkController controller;

  /// A short title in the slip's corner, e.g. "Name 2".
  final String? label;
  final bool hidden;
  final VoidCallback? onReveal;

  /// Called as a stroke starts, e.g. to hide the other pads.
  final VoidCallback? onStrokeStart;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final l10n = context.l10n;
    final hand = TextStyle(fontFamily: AppFonts.hand, fontFamilyFallback: AppFonts.arabicHand, color: game.slipInk);
    return AspectRatio(
      aspectRatio: SlipInk.maxWidth / SlipInk.maxHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: game.slipPaper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hidden ? game.slipEdge : game.slipInk, width: hidden ? 1.5 : 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final scale = constraints.maxWidth / SlipInk.maxWidth;
                Offset toInk(Offset local) => Offset(
                  (local.dx / scale).clamp(0, SlipInk.maxWidth.toDouble()),
                  (local.dy / scale).clamp(0, SlipInk.maxHeight.toDouble()),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (controller.isEmpty && !hidden)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.inkHint,
                            textAlign: TextAlign.center,
                            style: hand.copyWith(fontSize: 17, color: game.slipInk.withValues(alpha: 0.45)),
                          ),
                        ),
                      ),
                    Semantics(
                      label: label == null ? l10n.inkHint : '$label. ${l10n.inkHint}',
                      child: RawGestureDetector(
                        behavior: HitTestBehavior.opaque,
                        gestures: {
                          _InkGestureRecognizer: GestureRecognizerFactoryWithHandlers<_InkGestureRecognizer>(
                            _InkGestureRecognizer.new,
                            (r) => r
                              ..dragStartBehavior = DragStartBehavior.down
                              ..onStart = (d) {
                                if (hidden) return;
                                onStrokeStart?.call();
                                controller.begin(toInk(d.localPosition));
                              }
                              ..onUpdate = (d) {
                                if (!hidden) controller.extend(toInk(d.localPosition));
                              },
                          ),
                        },
                        child: CustomPaint(
                          painter: _InkPainter(hidden ? const [] : controller.strokes, scale, game.slipInk),
                        ),
                      ),
                    ),
                    if (label != null)
                      PositionedDirectional(
                        top: 6,
                        start: 10,
                        child: IgnorePointer(
                          child: Text(
                            label!,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: game.slipInk),
                          ),
                        ),
                      ),
                    if (!controller.isEmpty && !hidden)
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        child: TextButton.icon(
                          onPressed: controller.clear,
                          style: TextButton.styleFrom(foregroundColor: game.slipInk),
                          icon: const Icon(Icons.backspace_rounded, size: 18),
                          label: Text(l10n.inkClear),
                        ),
                      ),
                    if (hidden)
                      Material(
                        color: game.slipPaper,
                        child: InkWell(
                          onTap: onReveal,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.isEmpty ? Icons.edit_rounded : Icons.visibility_off_rounded,
                                  color: game.slipInk.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.isEmpty ? l10n.inkHint : l10n.inkHidden,
                                  textAlign: TextAlign.center,
                                  style: hand.copyWith(fontSize: 16, color: game.slipInk.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Wins every drag that starts on the pad, so writing never scrolls the page instead.
class _InkGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolvePointer(event.pointer, GestureDisposition.accepted);
  }
}

class _InkPainter extends CustomPainter {
  const _InkPainter(this.strokes, this.scale, this.color);

  final List<List<Offset>> strokes;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => InkController.paintStrokes(canvas, strokes, scale: scale, color: color);

  // The strokes list is a fresh copy on every change.
  @override
  bool shouldRepaint(_InkPainter old) => old.strokes != strokes || old.scale != scale || old.color != color;
}
