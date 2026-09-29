import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const empty = Room(
    code: 'K7Q4',
    category: GameCategory.preset(PresetCategory.famousPeople),
    namesPerPlayer: 1,
    hostName: 'Mafdy',
  );

  group('validate', () {
    test('accepts a name and one secret', () {
      expect(empty.validate(name: 'Omar', secrets: ['Lionel Messi']), isNull);
    });

    test('rejects missing, blank, too long and closed submissions', () {
      expect(empty.validate(name: '  ', secrets: ['Messi']), SubmissionError.missingName);
      expect(empty.validate(name: 'Omar', secrets: ['   ']), SubmissionError.missingSecret);
      expect(empty.validate(name: 'Omar', secrets: []), SubmissionError.missingSecret);
      expect(empty.validate(name: 'Omar', secrets: ['x' * 61]), SubmissionError.tooLong);
      expect(empty.validate(name: 'x' * 31, secrets: ['Messi']), SubmissionError.tooLong);
      expect(empty.startReading().validate(name: 'Omar', secrets: ['Messi']), SubmissionError.roomClosed);
    });

    test('needs exactly namesPerPlayer secrets', () {
      const two = Room(
        code: 'K7Q4',
        category: GameCategory.preset(PresetCategory.movies),
        namesPerPlayer: 2,
        hostName: 'Mafdy',
      );
      expect(two.validate(name: 'Omar', secrets: ['Up']), SubmissionError.missingSecret);
      expect(two.validate(name: 'Omar', secrets: ['Up', 'Heat']), isNull);
    });
  });

  group('withSubmission', () {
    test('adds a player in join order and tidies whitespace', () {
      final room = empty
          .withSubmission(playerId: 'a', name: ' Omar ', secrets: ['  Lionel   Messi '])
          .withSubmission(playerId: 'b', name: 'Nour', secrets: ['Fairuz']);
      expect(room.players.map((p) => p.name), ['Omar', 'Nour']);
      expect(room.players.first.secrets, ['Lionel Messi']);
      expect(room.slipCount, 2);
    });

    test('replaces an edit in place, keeping the colour slot', () {
      final room = empty
          .withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi'])
          .withSubmission(playerId: 'b', name: 'Nour', secrets: ['Fairuz'])
          .withSubmission(playerId: 'a', name: 'Omar K', secrets: ['Salah']);
      expect(room.players.map((p) => p.id), ['a', 'b']);
      expect(room.playerById('a')!.secrets, ['Salah']);
      expect(room.joinIndexOf('a'), 0);
    });

    test('stops adding new players at the limit', () {
      var room = empty;
      for (var i = 0; i < Room.maxPlayers + 2; i++) {
        room = room.withSubmission(playerId: 'p$i', name: 'P$i', secrets: ['S$i']);
      }
      expect(room.players, hasLength(Room.maxPlayers));
    });
  });

  test('host secrets fill up to namesPerPlayer and ignore blanks', () {
    const two = Room(
      code: 'K7Q4',
      category: GameCategory.preset(PresetCategory.movies),
      namesPerPlayer: 2,
      hostName: 'Mafdy',
    );
    final room = two.withHostSecret('Up').withHostSecret('  ').withHostSecret('Heat').withHostSecret('Jaws');
    expect(room.host!.secrets, ['Up', 'Heat']);
    expect(room.host!.name, 'Mafdy');
    expect(room.hostSecretsLeft, 0);
  });

  test('needs three players with names in before it can start', () {
    var room = empty.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']);
    room = room.withSubmission(playerId: 'b', name: 'Nour', secrets: ['Fairuz']);
    expect(room.canStart, isFalse);
    expect(room.playersNeeded, 1);
    room = room.withHostSecret('Umm Kulthum');
    expect(room.canStart, isTrue);
    expect(room.playersNeeded, 0);
  });

  test('slips remember their writer', () {
    final room = empty.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']).withHostSecret('Adele');
    expect(room.slips.map((s) => (s.text, s.writerId, s.writerName)), [
      ('Messi', 'a', 'Omar'),
      ('Adele', Player.hostId, 'Mafdy'),
    ]);
  });

  test('next round keeps players, empties the bowl and reopens it', () {
    final played = empty.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']).startReading();
    expect(played.isCollecting, isFalse);
    final next = played.nextRound();
    expect(next.isCollecting, isTrue);
    expect(next.round, 2);
    expect(next.players.single.name, 'Omar');
    expect(next.players.single.hasSubmitted, isFalse);
    expect(played.reopen().slipCount, 1);
  });

  test('host secrets are ignored while reading', () {
    expect(empty.startReading().withHostSecret('Messi').slipCount, 0);
  });

  group('same name twice', () {
    const strict = Room(
      code: 'K7Q4',
      category: GameCategory.preset(PresetCategory.footballers),
      namesPerPlayer: 1,
      hostName: 'Mafdy',
      allowDuplicates: false,
    );

    test('is allowed by default, even spelled the same', () {
      final room = empty.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']);
      expect(room.validate(name: 'Nour', secrets: ['messi'], playerId: 'b'), isNull);
    });

    test('when not allowed, catches case, spacing and Arabic letter variants', () {
      final room = strict.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Lionel Messi']);
      expect(room.validate(name: 'Nour', secrets: ['lionel  MESSI'], playerId: 'b'), SubmissionError.duplicate);
      final arabic = strict.withSubmission(playerId: 'a', name: 'Omar', secrets: ['أم كلثوم']);
      expect(arabic.validate(name: 'Nour', secrets: ['ام كلثوم'], playerId: 'b'), SubmissionError.duplicate);
      final taa = strict.withSubmission(playerId: 'a', name: 'Omar', secrets: ['فيروزة']);
      expect(taa.validate(name: 'Nour', secrets: ['فيروزه'], playerId: 'b'), SubmissionError.duplicate);
    });

    test('different spellings still get through', () {
      final room = strict.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']);
      expect(room.validate(name: 'Nour', secrets: ['Mesi'], playerId: 'b'), isNull);
    });

    test('a friend can resubmit their own name', () {
      final room = strict.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']);
      expect(room.validate(name: 'Omar', secrets: ['Messi'], playerId: 'a'), isNull);
    });

    test('the host is checked too', () {
      final room = strict.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']);
      expect(room.validateHostSecret('MESSI'), SubmissionError.duplicate);
      expect(room.withHostSecret('MESSI').host, isNull);
    });

    test('the host can add a second, different name', () {
      final room = Room(
        code: 'K7Q4',
        category: const GameCategory.preset(PresetCategory.footballers),
        namesPerPlayer: 2,
        hostName: 'Mafdy',
        allowDuplicates: false,
      ).withHostSecret('Messi');
      expect(room.validateHostSecret('Salah'), isNull);
      expect(room.withHostSecret('Salah').host?.secrets, ['Messi', 'Salah']);
      expect(room.validateHostSecret('messi'), SubmissionError.duplicate);
    });
  });

  group('fairness checks', () {
    const three = Room(
      code: 'K7Q4',
      category: GameCategory.preset(PresetCategory.movies),
      namesPerPlayer: 3,
      hostName: 'Mafdy',
    );

    test('a host part-way through their names is not in yet, and their names wait', () {
      var room = three
          .withSubmission(playerId: 'a', name: 'Omar', secrets: ['Up', 'Heat', 'Jaws'])
          .withSubmission(playerId: 'b', name: 'Nour', secrets: ['Cars', 'Big', 'Coco'])
          .withHostSecret('Alien');
      expect(room.canStart, isFalse);
      expect(room.slips, hasLength(6));
      room = room.withHostSecret('Rocky').withHostSecret('Ran');
      expect(room.canStart, isTrue);
      expect(room.slips, hasLength(9));
    });

    test('two players cannot share a name, the host’s included', () {
      final room = empty.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']);
      expect(room.validate(name: ' omar ', secrets: ['Salah'], playerId: 'b'), SubmissionError.nameTaken);
      expect(room.validate(name: 'Mafdy', secrets: ['Salah'], playerId: 'b'), SubmissionError.nameTaken);
      expect(
        room.validate(name: 'Omar', secrets: ['Salah'], playerId: 'a'),
        isNull,
        reason: 'Omar editing his own',
      );
    });

    test('names made only of emoji are told apart', () {
      expect(Room.matchKey('🐱'), isNot(Room.matchKey('🐶')));
      expect(Room.matchKey('أحمد'), Room.matchKey('احمد'));
    });

    test('Face-off starts at 3 names each and allows up to 5', () {
      expect(Room.namesForMode(1, GameMode.celebrity), 3);
      expect(Room.namesForMode(5, GameMode.celebrity), 5);
      expect(Room.namesForMode(5, GameMode.classic), 3);
      expect(Room.maxNamesFor(GameMode.celebrity), 5);
      expect(Room.maxNamesFor(GameMode.classic), 3);
    });

    test('Face-off starts with two players per team, however few names each', () {
      var race = const Room(
        code: 'K7Q4',
        category: GameCategory.preset(PresetCategory.movies),
        namesPerPlayer: 1,
        hostName: 'Mafdy',
        mode: GameMode.celebrity,
      );
      for (final id in ['a', 'b', 'c']) {
        race = race.withSubmission(playerId: id, name: id, secrets: ['$id 1']);
      }
      expect(race.playersNeeded, 1);
      expect(race.canStart, isFalse);
      race = race.withSubmission(playerId: 'd', name: 'd', secrets: ['d 1']);
      expect(race.playersNeeded, 0);
      expect(race.canStart, isTrue);
    });
  });

  test('the host can take a stale friend out before the reading, never after', () {
    final room = empty.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi']).withHostSecret('Adele');
    expect(room.withoutPlayer('a').players.map((p) => p.id), [Player.hostId]);
    expect(room.withoutPlayer(Player.hostId).players, hasLength(2), reason: 'the host stays');
    expect(room.startReading().withoutPlayer('a').players, hasLength(2));
  });
}
