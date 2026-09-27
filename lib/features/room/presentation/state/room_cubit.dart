import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/network_access.dart';
import '../../domain/room.dart';
import '../../domain/room_host.dart';
import '../../../family/domain/family_table.dart';
import '../../data/host_family_table.dart';

part 'room_state.dart';

/// Owns one hosting session: settings, the network, and the room while it is open.
class RoomCubit extends Cubit<RoomState> {
  RoomCubit({
    required this._network,
    required this._createHost,
    Random? random,
    @visibleForTesting this._pollInterval = const Duration(seconds: 3),
  }) : _random = random ?? Random(),
       super(const RoomState());

  final NetworkAccess _network;
  final RoomHostFactory _createHost;
  final Random _random;

  /// How often the network is re-checked, in case a change event never arrives
  /// (joining Wi-Fi, or turning a hotspot on in Settings, does not always send one).
  final Duration _pollInterval;

  RoomHost? _host;
  StreamSubscription<Room>? _roomSub;
  final _networkSubs = <StreamSubscription<void>>[];
  Timer? _poll;
  bool _checking = false;
  bool _checkAgain = false;

  /// The host started the app's hotspot although Wi-Fi was available (for
  /// example, the Wi-Fi keeps phones apart), so being on Wi-Fi must not end it.
  bool _hotspotChosenOverWifi = false;

  /// Starts watching the network. Call once after creation.
  Future<void> start() async {
    _networkSubs
      ..add(_network.changes.listen((_) => refreshConnection()))
      ..add(_network.hotspotStopped.listen((_) => _onHotspotStopped()));
    _poll = Timer.periodic(_pollInterval, (_) => refreshConnection());
    await refreshConnection();
  }

  void selectCategory(GameCategory category) => emit(state.copyWith(category: category));

  void setAllowDuplicates(bool allow) => emit(state.copyWith(allowDuplicates: allow));

  void setMode(GameMode mode) => emit(state.copyWith(mode: mode));

  void setFamilyChat(bool on) => emit(state.copyWith(familyChat: on));

  void setTeamSetup(TeamSetup setup) =>
      emit(state.copyWith(teamSetup: setup.copyWith(count: setup.count.clamp(TeamSetup.minTeams, TeamSetup.maxTeams))));

  void setNamesPerPlayer(int count) => emit(state.copyWith(namesPerPlayer: count.clamp(1, Room.maxNamesPerPlayer)));

  /// Re-checks how friends can reach this phone. Safe to call often: a call that
  /// arrives mid-check runs one more check afterwards instead of being dropped.
  Future<void> refreshConnection() async {
    if (isClosed) return;
    if (_checking) {
      _checkAgain = true;
      return;
    }
    _checking = true;
    try {
      do {
        _checkAgain = false;
        await _checkConnection();
      } while (_checkAgain && !isClosed);
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkConnection() async {
    final current = state.connection;
    if (current is ConnectionStartingHotspot) return;
    if (current is ConnectionAppHotspot) {
      if (_hotspotChosenOverWifi || !await _network.isOnWifi()) return;
      if (isClosed) return;
      // The host joined Wi-Fi. Friends already on the hotspot would be cut off,
      // so only switch by ourselves while nobody depends on it.
      if (_friendsJoined) {
        if (!current.wifiAvailable) {
          _setConnection(ConnectionAppHotspot(current.address, current.credentials, wifiAvailable: true));
        }
        return;
      }
      await _network.stopHotspot();
      if (isClosed) return;
      _setConnection(const ConnectionChecking());
    }

    final address = await _network.findLanAddress();
    final latest = state.connection;
    if (isClosed || latest is ConnectionStartingHotspot || latest is ConnectionAppHotspot) return;
    if (address != null) {
      if (latest is ConnectionReady && latest.address == address) return;
      _setConnection(ConnectionReady(address));
    } else {
      final canCreate = await _network.canCreateHotspot();
      if (isClosed || state.connection is ConnectionStartingHotspot || state.connection is ConnectionAppHotspot) return;
      final failure = switch (latest) {
        ConnectionMissing(:final failure) => failure,
        ConnectionReady(:final hotspotFailure) => hotspotFailure,
        _ => null,
      };
      if (latest is ConnectionMissing && latest.canCreateHotspot == canCreate && latest.failure == failure) return;
      _setConnection(ConnectionMissing(canCreateHotspot: canCreate, failure: failure));
    }
  }

  bool get _friendsJoined => state.room?.players.any((p) => !p.isHost) ?? false;

  /// Starts the app's own hotspot: when there is no Wi-Fi, or when the Wi-Fi
  /// keeps phones from reaching each other.
  Future<void> createHotspot() async {
    final previous = state.connection;
    if (previous is! ConnectionMissing && previous is! ConnectionReady) return;
    _hotspotChosenOverWifi = previous is ConnectionReady;
    _setConnection(const ConnectionStartingHotspot());

    final result = await _network.startHotspot();
    if (isClosed) return;
    switch (result) {
      case HotspotStarted(:final credentials, :final address):
        _setConnection(ConnectionAppHotspot(address, credentials));
      case HotspotFailed(:final failure):
        _hotspotChosenOverWifi = false;
        _setConnection(switch (previous) {
          ConnectionReady(:final address) => ConnectionReady(address, hotspotFailure: failure),
          _ => ConnectionMissing(canCreateHotspot: true, failure: failure),
        });
        await refreshConnection();
    }
  }

  /// Ends the app's hotspot and serves the room on Wi-Fi instead.
  Future<void> switchToWifi() async {
    if (state.connection is! ConnectionAppHotspot) return;
    _hotspotChosenOverWifi = false;
    await _network.stopHotspot();
    if (isClosed) return;
    _setConnection(const ConnectionChecking());
    await refreshConnection();
  }

  Future<void> openPermissionSettings() => _network.openPermissionSettings();

  Future<void> _onHotspotStopped() async {
    if (isClosed || state.connection is! ConnectionAppHotspot) return;
    _hotspotChosenOverWifi = false;
    _setConnection(const ConnectionChecking());
    await refreshConnection();
  }

  void _setConnection(Connection connection) {
    if (isClosed) return;
    emit(state.copyWith(connection: connection, linkCheck: LinkCheck.unknown));
    unawaited(_checkLink());
  }

  /// Opens the join link from this phone, to catch a wrong address early.
  Future<void> _checkLink() async {
    final address = state.address;
    final port = state.port;
    if (address == null || port == null) return;
    final works = await _network.canReach(address, port);
    if (isClosed || state.address != address || state.port != port) return;
    emit(state.copyWith(linkCheck: works ? LinkCheck.works : LinkCheck.broken));
  }

  /// Opens the room with the current settings; [hostName] is how the host shows up in it.
  Future<void> openRoom({required String hostName}) async {
    if (state.opening || state.stage == RoomStage.lobby) return;
    emit(state.copyWith(opening: true));
    final host = _createHost();
    final room = Room(
      code: _newCode(),
      category: state.category,
      namesPerPlayer: state.namesPerPlayer,
      hostName: hostName,
      allowDuplicates: state.allowDuplicates,
      mode: state.mode,
      teamSetup: state.teamSetup,
      familyChat: state.familyChat,
    );
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
      unawaited(_checkLink());
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

  /// Puts one of the host's own names in the bowl. Returns why it was refused, if it was.
  SubmissionError? addHostSecret(String secret) {
    final host = _host;
    if (host == null) return SubmissionError.roomClosed;
    final error = host.room.validateHostSecret(secret);
    if (error == null) host.update((room) => room.withHostSecret(secret));
    return error;
  }

  /// Locks the bowl and returns its slips, or null when the room cannot start yet.
  List<Slip>? startReading() {
    final host = _host;
    if (host == null || !host.room.canStart) return null;
    host.update((room) => room.startReading());
    return host.room.slips;
  }

  /// Deals the bowl into a family game everyone plays on their phone. Returns
  /// the table the host's own screen plays on, or null when the room cannot start yet.
  FamilyTable? startFamily() {
    final host = _host;
    if (host == null || !host.room.canStart || host.room.mode != GameMode.family) return null;
    host.update((room) => room.startFamily(_random));
    return HostFamilyTable(host);
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
    _poll?.cancel();
    for (final sub in _networkSubs) {
      await sub.cancel();
    }
    await _shutDownHost();
    if (state.connection is ConnectionAppHotspot) await _network.stopHotspot();
    return super.close();
  }
}
