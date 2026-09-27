import '../room/domain/room.dart';

/// What the round screen needs from the room: plain values, no room state.
final class RoundArgs {
  const RoundArgs({required this.category, required this.slips, required this.players});

  final String category;
  final List<Slip> slips;

  /// Player ids in join order, so avatars keep the colours they had in the lobby.
  final List<String> players;
}

/// How the host left the round. Null (system back) means "back to the lobby".
enum RoundExit { newRound, endGame }
