import 'package:flutter/foundation.dart';

import '../../room/domain/room.dart';

/// Why a turn on the passed-around phone was refused. Wording is chosen at the UI edge.
enum PassError {
  missingName,

  /// Someone already put their names in this round under that name.
  nameTaken,
  missingSecret,
  tooLong,

  /// Someone already wrote this name, and the game asks for different names.
  duplicate,

  /// [Room.maxPlayers] have already played.
  full,
}

/// The bowl filled on one phone passed around the table.
///
/// A thin layer over [Room], so the same rules check the names as on the join
/// page. Nobody types a list of players: each person adds their own name on
/// their turn. After a round, everyone is remembered, and typing the same name
/// again (or tapping it) keeps that player's colour.
@immutable
final class PassBowl {
  PassBowl.start({
    required GameCategory category,
    required int namesPerPlayer,
    required bool allowDuplicates,
    required GameMode mode,
    required TeamSetup teamSetup,
  }) : room = Room(
         code: '',
         category: category,
         namesPerPlayer: namesPerPlayer,
         hostName: '',
         allowDuplicates: allowDuplicates,
         mode: mode,
         teamSetup: teamSetup,
       );

  const PassBowl._(this.room);

  final Room room;

  /// Everyone who has played on this phone, in the order they first played.
  List<Player> get players => room.players;

  /// Who has put their names in this round.
  List<Player> get playersIn => room.playersIn;

  /// Players from earlier rounds who haven't had their turn yet this round.
  List<Player> get waiting => [
    for (final p in room.players)
      if (!p.hasSubmitted) p,
  ];

  int get requiredPlayers => room.requiredPlayers;
  bool get canStart => room.canStart;
  int get slipCount => room.slipCount;
  List<Slip> get slips => room.slips;

  /// Checks one person's turn. Returns null when it can go in the bowl.
  PassError? validate({required String name, required List<String> secrets}) {
    final clean = Room.tidy(name);
    if (clean.isEmpty) return PassError.missingName;
    final known = _playerNamed(clean);
    if (known != null && known.hasSubmitted) return PassError.nameTaken;
    if (known == null && room.players.length >= Room.maxPlayers) return PassError.full;
    return switch (room.validate(name: clean, secrets: secrets, playerId: known?.id)) {
      null => null,
      SubmissionError.missingName => PassError.missingName,
      SubmissionError.missingSecret => PassError.missingSecret,
      SubmissionError.tooLong => PassError.tooLong,
      SubmissionError.duplicate => PassError.duplicate,
      SubmissionError.nameTaken => PassError.nameTaken,
      // Only reachable if the bowl were closed or teams were picked here; neither happens on one phone.
      SubmissionError.roomClosed || SubmissionError.invalidTeam => PassError.full,
    };
  }

  /// Drops one person's names in the bowl. Call [validate] first.
  PassBowl submit({required String name, required List<String> secrets}) {
    assert(validate(name: name, secrets: secrets) == null, 'Validate the turn first');
    final clean = Room.tidy(name);
    final id = _playerNamed(clean)?.id ?? 'p${room.players.length + 1}';
    return PassBowl._(room.withSubmission(playerId: id, name: clean, secrets: secrets));
  }

  /// Same players, empty bowl.
  PassBowl nextRound() => PassBowl._(room.nextRound());

  Player? _playerNamed(String name) {
    final key = Room.matchKey(name);
    for (final p in room.players) {
      if (Room.matchKey(p.name) == key) return p;
    }
    return null;
  }
}
