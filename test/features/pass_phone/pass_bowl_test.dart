import 'package:family_game/core/router/game_exit.dart';
import 'package:family_game/features/pass_phone/domain/pass_bowl.dart';
import 'package:family_game/features/pass_phone/presentation/state/pass_phone_cubit.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

PassBowl bowl({int names = 1, bool allowDuplicates = true, GameMode mode = GameMode.classic}) => PassBowl.start(
  category: const GameCategory.preset(PresetCategory.footballers),
  namesPerPlayer: names,
  allowDuplicates: allowDuplicates,
  mode: mode,
  teamSetup: const TeamSetup(),
);

void main() {
  group('PassBowl', () {
    test('each person adds their own name with their secret names', () {
      var b = bowl(names: 2);
      b = b.submit(name: ' Sara ', secrets: ['Salah', 'Abou Trika']);
      b = b.submit(name: 'Omar', secrets: ['Messi', 'Ronaldo']);
      expect([for (final p in b.playersIn) p.name], ['Sara', 'Omar']);
      expect(b.slipCount, 4);
      expect({for (final s in b.slips) s.writerName}, {'Sara', 'Omar'});
    });

    test('two players cannot share a name, whatever the spelling', () {
      final b = bowl().submit(name: 'Sara', secrets: ['Salah']);
      expect(b.validate(name: 'sara', secrets: ['Messi']), PassError.nameTaken);
      expect(b.validate(name: 'Sara M', secrets: ['Messi']), isNull);
    });

    test('checks the names like the join page', () {
      final b = bowl(names: 2, allowDuplicates: false).submit(name: 'Sara', secrets: ['Salah', 'Messi']);
      expect(b.validate(name: '  ', secrets: ['a', 'b']), PassError.missingName);
      expect(b.validate(name: 'Omar', secrets: ['a', '']), PassError.missingSecret);
      expect(b.validate(name: 'Omar', secrets: ['a', 'x' * 61]), PassError.tooLong);
      expect(b.validate(name: 'Omar', secrets: ['salah', 'Pele']), PassError.duplicate);
      expect(
        bowl(names: 2).submit(name: 'Sara', secrets: ['Salah', 'x']).validate(name: 'Omar', secrets: ['Salah', 'y']),
        isNull,
      );
    });

    test('needs 3 players for Classic and 2 per team for Team race', () {
      var classic = bowl();
      var race = bowl(mode: GameMode.celebrity, names: 3);
      for (final name in ['A', 'B', 'C']) {
        classic = classic.submit(name: name, secrets: [name]);
        race = race.submit(name: name, secrets: ['$name 1', '$name 2', '$name 3']);
      }
      expect(classic.canStart, isTrue);
      expect(race.canStart, isFalse);
      expect(race.submit(name: 'D', secrets: ['D 1', 'D 2', 'D 3']).canStart, isTrue);
    });

    test('Team race needs 12 names in the bowl, however many play', () {
      var race = bowl(mode: GameMode.celebrity, names: 2);
      for (final name in ['A', 'B', 'C', 'D', 'E']) {
        race = race.submit(name: name, secrets: ['$name 1', '$name 2']);
      }
      expect(race.room.slipsNeeded, 2);
      expect(race.canStart, isFalse);
      race = race.submit(name: 'F', secrets: ['F 1', 'F 2']);
      expect(race.room.slipsNeeded, 0);
      expect(race.canStart, isTrue);
    });

    test('a new round keeps everyone, empties the bowl, and a returning name keeps its colour', () {
      var b = bowl();
      for (final name in ['Sara', 'Omar', 'Nour']) {
        b = b.submit(name: name, secrets: [name]);
      }
      final ids = [for (final p in b.players) p.id];
      b = b.nextRound();
      expect(b.slipCount, 0);
      expect([for (final p in b.waiting) p.name], ['Sara', 'Omar', 'Nour']);
      b = b.submit(name: 'omar', secrets: ['Zidane']);
      expect(b.players[1].id, ids[1]);
      expect(b.players, hasLength(3));
      expect(b.validate(name: 'Omar', secrets: ['x']), PassError.nameTaken);
      expect(b.validate(name: 'Sara', secrets: ['x']), isNull);
    });

    test('the bowl stops at the room limit', () {
      var b = bowl();
      for (var i = 0; i < Room.maxPlayers; i++) {
        b = b.submit(name: 'P$i', secrets: ['S$i']);
      }
      expect(b.validate(name: 'Late', secrets: ['x']), PassError.full);
    });
  });

  group('PassPhoneCubit', () {
    PassPhoneCubit threeIn({GameMode mode = GameMode.classic}) {
      final cubit = PassPhoneCubit()
        ..setMode(mode)
        ..begin();
      for (final name in ['Sara', 'Omar', 'Nour']) {
        cubit.submit(
          name: name,
          secrets: cubit.state.namesPerPlayer == 1
              ? [name]
              : [for (var i = 1; i <= cubit.state.namesPerPlayer; i++) '$name $i'],
        );
        cubit.next();
      }
      cubit.cancelTurn();
      return cubit;
    }

    test('hides each turn behind the hand-off screen', () {
      final cubit = PassPhoneCubit()..begin();
      expect(cubit.state.stage, PassStage.typing);
      expect(cubit.submit(name: 'Sara', secrets: ['Salah']), isNull);
      expect(cubit.state.stage, PassStage.passed);
      expect(cubit.state.lastName, 'Sara');
      cubit.next();
      expect(cubit.state.stage, PassStage.typing);
      expect(cubit.submit(name: 'sara', secrets: ['Messi']), PassError.nameTaken);
      expect(cubit.state.stage, PassStage.typing);
    });

    test('cannot start before enough players are in', () {
      final cubit = PassPhoneCubit()..begin();
      cubit.submit(name: 'Sara', secrets: ['Salah']);
      cubit.everyoneIn();
      expect(cubit.state.stage, PassStage.passed);
      expect(cubit.roundArgs(), isNull);
    });

    test('the family game is not offered on one phone', () {
      final cubit = PassPhoneCubit()..setMode(GameMode.family);
      expect(cubit.state.mode, GameMode.classic);
    });

    test('friends picking teams becomes random, since there is no join page', () {
      final cubit = PassPhoneCubit()..setTeamSetup(const TeamSetup(pick: TeamPick.players));
      expect(cubit.state.teamSetup.pick, TeamPick.random);
    });

    test('Classic goes to a reader, then plays the names from the bowl', () {
      final cubit = threeIn();
      expect(cubit.state.stage, PassStage.passed);
      cubit.everyoneIn();
      expect(cubit.state.stage, PassStage.reader);
      final args = cubit.roundArgs()!;
      expect({for (final s in args.slips) s.text}, {'Sara', 'Omar', 'Nour'});
      expect(args.players, hasLength(3));
    });

    test('Team race hands over the players who are in', () {
      final cubit = threeIn(mode: GameMode.celebrity);
      cubit
        ..next()
        ..submit(name: 'Karim', secrets: ['Karim 1', 'Karim 2', 'Karim 3']);
      final args = cubit.celebrityArgs()!;
      expect([for (final p in args.players) p.name], ['Sara', 'Omar', 'Nour', 'Karim']);
      expect(cubit.roundArgs(), isNull);
    });

    test('after the game: a new round asks everyone again, going back keeps the names', () {
      final cubit = threeIn()..everyoneIn();
      cubit.afterGame(null);
      expect(cubit.state.stage, PassStage.passed);
      expect(cubit.state.bowl!.slipCount, 3);
      cubit.afterGame(GameExit.newRound);
      expect(cubit.state.stage, PassStage.typing);
      expect(cubit.state.bowl!.slipCount, 0);
      expect(cubit.state.bowl!.waiting, hasLength(3));
    });

    test('stopping throws the bowl away', () {
      final cubit = threeIn()..stop();
      expect(cubit.state.stage, PassStage.setup);
      expect(cubit.state.bowl, isNull);
    });
  });
}
