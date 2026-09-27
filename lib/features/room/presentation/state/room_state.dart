part of 'room_cubit.dart';

enum RoomStage { setup, lobby }

/// How friends can reach this phone right now.
sealed class Connection {
  const Connection();
}

final class ConnectionChecking extends Connection {
  const ConnectionChecking();
}

/// On Wi-Fi, or on a hotspot the user turned on themselves.
final class ConnectionReady extends Connection {
  const ConnectionReady(this.address);

  final String address;
}

/// On the hotspot the app created: friends need its Wi-Fi code first.
final class ConnectionAppHotspot extends Connection {
  const ConnectionAppHotspot(this.address, this.credentials);

  final String address;
  final HotspotCredentials credentials;
}

/// No local network. The app may be able to create one.
final class ConnectionMissing extends Connection {
  const ConnectionMissing({required this.canCreateHotspot, this.starting = false, this.failure});

  final bool canCreateHotspot;
  final bool starting;
  final HotspotFailure? failure;
}

@immutable
final class RoomState {
  const RoomState({
    this.stage = RoomStage.setup,
    this.category = 'Famous people',
    this.namesPerPlayer = 1,
    this.connection = const ConnectionChecking(),
    this.room,
    this.port,
    this.opening = false,
    this.openFailed = false,
  });

  static const categories = ['Famous people', 'Movies', 'Animals', 'Countries', 'Footballers', 'Anything'];

  final RoomStage stage;
  final String category;
  final int namesPerPlayer;
  final Connection connection;
  final Room? room;
  final int? port;
  final bool opening;

  /// One-shot flag the screen turns into a message.
  final bool openFailed;

  String? get address => switch (connection) {
    ConnectionReady(:final address) || ConnectionAppHotspot(:final address) => address,
    _ => null,
  };

  /// The link friends open, once both the room and the network are up.
  String? get joinUrl => address == null || port == null ? null : 'http://$address${port == 80 ? '' : ':$port'}';

  RoomState copyWith({
    RoomStage? stage,
    String? category,
    int? namesPerPlayer,
    Connection? connection,
    Room? room,
    int? port,
    bool? opening,
    bool? openFailed,
    bool clearRoom = false,
  }) => RoomState(
    stage: stage ?? this.stage,
    category: category ?? this.category,
    namesPerPlayer: namesPerPlayer ?? this.namesPerPlayer,
    connection: connection ?? this.connection,
    room: clearRoom ? null : room ?? this.room,
    port: clearRoom ? null : port ?? this.port,
    opening: opening ?? this.opening,
    openFailed: openFailed ?? false,
  );
}
