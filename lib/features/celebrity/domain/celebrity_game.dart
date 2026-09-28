import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../room/domain/room.dart';
import 'teams.dart';

/// The three rounds, played with the same names each time.
enum CelebrityRound {
  /// Say anything except the name itself.
  describe,

  /// Exactly one word.
  oneWord,

  /// No words at all: act it out.
  actOut,
}

enum CelebrityPhase {
  /// Teams are being arranged.
  teams,

  /// Before each round: its rule is shown.
  roundIntro,

  /// Hand the phone to the next clue-giver.
  handOff,

  /// The clock runs; the clue-giver works through the bowl.
  playing,

  /// Time ran out or the bowl emptied; the turn's points are shown.
  turnOver,

  /// All three rounds are done.
  finished,
}

/// Celebrity, also known as Salad Bowl: teams take turns guessing the names in
/// the bowl, over three rounds with stricter clues each time.
///
/// Immutable, pure rules; the clock lives in the state holder.
@immutable
final class CelebrityGame {
  const CelebrityGame._({
    required this.slips,
    required this.teams,
    required this.phase,
    required this.round,
    required this.bowl,
    required this.team,
    required this.givers,
    required this.scores,
    this.turnPoints = 0,
  });

  factory CelebrityGame.start({required List<Slip> slips, required List<List<String>> teams}) {
    assert(teams.length >= 2 && teams.every((t) => t.isNotEmpty), 'Every team needs players');
    return CelebrityGame._(
      slips: List.unmodifiable(slips),
      teams: List.unmodifiable(teams),
      phase: CelebrityPhase.teams,
      round: CelebrityRound.describe,
      bowl: const [],
      team: 0,
      givers: List.unmodifiable(List.filled(teams.length, 0)),
      scores: List.unmodifiable([for (final _ in teams) List<int>.unmodifiable(List.filled(3, 0))]),
    );
  }

  final List<Slip> slips;

  /// Player ids per team.
  final List<List<String>> teams;
  final CelebrityPhase phase;
  final CelebrityRound round;

  /// Names still to guess this round; the first one is on screen while playing.
  final List<Slip> bowl;

  /// The team whose turn it is.
  final int team;

  /// Per team, how many turns its players have taken, so clue-givers rotate.
  final List<int> givers;

  /// Points per team per round.
  final List<List<int>> scores;

  /// Names guessed in the current turn.
  final int turnPoints;

  Slip? get current => phase == CelebrityPhase.playing && bowl.isNotEmpty ? bowl.first : null;
  String get giverId => teams[team][givers[team] % teams[team].length];
  bool get bowlEmpty => bowl.isEmpty;
  bool get isLastRound => round == CelebrityRound.values.last;
  List<int> get totals => [for (final s in scores) s.fold(0, (a, b) => a + b)];

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

  /// Locks the teams and fills the bowl for the first round.
  CelebrityGame begin(Random random) {
    if (phase != CelebrityPhase.teams || !teamsPlayable) return this;
    return _copy(
      phase: CelebrityPhase.roundIntro,
      bowl: _shuffled(random),
      givers: List.unmodifiable(List.filled(teams.length, 0)),
    );
  }

  CelebrityGame toHandOff() => phase == CelebrityPhase.roundIntro ? _copy(phase: CelebrityPhase.handOff) : this;

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
      scores: [
        for (final (i, s) in scores.indexed)
          i == team ? List<int>.unmodifiable([for (final (r, p) in s.indexed) r == round.index ? p + 1 : p]) : s,
      ],
      phase: next.isEmpty ? CelebrityPhase.turnOver : CelebrityPhase.playing,
    );
  }

  /// Puts the name on screen back at the bottom of the bowl.
  CelebrityGame skip() {
    if (current == null || bowl.length < 2) return this;
    return _copy(bowl: [...bowl.sublist(1), bowl.first]);
  }

  CelebrityGame timeUp() => phase == CelebrityPhase.playing ? _copy(phase: CelebrityPhase.turnOver) : this;

  /// After a turn: the next team's clue-giver, or the next round when the bowl is empty.
  ///
  /// Turns always pass to the next team, even when a team empties the bowl
  /// early, so one quick clue-giver can't play every round alone. The name left
  /// on screen at time-up is shuffled back in, so the next team doesn't start
  /// on a name it just heard every clue for.
  CelebrityGame nextTurn(Random random) {
    if (phase != CelebrityPhase.turnOver) return this;
    final givers = List<int>.unmodifiable([for (final (i, g) in this.givers.indexed) i == team ? g + 1 : g]);
    final nextTeam = (team + 1) % teams.length;
    if (!bowlEmpty) {
      return _copy(
        phase: CelebrityPhase.handOff,
        team: nextTeam,
        givers: givers,
        bowl: _reshuffled(random),
        turnPoints: 0,
      );
    }
    if (isLastRound) return _copy(phase: CelebrityPhase.finished, givers: givers);
    return _copy(
      phase: CelebrityPhase.roundIntro,
      round: CelebrityRound.values[round.index + 1],
      bowl: _shuffled(random),
      team: nextTeam,
      givers: givers,
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
    CelebrityRound? round,
    List<Slip>? bowl,
    int? team,
    List<int>? givers,
    List<List<int>>? scores,
    int? turnPoints,
  }) => CelebrityGame._(
    slips: slips,
    teams: teams ?? this.teams,
    phase: phase ?? this.phase,
    round: round ?? this.round,
    bowl: bowl == null ? this.bowl : List.unmodifiable(bowl),
    team: team ?? this.team,
    givers: givers ?? this.givers,
    scores: scores == null ? this.scores : List.unmodifiable(scores),
    turnPoints: turnPoints ?? this.turnPoints,
  );
}
