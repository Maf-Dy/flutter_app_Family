import 'package:flutter/widgets.dart';

extension SafePop on BuildContext {
  /// Closes the route this context belongs to, but only while it is the top
  /// route. A second tap while a screen or dialog is already closing would
  /// otherwise close the screen underneath too, and a few of those in a row
  /// leave the app with no screen at all.
  void popRoute<T extends Object?>([T? result]) {
    final route = ModalRoute.of(this);
    if (route != null && !route.isCurrent) return;
    Navigator.of(this).pop<T>(result);
  }
}
