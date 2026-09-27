import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display awake while [child] is on screen: the host phone serves the
/// room and shows the names, so it must not lock mid-game.
class KeepScreenOn extends StatefulWidget {
  const KeepScreenOn({super.key, required this.child});

  final Widget child;

  @override
  State<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends State<KeepScreenOn> {
  @override
  void initState() {
    super.initState();
    _toggle(true);
  }

  @override
  void dispose() {
    _toggle(false);
    super.dispose();
  }

  // Best effort: if the platform refuses, the game still works and the phone
  // simply follows its normal screen timeout.
  Future<void> _toggle(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (error) {
      debugPrint('KeepScreenOn: wakelock unavailable ($error)');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
