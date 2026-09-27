import 'package:flutter/material.dart';

/// The app's motion vocabulary. Every animation reads its timing from here and
/// checks [isReduced] so the system "remove animations" setting is respected.
abstract final class Motion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 300);
  static const page = Duration(milliseconds: 360);
  static const settle = Duration(milliseconds: 500);
  static const flip = Duration(milliseconds: 550);
  static const drop = Duration(milliseconds: 750);
  static const revealGap = Duration(milliseconds: 650);
  static const reveal = Duration(milliseconds: 900);
  static const wobble = Duration(milliseconds: 900);
  static const shuffle = Duration(milliseconds: 1700);
  static const confetti = Duration(milliseconds: 2600);

  /// How long a "Lina's name is in" banner stays up, including its slide in and out.
  static const banner = Duration(milliseconds: 2200);
  static const bob = Duration(milliseconds: 3200);

  static const Curve emphasized = Easing.emphasizedDecelerate;
  static const Curve spring = Curves.easeOutBack;

  /// Horizontal travel of a shared-axis transition, in logical pixels.
  static const axisShift = 28.0;

  static bool isReduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when the user asked for reduced motion.
  static Duration of(BuildContext context, Duration duration) => isReduced(context) ? Duration.zero : duration;
}
