import 'package:family_game/features/room/domain/network_access.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/room/presentation/state/room_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  late FakeNetwork network;
  late FakeRoomHost host;

  RoomCubit build({bool failOpen = false, Duration poll = const Duration(hours: 1)}) {
    host = FakeRoomHost(failOpen: failOpen);
    return RoomCubit(network: network, createHost: () => host, pollInterval: poll);
  }

  tearDown(() => network.dispose());

  group('connection', () {
    test('is ready on Wi-Fi', () async {
      network = FakeNetwork(address: '192.168.1.23', onWifi: true);
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

    test('notices Wi-Fi even when no change event arrives', () async {
      network = FakeNetwork();
      final cubit = build(poll: const Duration(milliseconds: 5));
      await cubit.start();
      network.address = '192.168.1.50';
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(cubit.state.address, '192.168.1.50');
      await cubit.close();
    });

    test('a change during a check is not lost', () async {
      network = FakeNetwork();
      final cubit = build();
      await cubit.start();
      final first = cubit.refreshConnection();
      network.address = '192.168.1.50';
      final second = cubit.refreshConnection(); // arrives while the first is still checking
      await Future.wait([first, second]);
      expect(cubit.state.address, '192.168.1.50');
      await cubit.close();
    });

    test('leaves the app hotspot for Wi-Fi when nobody has joined yet', () async {
      network = FakeNetwork();
      final cubit = build();
      await cubit.start();
      await cubit.createHotspot();
      network
        ..address = '192.168.1.50'
        ..onWifi = true;
      await cubit.refreshConnection();
      expect(cubit.state.connection, isA<ConnectionReady>().having((c) => c.address, 'address', '192.168.1.50'));
      expect(network.stopCalls, 1);
      await cubit.close();
    });

    test('keeps friends on the hotspot until the host switches to Wi-Fi', () async {
      network = FakeNetwork();
      final cubit = build();
      await cubit.start();
      await cubit.openRoom(hostName: 'Mafdy');
      await cubit.createHotspot();
      host.join('a', 'Omar', ['Messi']);
      await pumpEventQueue();
      network
        ..address = '192.168.1.50'
        ..onWifi = true;
      await cubit.refreshConnection();
      expect(cubit.state.connection, isA<ConnectionAppHotspot>().having((c) => c.wifiAvailable, 'wifi', isTrue));
      expect(network.stopCalls, 0);

      await cubit.switchToWifi();
      expect(cubit.state.connection, isA<ConnectionReady>());
      expect(network.stopCalls, 1);
      await cubit.close();
    });

    test('a hotspot chosen over Wi-Fi stays on, and a failed one keeps the Wi-Fi link', () async {
      network = FakeNetwork(address: '192.168.1.23', onWifi: true);
      final cubit = build();
      await cubit.start();
      await cubit.createHotspot();
      await cubit.refreshConnection();
      expect(cubit.state.connection, isA<ConnectionAppHotspot>(), reason: 'the host picked it on purpose');
      await cubit.switchToWifi();

      network.hotspotResult = const HotspotFailed(HotspotFailure.incompatibleMode);
      await cubit.createHotspot();
      expect(
        cubit.state.connection,
        isA<ConnectionReady>()
            .having((c) => c.address, 'address', '192.168.1.23')
            .having((c) => c.hotspotFailure, 'failure', HotspotFailure.incompatibleMode),
      );
      await cubit.close();
    });

    test('checks that the join link opens on this phone', () async {
      network = FakeNetwork(address: '192.168.1.23', onWifi: true, reachable: false);
      final cubit = build();
      await cubit.start();
      await cubit.openRoom(hostName: 'Mafdy');
      await pumpEventQueue();
      expect(cubit.state.linkCheck, LinkCheck.broken);

      network
        ..reachable = true
        ..address = '192.168.1.24';
      await cubit.refreshConnection();
      await pumpEventQueue();
      expect(cubit.state.linkCheck, LinkCheck.works);
      await cubit.close();
    });
  });

  group('room', () {
    setUp(() => network = FakeNetwork(address: '192.168.1.23', onWifi: true));

    test('opens with the chosen settings and a join link', () async {
      final cubit = build();
      await cubit.start();
      cubit
        ..selectCategory(const GameCategory.preset(PresetCategory.movies))
        ..setNamesPerPlayer(5);
      await cubit.openRoom(hostName: 'Mafdy');
      expect(cubit.state.stage, RoomStage.lobby);
      expect(cubit.state.room!.category, const GameCategory.preset(PresetCategory.movies));
      expect(cubit.state.room!.namesPerPlayer, Room.maxNamesPerPlayer);
      expect(cubit.state.room!.code, matches(RegExp(r'^[A-Z2-9]{4}$')));
      expect(cubit.state.joinUrl, 'http://192.168.1.23:8182');
      await cubit.close();
      expect(host.closed, isTrue);
    });

    test('reports a room that could not open', () async {
      final cubit = build(failOpen: true);
      await cubit.start();
      await cubit.openRoom(hostName: 'Mafdy');
      expect(cubit.state.stage, RoomStage.setup);
      expect(cubit.state.openFailed, isTrue);
      expect(cubit.state.opening, isFalse);
      await cubit.close();
    });

    test('starts reading only with enough players, then runs rounds', () async {
      final cubit = build();
      await cubit.start();
      await cubit.openRoom(hostName: 'Mafdy');
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
      await cubit.openRoom(hostName: 'Mafdy');
      await cubit.closeRoom();
      expect(cubit.state.stage, RoomStage.setup);
      expect(cubit.state.room, isNull);
      expect(host.closed, isTrue);
      await cubit.close();
    });
  });
}
