import '../../family/domain/family_game.dart';
import '../../family/domain/family_table.dart';
import '../domain/room_host.dart';

/// The family game kept in the served room, so the host's moves and friends'
/// moves land in the same place.
final class HostFamilyTable implements FamilyTable {
  HostFamilyTable(this._host);

  final RoomHost _host;

  @override
  FamilyGame? get game => _host.room.family;

  @override
  Stream<FamilyGame> get changes => _host.changes.map((room) => room.family).where((g) => g != null).cast();

  @override
  void apply(FamilyGame Function(FamilyGame game) move) => _host.update((room) {
    final game = room.family;
    return game == null ? room : room.withFamily(move(game));
  });
}
