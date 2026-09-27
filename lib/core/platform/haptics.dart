import 'package:flutter/services.dart';

/// Named haptic moments, so every screen buzzes the same way for the same event.
abstract final class Haptics {
  /// A friend's name landed in the bowl.
  static Future<void> nameIn() => HapticFeedback.lightImpact();

  /// Reading starts.
  static Future<void> start() => HapticFeedback.mediumImpact();

  /// A slip turned over: next name, or a reveal.
  static Future<void> tick() => HapticFeedback.selectionClick();

  /// A team guessed a name.
  static Future<void> point() => HapticFeedback.lightImpact();

  /// The last seconds of a turn.
  static Future<void> countdown() => HapticFeedback.selectionClick();

  /// The family game came round to the host's family.
  static Future<void> yourTurn() => HapticFeedback.mediumImpact();

  /// The turn's clock ran out.
  static Future<void> timeUp() => HapticFeedback.heavyImpact();
}
