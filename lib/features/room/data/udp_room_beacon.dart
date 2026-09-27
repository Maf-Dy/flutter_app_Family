import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../domain/room_beacon.dart';

/// The UDP port rooms are announced on. Friends' phones listen here.
const roomBeaconPort = 8183;

/// Where a beacon sends its packets. Returns the broadcast addresses of this
/// phone's local networks.
typedef BroadcastTargets = Future<List<InternetAddress>> Function();

/// Announces the open room with a small UDP broadcast every second.
///
/// Sends to every local network's broadcast address as well as the general
/// one, because Android routes 255.255.255.255 out of a single interface,
/// which may not be the hotspot friends are on.
class UdpRoomBeacon implements RoomBeacon {
  UdpRoomBeacon({this.port = roomBeaconPort, this.interval = const Duration(seconds: 1), BroadcastTargets? targets})
    : _targets = targets ?? localBroadcastTargets;

  final int port;
  final Duration interval;
  final BroadcastTargets _targets;

  RawDatagramSocket? _socket;
  Timer? _timer;
  List<int>? _packet;
  bool _sending = false;

  @override
  Future<void> announce(RoomAnnouncement announcement) async {
    _packet = announcement.encode();
    if (_timer != null) return;
    try {
      _socket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        ..broadcastEnabled = true;
    } on SocketException catch (error) {
      // Joining by QR code still works; only the "Join a game" list misses this room.
      debugPrint('UdpRoomBeacon: cannot announce ($error)');
      return;
    }
    if (_packet == null) return; // Stopped while binding.
    _timer = Timer.periodic(interval, (_) => _send());
    unawaited(_send());
  }

  Future<void> _send() async {
    final socket = _socket;
    final packet = _packet;
    if (socket == null || packet == null || _sending) return;
    _sending = true;
    try {
      for (final target in await _targets()) {
        try {
          socket.send(packet, target, port);
        } on SocketException catch (error) {
          // For example, a network that just went away.
          debugPrint('UdpRoomBeacon: send to ${target.address} failed ($error)');
        }
      }
    } finally {
      _sending = false;
    }
  }

  @override
  Future<void> stop() async {
    _packet = null;
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }
}

/// Lists rooms announced by [UdpRoomBeacon]s on the same network.
///
/// A room drops off the list once it has been quiet for [expireAfter], so a
/// host who closed the room or left the Wi-Fi disappears on its own.
class UdpRoomFinder implements RoomFinder {
  UdpRoomFinder({
    this.port = roomBeaconPort,
    this.expireAfter = const Duration(seconds: 4),
    this._onListen,
    this._onCancel,
    @visibleForTesting DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final int port;
  final Duration expireAfter;

  /// Called when listening starts and stops; Android needs a multicast lock
  /// held meanwhile, or the Wi-Fi chip drops broadcasts to save power.
  final Future<void> Function()? _onListen;
  final Future<void> Function()? _onCancel;
  final DateTime Function() _now;

  @override
  Stream<List<NearbyRoom>> watch() {
    RawDatagramSocket? socket;
    Timer? sweep;
    final heard = <String, ({NearbyRoom room, DateTime at})>{};
    late final StreamController<List<NearbyRoom>> controller;
    var last = const <NearbyRoom>[];

    void publish() {
      final cutoff = _now().subtract(expireAfter);
      heard.removeWhere((_, entry) => entry.at.isBefore(cutoff));
      final rooms = [for (final entry in heard.values) entry.room]
        ..sort((a, b) => a.announcement.hostName.toLowerCase().compareTo(b.announcement.hostName.toLowerCase()));
      if (listEquals(rooms, last)) return;
      last = rooms;
      if (!controller.isClosed) controller.add(rooms);
    }

    void onDatagram(RawSocketEvent event) {
      if (event != RawSocketEvent.read) return;
      Datagram? datagram;
      while ((datagram = socket?.receive()) != null) {
        final announcement = RoomAnnouncement.decode(datagram!.data);
        if (announcement == null) continue;
        final room = NearbyRoom(datagram.address.address, announcement);
        heard['${room.address}:${announcement.port}'] = (room: room, at: _now());
      }
      publish();
    }

    controller = StreamController<List<NearbyRoom>>(
      onListen: () async {
        controller.add(const []);
        await _onListen?.call();
        try {
          socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port, reuseAddress: true)
            ..broadcastEnabled = true;
        } on SocketException catch (error) {
          if (!controller.isClosed) controller.addError(RoomFinderException(error.message));
          return;
        }
        if (controller.isClosed) {
          socket?.close();
          return;
        }
        socket!.listen(onDatagram);
        sweep = Timer.periodic(const Duration(seconds: 1), (_) => publish());
      },
      onCancel: () async {
        sweep?.cancel();
        socket?.close();
        socket = null;
        await _onCancel?.call();
        await controller.close();
      },
    );
    return controller.stream;
  }
}

/// This phone could not listen for rooms, for example because another app holds the port.
final class RoomFinderException implements Exception {
  const RoomFinderException(this.message);

  final String message;

  @override
  String toString() => 'RoomFinderException: $message';
}

/// The general broadcast address plus the /24 broadcast address of every
/// private IPv4 network this phone is on. Dart doesn't expose netmasks, and
/// home Wi-Fi and Android hotspots are /24 networks.
Future<List<InternetAddress>> localBroadcastTargets() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  return broadcastTargetsFor([
    for (final interface in interfaces)
      for (final address in interface.addresses) address.address,
  ]);
}

@visibleForTesting
List<InternetAddress> broadcastTargetsFor(List<String> addresses) {
  final targets = <String>{'255.255.255.255'};
  for (final address in addresses) {
    final parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) continue;
    final [a!, b!, c!, _] = parts;
    final private = a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
    if (private) targets.add('$a.$b.$c.255');
  }
  return [for (final t in targets) InternetAddress(t)];
}
