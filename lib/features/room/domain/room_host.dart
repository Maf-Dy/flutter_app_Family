import 'room.dart';

/// Thrown when the room cannot start listening for friends.
final class RoomHostException implements Exception {
  const RoomHostException(this.message);

  final String message;

  @override
  String toString() => 'RoomHostException: $message';
}

/// Creates a fresh host for each room the user opens.
typedef RoomHostFactory = RoomHost Function();

/// Serves a [Room] to friends' phones and keeps it as the single source of truth:
/// friends' submissions and the host's own changes both go through here.
abstract interface class RoomHost {
  /// Starts serving [room]. Returns the port friends connect to.
  /// Throws [RoomHostException] when the server cannot start.
  Future<int> open(Room room);

  Room get room;

  /// Every change, from friends or from [update].
  Stream<Room> get changes;

  /// Applies a host-side change, such as the host's own name or starting a round.
  void update(Room Function(Room room) change);

  Future<void> close();
}
