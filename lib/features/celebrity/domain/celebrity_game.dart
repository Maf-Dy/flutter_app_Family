import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../room/domain/room.dart';
import 'teams.dart';

enum CelebrityPhase {
  /// Teams are being arranged.
  teams,

  /// Before the first turn: the rules are shown.
  intro,

  /// Hand the phone to the next clue-giver.
  handOff,

  /// The clock runs; the clue-giver works through the bowl.
  playing,

  /// Time ran out or the bowl emptied; the turn's points are shown.
  turnOver,

  /// The bowl is empty: every name was guessed.
  finished,
}

/// Celebrity, also known as Salad Bowl: teams take turns guessing the names in
/// the bowl. Each name is guessed once; the game ends when the bowl is empty.
///
/// Immutable, pure rules; the clock lives in the state holder.
@immutable
final class CelebrityGame {
  const CelebrityGame._({
    required this.slips,
    required this.teams,
    required this.phase,
    required this.bowl,
    required this.team,
    required this.givers,
    required this.totals,
    this.turnPoints = 0,
  });

  factory CelebrityGame.start({required List<Slip> slips, required List<List<String>> teams}) {
    assert(teams.length >= 2 && teams.every((t) => t.isNotEmpty), 'Every team needs players');
    return CelebrityGame._(
      slips: List.unmodifiable(slips),
      teams: List.unmodifiable(teams),
      phase: CelebrityPhase.teams,
      bowl: const [],
      team: 0,
      givers: List.unmodifiable(List.filled(teams.length, 0)),
      totals: List.unmodifiable(List.filled(teams.length, 0)),
    );
  }

  final List<Slip> slips;

  /// Player ids per team.
  final List<List<String>> teams;
  final CelebrityPhase phase;

  /// Names still to guess; the first one is on screen while playing.
  final List<Slip> bowl;

  /// The team whose turn it is.
  final int team;

  /// Per team, how many turns its players have taken, so clue-givers rotate.
  final List<int> givers;

  /// Points per team: one per name guessed.
  final List<int> totals;

  /// Names guessed in the current turn.
  final int turnPoints;

  Slip? get current => phase == CelebrityPhase.playing && bowl.isNotEmpty ? bowl.first : null;
  String get giverId => teams[team][givers[team] % teams[team].length];
  bool get bowlEmpty => bowl.isEmpty;

  /// Teams with the highest total; more than one means a draw.
  List<int> get leaders {
    final best = totals.reduce(max);
    return [
      for (final (i, total) in totals.indexed)
        if (total == best) i,
    ];
  }

  bool get teamsPlayable => teams.length >= 2 && teams.every((t) => t.length >= minTeamSize);

  CelebrityGame withTeams(List<List<String>> teams) =>
      phase == CelebrityPhase.teams ? _copy(teams: List.unmodifiable(teams)) : this;

  /// Locks the teams and fills the bowl.
  CelebrityGame begin(Random random) {
    if (phase != CelebrityPhase.teams || !teamsPlayable) return this;
    return _copy(
      phase: CelebrityPhase.intro,
      bowl: _shuffled(random),
      givers: List.unmodifiable(List.filled(teams.length, 0)),
    );
  }

  CelebrityGame toHandOff() => phase == CelebrityPhase.intro ? _copy(phase: CelebrityPhase.handOff) : this;

  CelebrityGame startTurn() =>
      phase == CelebrityPhase.handOff ? _copy(phase: CelebrityPhase.playing, turnPoints: 0) : this;

  /// Whether the turn ended because this team emptied the bowl, not the clock.
  bool get emptiedBowl => phase == CelebrityPhase.turnOver && bowlEmpty;

  /// The team guessed the name on screen.
  CelebrityGame gotIt() {
    if (current == null) return this;
    final next = bowl.sublist(1);
    return _copy(
      bowl: next,
      turnPoints: turnPoints + 1,
      totals: [for (final (i, p) in totals.indexed) i == team ? p + 1 : p],
      phase: next.isEmpty ? CelebrityPhase.turnOver : CelebrityPhase.playing,
    );
  }

  /// Puts the name on screen back at the bottom of the bowl.
  CelebrityGame skip() {
    if (current == null || bowl.length < 2) return this;
    return _copy(bowl: [...bowl.sublist(1), bowl.first]);
  }

  CelebrityGame timeUp() => phase == CelebrityPhase.playing ? _copy(phase: CelebrityPhase.turnOver) : this;

  /// After a turn: the next team's clue-giver, or the end of the game when the bowl is empty.
  ///
  /// The name left on screen at time-up is shuffled back in, so the next team
  /// doesn't start on a name it just heard every clue for.
  CelebrityGame nextTurn(Random random) {
    if (phase != CelebrityPhase.turnOver) return this;
    final givers = List<int>.unmodifiable([for (final (i, g) in this.givers.indexed) i == team ? g + 1 : g]);
    if (bowlEmpty) return _copy(phase: CelebrityPhase.finished, givers: givers);
    return _copy(
      phase: CelebrityPhase.handOff,
      team: (team + 1) % teams.length,
      givers: givers,
      bowl: _reshuffled(random),
      turnPoints: 0,
    );
  }

  /// The names left, shuffled, with the one last on screen kept off the top.
  List<Slip> _reshuffled(Random random) {
    final last = bowl.first;
    final next = [...bowl]..shuffle(random);
    if (next.length > 1 && identical(next.first, last)) next.add(next.removeAt(0));
    return next;
  }

  List<Slip> _shuffled(Random random) => List.unmodifiable([...slips]..shuffle(random));

  CelebrityGame _copy({
    List<List<String>>? teams,
    CelebrityPhase? phase,
    List<Slip>? bowl,
    int? team,
    List<int>? givers,
    List<int>? totals,
    int? turnPoints,
  }) => CelebrityGame._(
    slips: slips,
    teams: teams ?? this.teams,
    phase: phase ?? this.phase,
    bowl: bowl == null ? this.bowl : List.unmodifiable(bowl),
    team: team ?? this.team,
    givers: givers ?? this.givers,
    totals: totals == null ? this.totals : List.unmodifiable(totals),
    turnPoints: turnPoints ?? this.turnPoints,
  );
}
