import 'package:flutter/material.dart';

import '../../features/room/presentation/screens/home_screen.dart';
import '../../features/room/presentation/screens/room_screen.dart';
import '../../features/round/presentation/screens/round_screen.dart';
import '../../features/round/round_route.dart';
import 'game_exit.dart';
import '../../features/celebrity/celebrity_route.dart';
import '../../features/celebrity/presentation/screens/celebrity_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const room = '/room';

  /// Expects [RoundArgs]; pops with a [GameExit] or null.
  static const round = '/round';

  /// Expects [CelebrityArgs]; pops with a [GameExit] or null.
  static const celebrity = '/celebrity';

  static Route<Object?>? onGenerateRoute(RouteSettings settings) => switch ((settings.name, settings.arguments)) {
    (home, _) => MaterialPageRoute(settings: settings, builder: (_) => const HomeScreen()),
    (room, _) => MaterialPageRoute(settings: settings, builder: (_) => const RoomScreen()),
    (round, final RoundArgs args) => MaterialPageRoute<GameExit>(
      settings: settings,
      builder: (_) => RoundScreen(args: args),
    ),
    (celebrity, final CelebrityArgs args) => MaterialPageRoute<GameExit>(
      settings: settings,
      builder: (_) => CelebrityScreen(args: args),
    ),
    _ => null,
  };
}
