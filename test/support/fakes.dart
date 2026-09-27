import 'dart:async';

import 'package:family_game/features/room/domain/network_access.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/room/domain/room_host.dart';

class FakeNetwork implements NetworkAccess {
  FakeNetwork({this.address, this.canCreate = true, this.hotspotResult, this.hotspotAddress = '192.168.49.1'});

  String? address;
  bool canCreate;
  HotspotResult? hotspotResult;

  /// Address that appears once the app hotspot starts (null: it never shows up).
  String? hotspotAddress;

  int startCalls = 0;
  int stopCalls = 0;
  int settingsCalls = 0;
  final changesController = StreamController<void>.broadcast();
  final stoppedController = StreamController<void>.broadcast();

  @override
  Future<String?> findLanAddress() async => address;

  @override
  Stream<void> get changes => changesController.stream;

  @override
  Stream<void> get hotspotStopped => stoppedController.stream;

  @override
  Future<bool> canCreateHotspot() async => canCreate;

  @override
  Future<HotspotResult> startHotspot() async {
    startCalls++;
    final result =
        hotspotResult ?? const HotspotStarted(HotspotCredentials(ssid: 'AndroidShare_1234', password: 'secret12'));
    if (result is HotspotStarted) address = hotspotAddress;
    return result;
  }

  @override
  Future<void> stopHotspot() async => stopCalls++;

  @override
  Future<void> openPermissionSettings() async => settingsCalls++;

  Future<void> dispose() async {
    await changesController.close();
    await stoppedController.close();
  }
}

class FakeRoomHost implements RoomHost {
  FakeRoomHost({this.failOpen = false});

  final bool failOpen;
  final _changes = StreamController<Room>.broadcast();
  late Room _room;
  bool closed = false;

  @override
  Future<int> open(Room room) async {
    if (failOpen) throw const RoomHostException('port in use');
    _room = room;
    return 8182;
  }

  @override
  Room get room => _room;

  @override
  Stream<Room> get changes => _changes.stream;

  @override
  void update(Room Function(Room room) change) {
    _room = change(_room);
    _changes.add(_room);
  }

  /// A friend submits the join form.
  void join(String id, String name, List<String> secrets) {
    assert(_room.validate(name: name, secrets: secrets) == null);
    update((room) => room.withSubmission(playerId: id, name: name, secrets: secrets));
  }

  @override
  Future<void> close() async {
    closed = true;
    unawaited(_changes.close());
  }
}
