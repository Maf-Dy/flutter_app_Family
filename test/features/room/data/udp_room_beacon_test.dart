import 'dart:async';
import 'dart:io';

import 'package:family_game/features/room/data/udp_room_beacon.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/room/domain/room_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const announcement = RoomAnnouncement(
    code: 'K7QX',
    hostName: 'Mafdy',
    port: 8182,
    mode: GameMode.classic,
    category: GameCategory.preset(PresetCategory.movies),
    players: 2,
    open: true,
  );

  test('a phone listening hears the room, sees it change, and sees it go', () async {
    // A fixed high port, sent over loopback: broadcasts may not leave a test machine.
    const port = 48183;
    final beacon = UdpRoomBeacon(
      port: port,
      interval: const Duration(milliseconds: 50),
      targets: () async => [InternetAddress.loopbackIPv4],
    );
    var locks = 0;
    final finder = UdpRoomFinder(
      port: port,
      expireAfter: const Duration(milliseconds: 400),
      onListen: () async => locks++,
      onCancel: () async => locks--,
    );
    final seen = StreamIterator(finder.watch());

    Future<List<NearbyRoom>> next(bool Function(List<NearbyRoom>) test) async {
      while (await seen.moveNext().timeout(const Duration(seconds: 5))) {
        if (test(seen.current)) return seen.current;
      }
      throw StateError('stream ended');
    }

    expect(await next((rooms) => true), isEmpty, reason: 'starts empty, while it listens');
    expect(locks, 1);

    await beacon.announce(announcement);
    final heard = await next((rooms) => rooms.isNotEmpty);
    expect(heard.single.address, '127.0.0.1');
    expect(heard.single.announcement, announcement);

    await beacon.announce(
      const RoomAnnouncement(
        code: 'K7QX',
        hostName: 'Mafdy',
        port: 8182,
        mode: GameMode.classic,
        category: GameCategory.preset(PresetCategory.movies),
        players: 3,
        open: true,
      ),
    );
    await next((rooms) => rooms.singleOrNull?.announcement.players == 3);

    await beacon.stop();
    await next((rooms) => rooms.isEmpty);

    await seen.cancel();
    expect(locks, 0, reason: 'the multicast lock is released');
  });

  test('broadcasts reach every local network, not just the default one', () {
    expect(
      broadcastTargetsFor([
        '192.168.1.23',
        '192.168.49.1',
        '10.0.0.7',
        '100.64.1.2',
        '127.0.0.1',
      ]).map((a) => a.address),
      unorderedEquals(['255.255.255.255', '192.168.1.255', '192.168.49.255', '10.0.0.255']),
    );
  });
}
