import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/network_access.dart';
import '../../domain/room.dart';
import '../../domain/room_host.dart';

part 'room_state.dart';

/// Owns one hosting session: settings, the network, and the room while it is open.
class RoomCubit extends Cubit<RoomState> {
  RoomCubit({
    required this._network,
    required this._createHost,
    Random? random,
    @visibleForTesting this._addressPollInterval = const Duration(milliseconds: 300),
  }) : _random = random ?? Random(),
       super(const RoomState());

  final NetworkAccess _network;
  final RoomHostFactory _createHost;
  final Random _random;
  final Duration _addressPollInterval;

  RoomHost? _host;
  StreamSubscription<Room>? _roomSub;
  final _networkSubs = <StreamSubscription<void>>[];
  bool _checking = false;

  /// Starts watching the network. Call once after creation.
  Future<void> start() async {
    _networkSubs
      ..add(_network.changes.listen((_) => refreshConnection()))
      ..add(_network.hotspotStopped.listen((_) => _onHotspotStopped()));
    await refreshConnection();
  }

  void selectCategory(String category) => emit(state.copyWith(category: category));

  void setNamesPerPlayer(int count) => emit(state.copyWith(namesPerPlayer: count.clamp(1, Room.maxNamesPerPlayer)));

  /// Re-scans for a local address, e.g. after returning from Settings.
  Future<void> refreshConnection() async {
    if (_checking || isClosed) return;
    final current = state.connection;
    if (current is ConnectionMissing && current.starting) return;
    _checking = true;
    try {
      final address = await _network.findLanAddress();
      // The connection may have moved on while scanning (e.g. a hotspot is starting).
      final latest = state.connection;
      if (isClosed || (latest is ConnectionMissing && latest.starting)) return;
      if (latest is ConnectionAppHotspot && address != null) {
        emit(state.copyWith(connection: ConnectionAppHotspot(address, latest.credentials)));
      } else if (address != null) {
        emit(state.copyWith(connection: ConnectionReady(address)));
      } else {
        final canCreate = await _network.canCreateHotspot();
        if (isClosed) return;
        final failure = latest is ConnectionMissing ? latest.failure : null;
        emit(
          state.copyWith(
            connection: ConnectionMissing(canCreateHotspot: canCreate, failure: failure),
          ),
        );
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> createHotspot() async {
    final current = state.connection;
    if (current is! ConnectionMissing || current.starting) return;
    emit(state.copyWith(connection: ConnectionMissing(canCreateHotspot: true, starting: true)));

    final result = await _network.startHotspot();
    if (isClosed) return;
    switch (result) {
      case HotspotFailed(:final failure):
        emit(state.copyWith(connection: ConnectionMissing(canCreateHotspot: true, failure: failure)));
      case HotspotStarted(:final credentials):
        final address = await _waitForAddress();
        if (isClosed) return;
        emit(
          state.copyWith(
            connection: address == null
                ? const ConnectionMissing(canCreateHotspot: true, failure: HotspotFailure.noAddress)
                : ConnectionAppHotspot(address, credentials),
          ),
        );
    }
  }

  /// The hotspot interface appears a moment after Android reports it started.
  Future<String?> _waitForAddress() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final address = await _network.findLanAddress();
      if (address != null || isClosed) return address;
      await Future<void>.delayed(_addressPollInterval);
    }
    return null;
  }

  Future<void> openPermissionSettings() => _network.openPermissionSettings();

  Future<void> _onHotspotStopped() async {
    if (isClosed || state.connection is! ConnectionAppHotspot) return;
    emit(state.copyWith(connection: const ConnectionChecking()));
    await refreshConnection();
  }

  Future<void> openRoom() async {
    if (state.opening || state.stage == RoomStage.lobby) return;
    emit(state.copyWith(opening: true));
    final host = _createHost();
    final room = Room(code: _newCode(), category: state.category, namesPerPlayer: state.namesPerPlayer);
    try {
      final port = await host.open(room);
      if (isClosed) {
        await host.close();
        return;
      }
      _host = host;
      _roomSub = host.changes.listen((room) {
        if (!isClosed) emit(state.copyWith(room: room));
      });
      emit(state.copyWith(stage: RoomStage.lobby, room: host.room, port: port, opening: false));
    } on RoomHostException catch (error) {
      debugPrint('RoomCubit: $error');
      await host.close();
      if (!isClosed) emit(state.copyWith(opening: false, openFailed: true));
    }
  }

  /// Back to the setup stage. Friends' pages stop loading.
  Future<void> closeRoom() async {
    await _shutDownHost();
    if (!isClosed) emit(state.copyWith(stage: RoomStage.setup, clearRoom: true));
  }

  void addHostSecret(String secret) => _host?.update((room) => room.withHostSecret(secret));

  /// Locks the bowl and returns its slips, or null when the room cannot start yet.
  List<Slip>? startReading() {
    final host = _host;
    if (host == null || !host.room.canStart) return null;
    host.update((room) => room.startReading());
    return host.room.slips;
  }

  /// The host left the reading early: let friends edit again, keep the bowl.
  void reopen() => _host?.update((room) => room.reopen());

  void nextRound() => _host?.update((room) => room.nextRound());

  String _newCode() {
    // No 0/O, 1/I/L: the code is read aloud and typed.
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return [for (var i = 0; i < 4; i++) alphabet[_random.nextInt(alphabet.length)]].join();
  }

  Future<void> _shutDownHost() async {
    await _roomSub?.cancel();
    _roomSub = null;
    final host = _host;
    _host = null;
    await host?.close();
  }

  @override
  Future<void> close() async {
    for (final sub in _networkSubs) {
      await sub.cancel();
    }
    await _shutDownHost();
    if (state.connection is ConnectionAppHotspot) await _network.stopHotspot();
    return super.close();
  }
}
