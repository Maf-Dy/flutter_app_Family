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

  test('every change bumps the version', () {
    final game = start();
    expect(game.say('a', 'hi').version, greaterThan(game.version));
  });
}
