import 'dart:math';

import 'package:family_game/features/family/domain/family_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const players = [
    FamilyPlayer(id: 'a', name: 'Omar'),
    FamilyPlayer(id: 'b', name: 'Nour'),
    FamilyPlayer(id: 'c', name: 'Yara'),
  ];

  FamilyGame start({bool chat = true}) => FamilyGame.start(
    players: players,
    slips: const [(text: 'Messi', writerId: 'a'), (text: 'Fairuz', writerId: 'b'), (text: 'Adele', writerId: 'c')],
    chatEnabled: chat,
    random: Random(1),
  );

  int slipBy(FamilyGame game, String writer) => game.slips.firstWhere((s) => s.writerId == writer).id;

  /// A game where it's Omar's family's turn, however the first turn fell.
  FamilyGame omarsTurn() {
    var game = start();
    if (game.turn != 'a') {
      // Someone asks Omar wrongly, which hands him the turn.
      final asker = game.turn;
      final wrong = game.slips.firstWhere((s) => s.writerId != 'a' && s.writerId != asker).id;
      game = game.guess(asker, 'a', wrong);
    }
    expect(game.turn, 'a');
    return game;
  }

  test('everyone starts as their own family', () {
    final game = start();
    expect(game.familyHeads, ['a', 'b', 'c']);
    expect(game.isOver, isFalse);
  });

  test('a right guess brings the person into your family and keeps the turn', () {
    var game = omarsTurn();
    game = game.guess('a', 'b', slipBy(game, 'b'));
    expect(game.headOf('b'), 'a');
    expect(game.turn, 'a');
    expect(game.revealed, contains(slipBy(game, 'b')));
    expect(game.events.last.correct, isTrue);
  });

  test('a wrong guess passes the turn to the family of the person asked', () {
    var game = omarsTurn();
    game = game.guess('a', 'b', slipBy(game, 'c'));
    expect(game.turn, 'b');
    expect(game.headOf('b'), 'b');
    expect(game.events.last.correct, isFalse);
  });

  test('catching a head brings their whole family; the last family wins', () {
    var game = omarsTurn();
    // Omar's turn goes wrong on Yara, so Yara's family asks and catches Nour.
    game = game.guess('a', 'c', slipBy(game, 'b'));
    game = game.guess('c', 'b', slipBy(game, 'b'));
    expect(game.membersOf('c'), ['b', 'c']);
    // Yara now asks Omar and gets it: everyone is one family.
    game = game.guess('c', 'a', slipBy(game, 'a'));
    expect(game.isOver, isTrue);
    expect(game.winner, 'c');
    expect(game.checkGuess('c', 'a', 0), FamilyActionError.gameOver);
  });

  test('only the head guesses, only on the family\'s turn, only about outsiders', () {
    var game = omarsTurn();
    game = game.guess('a', 'b', slipBy(game, 'b'));
    expect(game.checkGuess('b', 'c', slipBy(game, 'c')), FamilyActionError.notHead);
    expect(game.checkGuess('c', 'a', slipBy(game, 'a')), FamilyActionError.notYourTurn);
    expect(game.checkGuess('a', 'b', slipBy(game, 'a')), FamilyActionError.invalidTarget);
    expect(game.checkGuess('a', 'c', slipBy(game, 'b')), FamilyActionError.invalidSlip, reason: 'already revealed');
  });

  test('members back one idea each; the head sees them ranked', () {
    var game = omarsTurn();
    game = game.guess('a', 'b', slipBy(game, 'b'));
    final adele = slipBy(game, 'c');
    final messi = slipBy(game, 'a');
    game = game.suggest('b', 'c', adele).suggest('a', 'c', messi);
    expect(game.suggestionsFor('a').map((s) => s.voters.length), [1, 1]);
    game = game.suggest('a', 'c', adele);
    final ideas = game.suggestionsFor('a');
    expect(ideas, hasLength(1), reason: 'Omar moved his vote, leaving the other idea empty');
    expect(ideas.single.voters, {'a', 'b'});
    game = game.unvote('b');
    expect(game.suggestionsFor('a').single.voters, {'a'});
  });

  test('family chat is private, and follows people into their new family', () {
    var game = omarsTurn();
    game = game.say('b', 'I think Yara wrote Adele').say('c', 'no idea');
    expect(game.chatFor('b').map((m) => m.text), ['I think Yara wrote Adele']);
    expect(game.chatFor('a'), isEmpty);
    game = game.guess('a', 'b', slipBy(game, 'b'));
    expect(game.chatFor('a').map((m) => m.text), ['I think Yara wrote Adele']);
    expect(game.chatFor('c').map((m) => m.text), ['no idea']);
  });

  test('chat can be turned off, and blank messages are ignored', () {
    final off = start(chat: false);
    expect(off.checkMessage('a', 'hi'), FamilyActionError.chatOff);
    expect(start().checkMessage('a', '   '), FamilyActionError.emptyMessage);
  });

  test('caught people drop out of who is worth asking', () {
    var game = omarsTurn();
    expect(game.askableFor('a').map((p) => p.id), ['b', 'c']);
    game = game.guess('a', 'b', slipBy(game, 'b'));
    expect(game.isCaught('b'), isTrue);
    expect(game.isCaught('a'), isFalse);
    expect(game.askableFor('a').map((p) => p.id), ['c']);
    expect(game.askableFor('c').map((p) => p.id), ['a'], reason: 'Nour is in the family, but her name is out');
  });

  test('a repeated name counts for either person who wrote it', () {
    var game = FamilyGame.start(
      players: players,
      slips: const [(text: 'Messi', writerId: 'a'), (text: 'messi', writerId: 'b'), (text: 'Adele', writerId: 'c')],
      chatEnabled: true,
      random: Random(1),
    );
    if (game.turn != 'c') game = game.guess(game.turn, 'c', slipBy(game, game.turn));
    expect(game.turn, 'c');
    // Yara asks Nour about Omar's copy: Nour wrote the same name, so it counts.
    game = game.guess('c', 'b', slipBy(game, 'a'));
    expect(game.events.last.correct, isTrue);
    expect(game.revealed, {slipBy(game, 'b')}, reason: 'only Nour\'s own slip is out');
  });

  test('every change bumps the version', () {
    final game = start();
    expect(game.say('a', 'hi').version, greaterThan(game.version));
  });

  group('when phones drop out', () {
    /// Omar's family (Omar and Nour) against Yara, and it's Omar's turn again.
    FamilyGame omarAndNour() {
      final game = omarsTurn();
      return game.guess('a', 'b', slipBy(game, 'b'));
    }

    test('with the head here, only the head asks', () {
      final game = omarAndNour().withAway({'c'});
      expect(game.canAsk('a'), isTrue);
      expect(game.canAsk('b'), isFalse);
      expect(game.checkGuess('b', 'c', slipBy(game, 'c')), FamilyActionError.notHead);
    });

    test('a member still here asks for a head who dropped, and the family stays the head\'s', () {
      final game = omarAndNour().withAway({'a'});
      expect(game.canAsk('b'), isTrue);
      expect(game.canAsk('a'), isTrue, reason: 'if Omar\'s phone comes back mid-turn he can still ask');
      final after = game.guess('b', 'c', slipBy(game, 'c'));
      expect(after.headOf('c'), 'a', reason: 'Yara joins Omar\'s family, not a new one under Nour');
      expect(after.events.last.askerId, 'b');
      expect(after.isOver, isTrue);
    });

    test('a wrong guess by the stand-in passes the turn as usual', () {
      final game = omarAndNour().withAway({'a'});
      final after = game.guess('b', 'c', slipBy(game, 'a'));
      expect(after.turn, 'c');
      expect(after.canAsk('b'), isFalse);
    });

    test('the turn is skipped only when the whole family dropped, and only when asked', () {
      final game = omarsTurn();
      expect(game.skipTurn(), same(game), reason: 'Omar is still here');
      final away = game.withAway({'a'});
      expect(away.familyAway('a'), isTrue);
      final skipped = away.skipTurn();
      expect(skipped.turn, isNot('a'));
      expect(skipped.familyHeads, contains(skipped.turn));
      expect(omarAndNour().withAway({'a'}).familyAway('a'), isFalse, reason: 'Nour is still here');
    });

    test('marking the same people away again changes nothing', () {
      final game = start().withAway({'a'});
      expect(game.withAway({'a'}), same(game));
      expect(game.withAway({'a', 'nobody'}), same(game));
      expect(game.withAway(const {}).away, isEmpty);
    });

    test('a new phone asks for a dropped seat, and the host decides', () {
      final game = start().withAway({'b'});
      expect(game.claimable.map((p) => p.id), ['b']);
      expect(game.claimSeat('x', 'a'), same(game), reason: 'Omar is still here, so his seat is not free');
      expect(game.claimSeat('a', 'b'), same(game), reason: 'someone already playing can\'t take another seat');

      final asked = game.claimSeat('x', 'b');
      expect(asked.pendingClaims.single.playerId, 'b');
      expect(asked.claimSeat('x', 'b').claims, hasLength(1), reason: 'asking again replaces the first ask');

      final denied = asked.resolveClaim('x', approve: false);
      expect(denied.claimOf('x')!.status, ClaimStatus.denied);
      expect(denied.pendingClaims, isEmpty);

      final approved = asked.resolveClaim('x', approve: true);
      expect(approved.claimOf('x')!.status, ClaimStatus.approved);
      expect(approved.resolveClaim('x', approve: false), same(approved), reason: 'decided once');
      expect(approved.dropClaim('x').claims, isEmpty);
    });
  });
}
