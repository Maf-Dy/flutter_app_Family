import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const empty = Room(code: 'K7Q4', category: 'Famous people', namesPerPlayer: 1);

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
      const two = Room(code: 'K7Q4', category: 'Movies', namesPerPlayer: 2);
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
    const two = Room(code: 'K7Q4', category: 'Movies', namesPerPlayer: 2);
    final room = two.withHostSecret('Up').withHostSecret('  ').withHostSecret('Heat').withHostSecret('Jaws');
    expect(room.host!.secrets, ['Up', 'Heat']);
    expect(room.host!.name, 'You');
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
      ('Adele', Player.hostId, 'You'),
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
}
