import 'family_game.dart';

/// Where a family game lives while it is played: on the host's phone, shared
/// with every friend's browser. The host's screen reads and plays through it.
abstract interface class FamilyTable {
  /// The game, or null once the room has moved on.
  FamilyGame? get game;

  /// Every move, from friends' phones or from [apply].
  Stream<FamilyGame> get changes;

  /// Makes a move on the host's own phone.
  void apply(FamilyGame Function(FamilyGame game) move);
}
