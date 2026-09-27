import '../room/domain/room.dart';
import 'domain/family_table.dart';

/// What the host's family screen needs: the shared table, and who the host is in it.
final class FamilyArgs {
  const FamilyArgs({required this.category, required this.table, required this.me});

  final GameCategory category;
  final FamilyTable table;

  /// The host's id in the game, or null when they put no names in and just watch.
  final String? me;
}
