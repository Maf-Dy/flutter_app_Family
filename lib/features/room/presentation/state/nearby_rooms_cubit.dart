import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/room_beacon.dart';

/// Opens a room's join link, in the browser. Returns false when nothing could open it.
typedef OpenRoomLink = Future<bool> Function(Uri url);

/// The rooms open on this network, for "Join a game".
final class NearbyRoomsState {
  const NearbyRoomsState({this.rooms = const [], this.failed = false});

  final List<NearbyRoom> rooms;

  /// This phone could not listen for rooms at all.
  final bool failed;
}

class NearbyRoomsCubit extends Cubit<NearbyRoomsState> {
  NearbyRoomsCubit(RoomFinder finder) : super(const NearbyRoomsState()) {
    _sub = finder.watch().listen(
      (rooms) => emit(NearbyRoomsState(rooms: rooms)),
      onError: (Object _) => emit(const NearbyRoomsState(failed: true)),
    );
  }

  late final StreamSubscription<List<NearbyRoom>> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
