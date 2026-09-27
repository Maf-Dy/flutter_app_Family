import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'room.dart';

/// What a hosting phone tells nearby phones about its room, so the app can
/// list it under "Join a game".
@immutable
final class RoomAnnouncement {
  const RoomAnnouncement({
    required this.code,
    required this.hostName,
    required this.port,
    required this.mode,
    required this.category,
    required this.players,
    required this.open,
  });

  /// Everything the list needs from the room served on [port].
  factory RoomAnnouncement.of(Room room, int port) => RoomAnnouncement(
    code: room.code,
    hostName: room.hostName,
    port: port,
    mode: room.mode,
    category: room.category,
    players: room.playersIn.length,
    open: room.isCollecting,
  );

  /// Marks our packets, so other apps' broadcasts on the same port are ignored.
  static const _app = 'family_game';
  static const _version = 1;

  final String code;
  final String hostName;
  final int port;
  final GameMode mode;
  final GameCategory category;

  /// Players whose names are in.
  final int players;

  /// Whether the bowl still takes names; once a game starts, newcomers can only watch.
  final bool open;

  List<int> encode() => utf8.encode(
    jsonEncode({
      'app': _app,
      'v': _version,
      'code': code,
      'host': hostName,
      'port': port,
      'mode': mode.name,
      'preset': ?category.preset?.name,
      'custom': ?category.custom,
      'players': players,
      'open': open,
    }),
  );

  /// Null for anything that isn't a room from this app, or is from a newer
  /// version this phone doesn't understand.
  static RoomAnnouncement? decode(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json case {
        'app': _app,
        'v': _version,
        'code': final String code,
        'host': final String host,
        'port': final int port,
        'mode': final String mode,
        'players': final int players,
        'open': final bool open,
      } when port > 0 && port <= 65535) {
        final gameMode = GameMode.values.asNameMap()[mode];
        final gameCategory = switch ((json['preset'], json['custom'])) {
          (final String preset, _) => switch (PresetCategory.values.asNameMap()[preset]) {
            final PresetCategory p => GameCategory.preset(p),
            null => null,
          },
          (_, final String custom) => GameCategory.custom(custom),
          _ => null,
        };
        if (gameMode == null || gameCategory == null) return null;
        return RoomAnnouncement(
          code: code,
          hostName: host,
          port: port,
          mode: gameMode,
          category: gameCategory,
          players: players,
          open: open,
        );
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RoomAnnouncement &&
      other.code == code &&
      other.hostName == hostName &&
      other.port == port &&
      other.mode == mode &&
      other.category == category &&
      other.players == players &&
      other.open == open;

  @override
  int get hashCode => Object.hash(code, hostName, port, mode, category, players, open);
}

/// A room heard on the network, and where to open it.
@immutable
final class NearbyRoom {
  const NearbyRoom(this.address, this.announcement);

  /// The hosting phone's address, as seen from this phone.
  final String address;
  final RoomAnnouncement announcement;

  /// The same link the host's QR code carries.
  Uri get joinUrl => Uri(scheme: 'http', host: address, port: announcement.port, path: '/');

  @override
  bool operator ==(Object other) =>
      other is NearbyRoom && other.address == address && other.announcement == announcement;

  @override
  int get hashCode => Object.hash(address, announcement);
}

/// Tells phones on the same network that a room is open.
abstract interface class RoomBeacon {
  /// Starts announcing, or updates what is announced.
  Future<void> announce(RoomAnnouncement announcement);

  /// Stops announcing. Safe to call when not announcing.
  Future<void> stop();
}

/// Listens for [RoomBeacon]s on the network.
abstract interface class RoomFinder {
  /// The rooms heard recently, updated as rooms appear, change or go quiet.
  /// Listening starts with the first subscriber and stops with the last.
  Stream<List<NearbyRoom>> watch();
}
