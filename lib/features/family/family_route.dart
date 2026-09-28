import 'package:flutter/widgets.dart';

import '../room/domain/room.dart';
import 'domain/family_table.dart';

/// What the host's family screen needs: the shared table, and who the host is in it.
final class FamilyArgs {
  const FamilyArgs({
    required this.category,
    required this.table,
    required this.me,
    this.joinOrder = const [],
    this.joinCodes,
  });

  final GameCategory category;
  final FamilyTable table;

  /// The host's id in the game, or null when they put no names in and just watch.
  final String? me;

  /// Everyone in the room in join order, so players keep their lobby colours.
  final List<String> joinOrder;

  /// The room's join codes, kept up to date, so a friend who dropped out can
  /// scan back in, even after the host's phone changed network.
  final WidgetBuilder? joinCodes;
}
