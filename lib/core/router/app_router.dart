import 'package:flutter/material.dart';

import '../../features/room/presentation/screens/home_screen.dart';
import '../../features/room/presentation/screens/room_screen.dart';
import '../../features/round/presentation/screens/round_screen.dart';
import '../../features/round/round_route.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const room = '/room';

  /// Expects [RoundArgs]; pops with a [RoundExit] or null.
  static const round = '/round';

  static Route<Object?>? onGenerateRoute(RouteSettings settings) => switch ((settings.name, settings.arguments)) {
    (home, _) => MaterialPageRoute(settings: settings, builder: (_) => const HomeScreen()),
    (room, _) => MaterialPageRoute(settings: settings, builder: (_) => const RoomScreen()),
    (round, final RoundArgs args) => MaterialPageRoute<RoundExit>(
      settings: settings,
      builder: (_) => RoundScreen(args: args),
    ),
    _ => null,
  };
}
