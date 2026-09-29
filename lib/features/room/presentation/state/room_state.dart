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
  const ConnectionReady(this.address, {this.hotspotFailure});

  final String address;

  /// Set when the host tried the app's hotspot instead and it did not start.
  final HotspotFailure? hotspotFailure;
}

/// The app is starting its own hotspot.
final class ConnectionStartingHotspot extends Connection {
  const ConnectionStartingHotspot();
}

/// On the hotspot the app created: friends need its Wi-Fi code first.
final class ConnectionAppHotspot extends Connection {
  const ConnectionAppHotspot(this.address, this.credentials, {this.wifiAvailable = false});

  final String address;
  final HotspotCredentials credentials;

  /// The host has since joined Wi-Fi, but friends are already on the hotspot,
  /// so the room waits for the host to choose.
  final bool wifiAvailable;
}

/// No local network. The app may be able to create one.
final class ConnectionMissing extends Connection {
  const ConnectionMissing({required this.canCreateHotspot, this.failure});

  final bool canCreateHotspot;
  final HotspotFailure? failure;
}

/// Whether this phone could open its own join link.
enum LinkCheck { unknown, works, broken }

@immutable
final class RoomState {
  const RoomState({
    this.stage = RoomStage.setup,
    this.category = const GameCategory.preset(PresetCategory.famousPeople),
    this.allowDuplicates = true,
    this.mode = GameMode.classic,
    this.teamSetup = const TeamSetup(),
    this.familyChat = true,
    this.familyTwists = FamilyTwists.none,
    this.namesPerPlayer = 1,
    this.connection = const ConnectionChecking(),
    this.room,
    this.port,
    this.opening = false,
    this.openFailed = false,
    this.linkCheck = LinkCheck.unknown,
  });

  final RoomStage stage;
  final GameCategory category;
  final bool allowDuplicates;
  final GameMode mode;
  final TeamSetup teamSetup;

  /// Whether families can message each other in [GameMode.family].
  final bool familyChat;

  /// House rules for [GameMode.family].
  final FamilyTwists familyTwists;
  final int namesPerPlayer;
  final Connection connection;
  final Room? room;
  final int? port;
  final bool opening;

  /// Result of the phone opening its own join link; see [NetworkAccess.canReach].
  final LinkCheck linkCheck;

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
    GameCategory? category,
    bool? allowDuplicates,
    GameMode? mode,
    TeamSetup? teamSetup,
    bool? familyChat,
    FamilyTwists? familyTwists,
    int? namesPerPlayer,
    Connection? connection,
    Room? room,
    int? port,
    bool? opening,
    bool? openFailed,
    LinkCheck? linkCheck,
    bool clearRoom = false,
  }) => RoomState(
    stage: stage ?? this.stage,
    category: category ?? this.category,
    allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    mode: mode ?? this.mode,
    teamSetup: teamSetup ?? this.teamSetup,
    familyChat: familyChat ?? this.familyChat,
    familyTwists: familyTwists ?? this.familyTwists,
    namesPerPlayer: namesPerPlayer ?? this.namesPerPlayer,
    connection: connection ?? this.connection,
    room: clearRoom ? null : room ?? this.room,
    port: clearRoom ? null : port ?? this.port,
    opening: opening ?? this.opening,
    openFailed: openFailed ?? false,
    linkCheck: clearRoom ? LinkCheck.unknown : linkCheck ?? this.linkCheck,
  );
}
