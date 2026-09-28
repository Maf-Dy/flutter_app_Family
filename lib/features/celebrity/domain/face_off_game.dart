import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../room/domain/room.dart';
import 'teams.dart';

enum FaceOffPhase {
  /// Teams are being arranged.
  teams,

  /// A name is out; the team on turn picks who wrote it and whether to bet double.
  pick,

  /// The writer is revealed with the points won or lost.
  reveal,

  /// The bowl is empty.
  finished,
}

/// The last guess, shown on the reveal.
@immutable
final class FaceOffGuess {
  const FaceOffGuess({required this.slip, required this.guessedId, required this.doubled, required this.correct});

  final Slip slip;
  final String guessedId;
  final bool doubled;
  final bool correct;

  int get points => FaceOffGame.pointsFor(correct: correct, doubled: doubled);
}

/// Face-off: teams take turns guessing which player on another team wrote
/// the name drawn from the bowl. Each name is played once; a team sure of its
/// answer can bet double.
///
/// Immutable, pure rules.
@immutable
final class FaceOffGame {
  const FaceOffGame._({
    required this.slips,
    required this.teams,
    required this.phase,
    required this.bowl,
    required this.team,
    required this.scores,
    this.lastGuess,
  });

  factory FaceOffGame.start({required List<Slip> slips, required List<List<String>> teams}) {
    assert(teams.length >= 2 && teams.every((t) => t.isNotEmpty), 'Every team needs players');
    return FaceOffGame._(
      slips: List.unmodifiable(slips),
      teams: List.unmodifiable(teams),
      phase: FaceOffPhase.teams,
      bowl: const [],
      team: 0,
      scores: List.unmodifiable(List.filled(teams.length, 0)),
    );
  }

  static const rightPoints = 1;
  static const doubleRightPoints = 2;
  static const doubleWrongPoints = -1;

  static int pointsFor({required bool correct, required bool doubled}) => switch ((correct, doubled)) {
    (true, false) => rightPoints,
    (true, true) => doubleRightPoints,
    (false, false) => 0,
    (false, true) => doubleWrongPoints,
  };

  final List<Slip> slips;

  /// Player ids per team.
  final List<List<String>> teams;
  final FaceOffPhase phase;

  /// Names not played yet. The one on the table is [current].
  final List<Slip> bowl;

  /// The team whose turn it is.
  final int team;

  /// Points per team.
  final List<int> scores;

  /// Shown on the reveal.
  final FaceOffGuess? lastGuess;

  bool get teamsPlayable => teams.length >= 2 && teams.every((t) => t.length >= minTeamSize);

  int? teamOf(String playerId) {
    final i = teams.indexWhere((t) => t.contains(playerId));
    return i < 0 ? null : i;
  }

  /// The name the team on turn is guessing: the first in the bowl that nobody
  /// on that team wrote.
  Slip? get current => phase == FaceOffPhase.pick || phase == FaceOffPhase.reveal ? _firstFor(team) : null;

  /// Everyone the team on turn can choose from: the players on the other teams.
  List<String> get suspects => [
    for (final (i, t) in teams.indexed)
      if (i != team) ...t,
  ];

  /// Teams with the most points; more than one means a draw.
  List<int> get leaders {
    final best = scores.reduce(max);
    return [
      for (final (i, s) in scores.indexed)
        if (s == best) i,
    ];
  }

  FaceOffGame withTeams(List<List<String>> teams) =>
      phase == FaceOffPhase.teams ? _copy(teams: List.unmodifiable(teams)) : this;

  /// Locks the teams, shuffles the bowl and draws the first name.
  FaceOffGame begin(Random random) {
    if (phase != FaceOffPhase.teams || !teamsPlayable) return this;
    return _copy(phase: FaceOffPhase.pick, bowl: [...slips]..shuffle(random))._turnFrom(0);
  }

  /// The team on turn says [guessedId] wrote the name on the table.
  FaceOffGame guess(String guessedId, {bool doubled = false}) {
    final slip = current;
    if (phase != FaceOffPhase.pick || slip == null || !suspects.contains(guessedId)) return this;
    // Two players may have written the same name: either of them counts.
    final key = Room.matchKey(slip.text);
    final correct = slips.any((s) => s.writerId == guessedId && Room.matchKey(s.text) == key);
    final result = FaceOffGuess(slip: slip, guessedId: guessedId, doubled: doubled, correct: correct);
    return _copy(
      phase: FaceOffPhase.reveal,
      lastGuess: result,
      scores: [for (final (i, s) in scores.indexed) i == team ? s + result.points : s],
    );
  }

  /// Takes the played name out and passes the turn to the next team that has
  /// a name to guess. Ends the game when the bowl is empty.
  FaceOffGame next() {
    final played = lastGuess?.slip;
    if (phase != FaceOffPhase.reveal || played == null) return this;
    final bowl = [...this.bowl]..remove(played);
    return _copy(bowl: bowl)._turnFrom((team + 1) % teams.length);
  }

  /// The first team from [start] on that has a name left to guess.
  FaceOffGame _turnFrom(int start) {
    for (var step = 0; step < teams.length; step++) {
      final t = (start + step) % teams.length;
      if (_firstFor(t) != null) return _copy(phase: FaceOffPhase.pick, team: t);
    }
    return _copy(phase: FaceOffPhase.finished);
  }

  Slip? _firstFor(int team) {
    for (final slip in bowl) {
      if (!teams[team].contains(slip.writerId)) return slip;
    }
    return null;
  }

  FaceOffGame _copy({
    List<List<String>>? teams,
    FaceOffPhase? phase,
    List<Slip>? bowl,
    int? team,
    List<int>? scores,
    FaceOffGuess? lastGuess,
  }) => FaceOffGame._(
    slips: slips,
    teams: teams ?? this.teams,
    phase: phase ?? this.phase,
    bowl: bowl == null ? this.bowl : List.unmodifiable(bowl),
    team: team ?? this.team,
    scores: scores == null ? this.scores : List.unmodifiable(scores),
    lastGuess: lastGuess ?? this.lastGuess,
  );
}
