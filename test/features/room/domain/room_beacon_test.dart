import 'dart:convert';

import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/room/domain/room_beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const announcement = RoomAnnouncement(
    code: 'K7QX',
    hostName: 'Mafdy',
    port: 8182,
    mode: GameMode.family,
    category: GameCategory.preset(PresetCategory.movies),
    players: 3,
    open: true,
  );

  test('an announcement survives the trip over the network', () {
    expect(RoomAnnouncement.decode(announcement.encode()), announcement);
    const custom = RoomAnnouncement(
      code: 'AB23',
      hostName: 'نور',
      port: 40111,
      mode: GameMode.classic,
      category: GameCategory.custom('أفلام الأبيض والأسود'),
      players: 0,
      open: false,
    );
    expect(RoomAnnouncement.decode(custom.encode()), custom);
  });

  test('anything that is not one of our rooms is ignored', () {
    Map<String, Object?> json() => jsonDecode(utf8.decode(announcement.encode())) as Map<String, Object?>;
    List<int> bytes(Map<String, Object?> json) => utf8.encode(jsonEncode(json));

    expect(RoomAnnouncement.decode(utf8.encode('hello')), isNull);
    expect(RoomAnnouncement.decode([0xff, 0xfe, 0x00]), isNull);
    expect(RoomAnnouncement.decode(bytes(json()..['app'] = 'other_game')), isNull);
    expect(RoomAnnouncement.decode(bytes(json()..['v'] = 2)), isNull, reason: 'a newer version');
    expect(RoomAnnouncement.decode(bytes(json()..remove('code'))), isNull);
    expect(RoomAnnouncement.decode(bytes(json()..['port'] = 70000)), isNull);
    expect(RoomAnnouncement.decode(bytes(json()..['mode'] = 'poker')), isNull);
    expect(RoomAnnouncement.decode(bytes(json()..['preset'] = 'dinosaurs')), isNull);
  });

  test('a room opens at the address it was heard from', () {
    expect(const NearbyRoom('192.168.1.23', announcement).joinUrl.toString(), 'http://192.168.1.23:8182/');
  });
}
