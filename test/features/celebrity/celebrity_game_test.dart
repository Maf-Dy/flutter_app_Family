import 'dart:math';

import 'package:family_game/features/celebrity/celebrity_route.dart';
import 'package:family_game/features/celebrity/domain/celebrity_game.dart';
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

  CelebrityGame started() => CelebrityGame.start(slips: slips, teams: teams).begin(Random(1));

  test('plays three rounds with the same names, alternating teams and clue-givers', () {
    var game = started();
    expect(game.phase, CelebrityPhase.roundIntro);
    for (final round in CelebrityRound.values) {
      expect(game.round, round);
      expect(game.bowl, hasLength(4));
      game = game.toHandOff().startTurn();
      // Team guesses everything in one turn.
      while (game.phase == CelebrityPhase.playing) {
        game = game.gotIt();
      }
      expect(game.phase, CelebrityPhase.turnOver);
      expect(game.bowlEmpty, isTrue);
      game = game.nextTurn(Random(2));
    }
    expect(game.phase, CelebrityPhase.finished);
    // Teams alternate: round 1 team 0, round 2 team 1, round 3 team 0.
    expect(game.scores, [
      [4, 0, 4],
      [0, 4, 0],
    ]);
    expect(game.totals, [8, 4]);
    expect(game.leaders, [0]);
  });

  test('time running out passes the turn with the rest of the bowl', () {
    var game = started().toHandOff().startTurn();
    expect(game.giverId, 'p0');
    game = game.gotIt().timeUp();
    expect(game.turnPoints, 1);
    game = game.nextTurn(Random(3));
    expect(game.phase, CelebrityPhase.handOff);
    expect(game.team, 1);
    expect(game.giverId, 'p2');
    expect(game.bowl, hasLength(3));
    // Team 0's next turn goes to its other player.
    game = game.startTurn().timeUp().nextTurn(Random(4));
    expect(game.giverId, 'p1');
  });

  test('skip moves the name to the bottom, never losing it', () {
    var game = started().toHandOff().startTurn();
    final first = game.current;
    game = game.skip();
    expect(game.current, isNot(first));
    expect(game.bowl.last, first);
    expect(game.bowl, hasLength(4));
  });

  test('a draw has several leaders', () {
    var game = started().toHandOff().startTurn().gotIt().timeUp().nextTurn(Random(5));
    game = game.startTurn().gotIt().timeUp();
    expect(game.leaders, [0, 1]);
  });

  test('the clock counts down and ends the turn', () {
    final cubit = CelebrityCubit(
      CelebrityArgs(
        category: const GameCategory.preset(PresetCategory.famousPeople),
        slips: slips,
        players: [for (final id in teams.expand((t) => t)) (id: id, name: id.toUpperCase(), team: null)],
        setup: const TeamSetup(turnSeconds: 3),
      ),
      random: Random(6),
      runClock: false,
    )..begin();
    cubit
      ..toHandOff()
      ..startTurn()
      ..tick();
    expect(cubit.state.secondsLeft, 2);
    cubit
      ..tick()
      ..tick();
    expect(cubit.state.game.phase, CelebrityPhase.turnOver);
    expect(cubit.state.secondsLeft, 0);
    cubit.close();
  });
}
