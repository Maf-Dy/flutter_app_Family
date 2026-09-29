import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../room/domain/slip_ink.dart';

export '../../../room/domain/slip_ink.dart' show SlipInk;

/// A slip's name wherever it shows: the typed [text], or the drawing itself
/// when the name was written by hand ([ink]), tinted with the text colour.
class SlipLabel extends StatelessWidget {
  const SlipLabel({
    super.key,
    required this.text,
    this.ink,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.inkHeight,
  });

  final String text;
  final SlipInk? ink;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// How tall the drawing shows; about two lines of [style] by default.
  final double? inkHeight;

  @override
  Widget build(BuildContext context) {
    final ink = this.ink;
    if (ink == null) return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final height = inkHeight ?? (resolved.fontSize ?? 14) * 2.2;
    return Semantics(
      container: true,
      label: Localizations.of<AppLocalizations>(context, AppLocalizations)?.handwrittenName ?? text,
      image: true,
      child: Image.memory(
        ink.png,
        height: height,
        fit: BoxFit.contain,
        color: resolved.color,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// A handwritten paper slip, like the ones that go in the bowl.
class PaperSlip extends StatelessWidget {
  const PaperSlip({super.key, required this.text, this.ink, this.tiltDegrees = 0, this.large = false});

  final String text;

  /// The name as written by hand; shown instead of [text] when set.
  final SlipInk? ink;
  final double tiltDegrees;

  /// The big single slip on the read-aloud screen, with a strip of tape.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final slip = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.slipPaper,
        borderRadius: BorderRadius.circular(large ? 4 : 3),
        boxShadow: [
          BoxShadow(color: colors.slipEdge, offset: const Offset(0, 1)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: Offset(0, large ? 14 : 6),
            blurRadius: large ? 30 : 14,
            spreadRadius: large ? -12 : -8,
          ),
        ],
      ),
      child: Padding(
        padding: large
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 34)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: SlipLabel(
          text: text,
          ink: ink,
          inkHeight: large ? 120 : 44,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.hand,
            fontFamilyFallback: AppFonts.arabicHand,
            fontWeight: FontWeight.w700,
            color: colors.slipInk,
            fontSize: large ? 34 : 17,
            height: 1.12,
          ),
        ),
      ),
    );
    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      child: large
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                slip,
                Positioned(
                  top: -9,
                  child: Transform.rotate(
                    angle: 0.05,
                    child: Container(width: 64, height: 18, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            )
          : slip,
    );
  }
}

/// Slight, repeatable tilts so the slips look hand-placed.
double slipTilt(int index) => const [-3.0, 2.0, -1.5, 3.0, -2.0, 1.5, -1.0, 2.5][index % 8];
