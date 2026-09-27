import '../room/domain/room.dart';

/// What the team race needs from the room: plain values, no room state.
final class CelebrityArgs {
  const CelebrityArgs({required this.category, required this.slips, required this.players, required this.setup});

  final GameCategory category;
  final List<Slip> slips;

  /// In join order, with the team each player chose on the join page, if any.
  final List<({String id, String name, int? team})> players;
  final TeamSetup setup;
}
