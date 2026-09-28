import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n.dart';

/// Keeps the app running while [child] is on screen or underneath a game, so
/// friends' phones don't lose the room when the host takes a call, locks the
/// phone or switches app. Android shows a "Hosting a game" notification for it.
/// Elsewhere it does nothing.
class KeepHosting extends StatefulWidget {
  const KeepHosting({super.key, required this.child});

  final Widget child;

  static const _channel = MethodChannel('family_game/hosting');

  static Future<void> _call(String method, [Map<String, String>? arguments]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Tests: no platform side.
    } on PlatformException catch (error) {
      // Hosting still works while the app stays open.
      debugPrint('KeepHosting: $error');
    }
  }

  @override
  State<KeepHosting> createState() => _KeepHostingState();
}

class _KeepHostingState extends State<KeepHosting> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final l10n = context.l10n;
    unawaited(_start(l10n.hostingTitle, l10n.hostingText));
  }

  Future<void> _start(String title, String text) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ hides the notification without this; the hosting works either way.
      try {
        await Permission.notification.request();
      } on Object catch (error) {
        debugPrint('KeepHosting: $error');
      }
    }
    if (!mounted) return;
    await KeepHosting._call('start', {'title': title, 'text': text});
  }

  @override
  void dispose() {
    unawaited(KeepHosting._call('stop'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
