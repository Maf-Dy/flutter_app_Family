import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps what [child] shows out of screenshots, screen recordings and the
/// recent-apps preview while it is on screen. Android only; elsewhere it does nothing.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  static const _channel = MethodChannel('family_game/secure_screen');

  /// Screens sliding in and out overlap, so the shield stays up while any of them is mounted.
  static int _mounted = 0;

  static Future<void> _set(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on MissingPluginException {
      // iOS, tests: no platform side.
    } on PlatformException {
      // Better to play without the shield than to stop the game.
    }
  }

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    if (SecureScreen._mounted++ == 0) unawaited(SecureScreen._set(true));
  }

  @override
  void dispose() {
    if (--SecureScreen._mounted == 0) unawaited(SecureScreen._set(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
