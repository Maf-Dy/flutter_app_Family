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

  test('friends who all pick the same team still get a game the host can start', () {
    final cubit = CelebrityCubit(
      CelebrityArgs(
        category: const GameCategory.preset(PresetCategory.famousPeople),
        slips: slips,
        players: [for (final id in teams.expand((t) => t)) (id: id, name: id.toUpperCase(), team: 0)],
        setup: const TeamSetup(pick: TeamPick.players),
      ),
      random: Random(7),
      runClock: false,
    );
    expect(cubit.state.game.teamsPlayable, isTrue);
    cubit.begin();
    expect(cubit.state.game.phase, CelebrityPhase.roundIntro);
    cubit.close();
  });

  CelebrityCubit cubitFor({int turnSeconds = 60, int seed = 8}) => CelebrityCubit(
    CelebrityArgs(
      category: const GameCategory.preset(PresetCategory.famousPeople),
      slips: slips,
      players: [for (final id in teams.expand((t) => t)) (id: id, name: id.toUpperCase(), team: null)],
      setup: TeamSetup(pick: TeamPick.host, turnSeconds: turnSeconds),
    ),
    random: Random(seed),
    runClock: false,
  );

  test('emptying the bowl early passes the next round to the other team', () {
    var game = started().toHandOff().startTurn();
    final firstGiver = game.giverId;
    while (game.phase == CelebrityPhase.playing) {
      game = game.gotIt();
    }
    expect(game.emptiedBowl, isTrue);
    game = game.nextTurn(Random(2));
    expect(game.round, CelebrityRound.oneWord);
    expect(game.team, 1, reason: 'the other team opens the next round');
    expect(game.bowl, hasLength(slips.length), reason: 'every name goes back in');
    // Round 3 opens with team 0 again, but its next clue-giver, not the same one.
    game = game.toHandOff().startTurn();
    while (game.phase == CelebrityPhase.playing) {
      game = game.gotIt();
    }
    game = game.nextTurn(Random(3));
    expect(game.round, CelebrityRound.actOut);
    expect(game.team, 0);
    expect(game.giverId, isNot(firstGiver));
  });

  test('the name on screen at time-up is shuffled back in, not handed to the next team first', () {
    for (var seed = 0; seed < 20; seed++) {
      var game = started().toHandOff().startTurn();
      final onScreen = game.current!;
      game = game.timeUp().nextTurn(Random(seed));
      expect(game.bowl, hasLength(4));
      expect(identical(game.bowl.first, onScreen), isFalse);
    }
  });

  test('a team of one cannot play: someone has to guess', () {
    final game = CelebrityGame.start(
      slips: slips,
      teams: [
        ['p0'],
        ['p1', 'p2', 'p3'],
      ],
    );
    expect(game.teamsPlayable, isFalse);
    expect(game.begin(Random(1)).phase, CelebrityPhase.teams);
  });

  test('pausing stops the clock and the buttons until the turn carries on', () {
    final cubit = cubitFor(turnSeconds: 10)
      ..begin()
      ..toHandOff()
      ..startTurn()
      ..tick()
      ..pause()
      ..tick()
      ..tick();
    expect(cubit.state.paused, isTrue);
    expect(cubit.state.secondsLeft, 9);
    cubit.gotIt();
    expect(cubit.state.game.turnPoints, 0);
    cubit
      ..resume()
      ..tick()
      ..gotIt();
    expect(cubit.state.secondsLeft, 8);
    expect(cubit.state.game.turnPoints, 1);
    cubit.close();
  });

  test('the cubit gives every turn the full clock, even after a team empties the bowl early', () {
    final cubit = cubitFor(turnSeconds: 30)
      ..begin()
      ..toHandOff()
      ..startTurn();
    for (var i = 0; i < 5; i++) {
      cubit.tick();
    }
    while (cubit.state.game.phase == CelebrityPhase.playing) {
      cubit.gotIt();
    }
    cubit
      ..nextTurn()
      ..toHandOff()
      ..startTurn();
    expect(cubit.state.secondsLeft, 30);
    expect(cubit.state.game.team, 1);
    cubit.close();
  });

  test('when friends pick teams, the host can still move someone to fix a short team', () {
    final cubit = CelebrityCubit(
      CelebrityArgs(
        category: const GameCategory.preset(PresetCategory.famousPeople),
        slips: slips,
        players: [for (final id in teams.expand((t) => t)) (id: id, name: id.toUpperCase(), team: 0)],
        setup: const TeamSetup(pick: TeamPick.players),
      ),
      random: Random(7),
      runClock: false,
    );
    final before = cubit.state.game.teams;
    cubit.movePlayer(before[0].first);
    expect(cubit.state.game.teams, isNot(before));
    cubit.close();
  });
}
