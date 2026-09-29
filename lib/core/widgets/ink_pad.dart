import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../features/room/domain/slip_ink.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';

/// The strokes on an [InkPad]. Points are kept in drawing units: the pad is
/// always [SlipInk.maxWidth] units wide, and as many units tall as its shape
/// gives, whatever size it shows at. [toInk] shrinks the drawing to fit a slip.
class InkController extends ChangeNotifier {
  static const strokeWidth = 12.0;

  /// How far, in drawing units, a finger has to move before it counts as a
  /// stroke. Less than that is a tap: a dot on a slip that already has ink
  /// (the dots of letters), nothing on an empty one.
  static const minMove = 8.0;

  final _strokes = <List<Offset>>[];

  /// Where the finger went down, until it has moved far enough to draw.
  Offset? _pending;

  /// Whether the finger that is down has started a stroke.
  bool _drawing = false;

  List<List<Offset>> get strokes => List.unmodifiable(_strokes);
  bool get isEmpty => _strokes.isEmpty;

  /// Starts a stroke at [point] straight away.
  void begin(Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  void extend(Offset point) {
    if (_strokes.isEmpty) return begin(point);
    _strokes.last.add(point);
    notifyListeners();
  }

  /// A finger went down at [point]; nothing is drawn until it moves ([move]).
  void down(Offset point) {
    _pending = point;
    _drawing = false;
  }

  void move(Offset point) {
    final start = _pending;
    if (start != null) {
      if ((point - start).distance < minMove) return;
      _pending = null;
      _drawing = true;
      _strokes.add([start, point]);
      notifyListeners();
      return;
    }
    if (_drawing) extend(point);
  }

  /// The finger lifted. A tap with no movement is a dot, but only next to other ink.
  void up() {
    final start = _pending;
    _pending = null;
    _drawing = false;
    if (start != null && _strokes.isNotEmpty) begin(start);
  }

  void cancel() {
    _pending = null;
    _drawing = false;
  }

  /// Takes back the last stroke.
  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    cancel();
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  /// The drawing as a PNG, cropped to the ink and shrunk to fit a slip, or null when nothing is drawn.
  Future<SlipInk?> toInk() async {
    if (_strokes.isEmpty) return null;
    var bounds = Rect.fromPoints(_strokes.first.first, _strokes.first.first);
    for (final stroke in _strokes) {
      for (final p in stroke) {
        bounds = bounds.expandToInclude(Rect.fromPoints(p, p));
      }
    }
    bounds = bounds.inflate(strokeWidth);
    final left = math.max(0.0, bounds.left).floorToDouble();
    final top = math.max(0.0, bounds.top).floorToDouble();
    final inkWidth = math.max(1.0, bounds.right - left);
    final inkHeight = math.max(1.0, bounds.bottom - top);
    final factor = math.min(1.0, math.min(SlipInk.maxWidth / inkWidth, SlipInk.maxHeight / inkHeight));
    final width = (inkWidth * factor).ceil().clamp(1, SlipInk.maxWidth);
    final height = (inkHeight * factor).ceil().clamp(1, SlipInk.maxHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(factor)
      ..translate(-left, -top);
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

/// A big paper slip to write a name on with a finger, with Undo and Clear under it.
///
/// When [hidden], the ink is covered so the table can't read it, and nothing
/// can be drawn; only the cover's button calls [onReveal], so opening the pad
/// never leaves a mark on it.
class InkPad extends StatelessWidget {
  const InkPad({
    super.key,
    required this.controller,
    this.label,
    this.hidden = false,
    this.onReveal,
    this.onStrokeStart,
  });

  /// The pad is full width and about half as tall, never shorter than this on a phone.
  static const minHeight = 200.0;
  static const maxHeight = 320.0;

  final InkController controller;

  /// A short title in the slip's corner, e.g. "Name 2".
  final String? label;
  final bool hidden;
  final VoidCallback? onReveal;

  /// Called as a finger goes down to write, e.g. to hide the other pads.
  final VoidCallback? onStrokeStart;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final l10n = context.l10n;
    final hand = TextStyle(fontFamily: AppFonts.hand, fontFamilyFallback: AppFonts.arabicHand, color: game.slipInk);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = (width / 2).clamp(minHeight, maxHeight);
              final scale = width / SlipInk.maxWidth;
              Offset toInk(Offset local) => Offset(
                (local.dx / scale).clamp(0, SlipInk.maxWidth.toDouble()),
                (local.dy / scale).clamp(0, height / scale),
              );
              return SizedBox(
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: game.slipPaper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hidden ? game.slipEdge : game.slipInk, width: hidden ? 1.5 : 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (controller.isEmpty && !hidden)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                l10n.inkHint,
                                textAlign: TextAlign.center,
                                style: hand.copyWith(fontSize: 18, color: game.slipInk.withValues(alpha: 0.45)),
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
                                    controller.down(toInk(d.localPosition));
                                  }
                                  ..onUpdate = (d) {
                                    if (!hidden) controller.move(toInk(d.localPosition));
                                  }
                                  ..onEnd = ((_) => controller.up())
                                  ..onCancel = controller.cancel,
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
                        if (hidden) _Cover(hasInk: !controller.isEmpty, onReveal: onReveal, hand: hand),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: controller.isEmpty || hidden ? null : controller.undo,
                icon: const Icon(Icons.undo_rounded, size: 20),
                label: Text(l10n.inkUndo),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: controller.isEmpty || hidden ? null : controller.clear,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: Text(l10n.inkClear),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Covers a hidden pad. It swallows every touch, so only its button opens the pad.
class _Cover extends StatelessWidget {
  const _Cover({required this.hasInk, required this.onReveal, required this.hand});

  final bool hasInk;
  final VoidCallback? onReveal;
  final TextStyle hand;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final l10n = context.l10n;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: game.slipPaper,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasInk) ...[
                  Icon(Icons.visibility_off_rounded, color: game.slipInk.withValues(alpha: 0.6)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.inkHidden,
                    textAlign: TextAlign.center,
                    style: hand.copyWith(fontSize: 16, color: game.slipInk.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton.tonalIcon(
                  onPressed: onReveal,
                  icon: Icon(hasInk ? Icons.visibility_rounded : Icons.edit_rounded),
                  label: Text(hasInk ? l10n.show : l10n.inkReveal),
                ),
              ],
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
