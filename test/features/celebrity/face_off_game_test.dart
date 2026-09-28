import 'dart:math';

import 'package:family_game/features/celebrity/celebrity_route.dart';
import 'package:family_game/features/celebrity/domain/face_off_game.dart';
import 'package:family_game/features/celebrity/presentation/state/celebrity_cubit.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final slips = [
    for (final (i, text) in ['Messi', 'Fairuz', 'Adele', 'Mr. Bean'].indexed)
      Slip(text: text, writerId: 'p$i', writerName: 'P$i'),
  ];
  final teams = [
    ['p0', 'p1'],
    ['p2', 'p3'],
  ];

  FaceOffGame started({List<Slip>? bowl, List<List<String>>? split}) =>
      FaceOffGame.start(slips: bowl ?? slips, teams: split ?? teams).begin(Random(1));

  /// Guesses the writer of every name right, until the bowl is empty.
  FaceOffGame playOut(FaceOffGame game) {
    while (game.phase == FaceOffPhase.pick) {
      game = game.guess(game.current!.writerId).next();
    }
    return game;
  }

  test('each name is played once, by a team that did not write it, then the game ends', () {
    var game = started();
    expect(game.phase, FaceOffPhase.pick);
    final seen = <String>[];
    while (game.phase == FaceOffPhase.pick) {
      final current = game.current!;
      expect(game.teams[game.team], isNot(contains(current.writerId)));
      expect(game.suspects, isNot(contains(game.teams[game.team].first)));
      seen.add(current.text);
      game = game.guess(current.writerId).next();
    }
    expect(game.phase, FaceOffPhase.finished);
    expect(seen, unorderedEquals(['Messi', 'Fairuz', 'Adele', 'Mr. Bean']));
    expect(game.scores, [2, 2]);
    expect(game.leaders, [0, 1]);
  });

  test('turns alternate between the teams', () {
    var game = started();
    expect(game.team, 0);
    game = game.guess(game.current!.writerId).next();
    expect(game.team, 1);
    game = game.guess(game.suspects.first).next();
    expect(game.team, 0);
  });

  test('a plain guess is +1 or nothing; a double bet is +2 or -1', () {
    var game = started();
    final right = game.current!.writerId;
    final wrong = game.suspects.firstWhere((id) => id != right);
    expect(game.guess(wrong).scores, [0, 0]);
    expect(game.guess(right).scores, [1, 0]);
    expect(game.guess(right, doubled: true).scores, [2, 0]);
    game = game.guess(wrong, doubled: true);
    expect(game.scores, [-1, 0]);
    expect(game.lastGuess!.correct, isFalse);
    expect(game.lastGuess!.doubled, isTrue);
    expect(game.lastGuess!.points, -1);
  });

  test('only players on the other teams can be picked, and only once per name', () {
    final game = started();
    expect(game.guess('p0'), same(game), reason: 'own team');
    expect(game.guess('nobody'), same(game));
    final revealed = game.guess('p2');
    expect(revealed.guess('p3'), same(revealed), reason: 'already guessed');
  });

  test('the same name written by two players: either writer counts', () {
    final bowl = [
      const Slip(text: 'Messi', writerId: 'p2', writerName: 'P2'),
      const Slip(text: 'messi ', writerId: 'p3', writerName: 'P3'),
    ];
    final game = started(bowl: bowl);
    expect(game.team, 0);
    for (final writer in ['p2', 'p3']) {
      expect(game.guess(writer).lastGuess!.correct, isTrue);
    }
  });

  test("a team with nothing left to guess is skipped, and the game ends when the bowl's empty", () {
    // Only team 1 wrote names, so team 0 guesses every one of them.
    final bowl = [
      for (final (i, text) in ['Adele', 'Shakira', 'Fairuz'].indexed)
        Slip(text: text, writerId: 'p${2 + i % 2}', writerName: 'P'),
    ];
    var game = started(bowl: bowl);
    for (var i = 0; i < 3; i++) {
      expect(game.team, 0);
      game = game.guess(game.current!.writerId).next();
    }
    expect(game.phase, FaceOffPhase.finished);
    expect(game.scores, [3, 0]);
  });

  test('three teams: the suspects are everyone not on the team whose turn it is', () {
    final three = [
      ['p0', 'p1'],
      ['p2', 'p3'],
      ['p4', 'p5'],
    ];
    final bowl = [for (var i = 0; i < 6; i++) Slip(text: 'Name $i', writerId: 'p$i', writerName: 'P$i')];
    final game = started(bowl: bowl, split: three);
    expect(game.suspects, ['p2', 'p3', 'p4', 'p5']);
    final done = playOut(game);
    expect(done.phase, FaceOffPhase.finished);
    expect(done.scores.reduce((a, b) => a + b), 6);
  });

  test("teams can't start short-handed", () {
    final short = FaceOffGame.start(
      slips: slips,
      teams: [
        ['p0'],
        ['p1', 'p2', 'p3'],
      ],
    );
    expect(short.teamsPlayable, isFalse);
    expect(short.begin(Random(1)), same(short));
  });

  test('the cubit arranges teams, takes guesses and moves on', () {
    final cubit = CelebrityCubit(
      CelebrityArgs(
        category: const GameCategory.preset(PresetCategory.famousPeople),
        slips: slips,
        players: [for (final id in teams.expand((t) => t)) (id: id, name: id.toUpperCase(), team: 0)],
        setup: const TeamSetup(pick: TeamPick.players),
      ),
      random: Random(7),
    );
    // Friends who all picked the same team still get a game the host can start.
    expect(cubit.state.game.teamsPlayable, isTrue);
    cubit.begin();
    expect(cubit.state.game.phase, FaceOffPhase.pick);
    final step = cubit.state.step;
    cubit.guess(cubit.state.game.current!.writerId, doubled: true);
    expect(cubit.state.game.phase, FaceOffPhase.reveal);
    expect(cubit.state.step, step + 1);
    expect(cubit.state.game.scores.reduce((a, b) => a + b), 2);
    cubit.next();
    expect(cubit.state.game.phase, FaceOffPhase.pick);
    cubit.close();
  });
}
