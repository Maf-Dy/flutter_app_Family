import 'package:family_game/features/room/domain/network_access.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/room/presentation/state/room_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  late FakeNetwork network;
  late FakeRoomHost host;

  RoomCubit build({bool failOpen = false}) {
    host = FakeRoomHost(failOpen: failOpen);
    return RoomCubit(network: network, createHost: () => host, addressPollInterval: Duration.zero);
  }

  tearDown(() => network.dispose());

  group('connection', () {
    test('is ready on Wi-Fi', () async {
      network = FakeNetwork(address: '192.168.1.23');
      final cubit = build();
      await cubit.start();
      expect(cubit.state.connection, isA<ConnectionReady>().having((c) => c.address, 'address', '192.168.1.23'));
      await cubit.close();
    });

    test('offers a hotspot when there is no network', () async {
      network = FakeNetwork();
      final cubit = build();
      await cubit.start();
      expect(cubit.state.connection, isA<ConnectionMissing>().having((c) => c.canCreateHotspot, 'canCreate', isTrue));
      await cubit.close();
    });

    test('creates a hotspot and then serves on it; stops it on close', () async {
      network = FakeNetwork();
      final cubit = build();
      await cubit.start();
      await cubit.createHotspot();
      expect(
        cubit.state.connection,
        isA<ConnectionAppHotspot>()
            .having((c) => c.address, 'address', '192.168.49.1')
            .having((c) => c.credentials.ssid, 'ssid', 'AndroidShare_1234'),
      );
      await cubit.close();
      expect(network.stopCalls, 1);
    });

    test('keeps the failure so the screen can explain it', () async {
      network = FakeNetwork(hotspotResult: const HotspotFailed(HotspotFailure.permissionBlocked));
      final cubit = build();
      await cubit.start();
      await cubit.createHotspot();
      expect(
        cubit.state.connection,
        isA<ConnectionMissing>().having((c) => c.failure, 'failure', HotspotFailure.permissionBlocked),
      );
      await cubit.refreshConnection();
      expect((cubit.state.connection as ConnectionMissing).failure, HotspotFailure.permissionBlocked);
      await cubit.close();
    });

    test('reports a hotspot whose address never appears', () async {
      network = FakeNetwork(hotspotAddress: null);
      final cubit = build();
      await cubit.start();
      await cubit.createHotspot();
      expect((cubit.state.connection as ConnectionMissing).failure, HotspotFailure.noAddress);
      await cubit.close();
    });

    test('follows the network when it changes', () async {
      network = FakeNetwork();
      final cubit = build();
      await cubit.start();
      network.address = '192.168.1.50';
      network.changesController.add(null);
      await pumpEventQueue();
      expect(cubit.state.address, '192.168.1.50');
      await cubit.close();
    });
  });

  group('room', () {
    setUp(() => network = FakeNetwork(address: '192.168.1.23'));

    test('opens with the chosen settings and a join link', () async {
      final cubit = build();
      await cubit.start();
      cubit
        ..selectCategory('Movies')
        ..setNamesPerPlayer(5);
      await cubit.openRoom();
      expect(cubit.state.stage, RoomStage.lobby);
      expect(cubit.state.room!.category, 'Movies');
      expect(cubit.state.room!.namesPerPlayer, Room.maxNamesPerPlayer);
      expect(cubit.state.room!.code, matches(RegExp(r'^[A-Z2-9]{4}$')));
      expect(cubit.state.joinUrl, 'http://192.168.1.23:8182');
      await cubit.close();
      expect(host.closed, isTrue);
    });

    test('reports a room that could not open', () async {
      final cubit = build(failOpen: true);
      await cubit.start();
      await cubit.openRoom();
      expect(cubit.state.stage, RoomStage.setup);
      expect(cubit.state.openFailed, isTrue);
      expect(cubit.state.opening, isFalse);
      await cubit.close();
    });

    test('starts reading only with enough players, then runs rounds', () async {
      final cubit = build();
      await cubit.start();
      await cubit.openRoom();
      host
        ..join('a', 'Omar', ['Messi'])
        ..join('b', 'Nour', ['Fairuz']);
      await pumpEventQueue();
      expect(cubit.state.room!.slipCount, 2);
      expect(cubit.startReading(), isNull);

      cubit.addHostSecret('Adele');
      await pumpEventQueue();
      final slips = cubit.startReading();
      expect(slips, hasLength(3));
      expect(host.room.isCollecting, isFalse);

      cubit.reopen();
      expect(host.room.isCollecting, isTrue);
      expect(host.room.slipCount, 3);

      cubit.nextRound();
      await pumpEventQueue();
      expect(cubit.state.room!.round, 2);
      expect(cubit.state.room!.slipCount, 0);
      await cubit.close();
    });

    test('closing the room returns to setup', () async {
      final cubit = build();
      await cubit.start();
      await cubit.openRoom();
      await cubit.closeRoom();
      expect(cubit.state.stage, RoomStage.setup);
      expect(cubit.state.room, isNull);
      expect(host.closed, isTrue);
      await cubit.close();
    });
  });
}
