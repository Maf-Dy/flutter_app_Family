import 'dart:math';

import 'package:family_game/features/family/domain/family_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const players = [
    FamilyPlayer(id: 'a', name: 'Omar'),
    FamilyPlayer(id: 'b', name: 'Nour'),
    FamilyPlayer(id: 'c', name: 'Yara'),
    FamilyPlayer(id: 'd', name: 'Sami'),
  ];
  const names = [
    (text: 'Messi', writerId: 'a'),
    (text: 'Salah', writerId: 'a'),
    (text: 'Fairuz', writerId: 'b'),
    (text: 'Adele', writerId: 'c'),
    (text: 'Chaplin', writerId: 'd'),
  ];

  /// A game whose first turn is Omar's.
  FamilyGame start(FamilyTwists twists) {
    for (var seed = 0; ; seed++) {
      final game = FamilyGame.start(
        players: players,
        slips: names,
        chatEnabled: true,
        random: Random(seed),
        twists: twists,
      );
      if (game.turn == 'a' && game.turnPlayer == 'a') return game;
    }
  }

  int slip(FamilyGame game, String text) => game.slips.firstWhere((s) => s.text == text).id;

  group('فكّك مني', () {
    const twists = FamilyTwists(letMeGo: true);

    test('the person asked is asked first; using it cancels the ask and passes the turn on', () {
      var game = start(twists).guess('a', 'b', slip(start(twists), 'Fairuz'));
      expect(game.pending?.kind, PendingKind.letMeGo);
      expect(game.waitingOn, 'b');
      expect(game.checkGuess('a', 'c', slip(game, 'Adele')), FamilyActionError.waiting);
      expect(game.answerLetMeGo('c', use: true), same(game), reason: 'not theirs to answer');
      game = game.answerLetMeGo('b', use: true);
      expect(game.pending, isNull);
      expect(game.familyHeads, ['a', 'b', 'c', 'd'], reason: 'nobody caught');
      expect(game.revealed, isEmpty);
      expect(game.events.last.blocked, isTrue);
      expect(game.turn, 'b', reason: 'the next family in join order');
      expect(game.hasCard('b'), isFalse);
      // Once used, Nour is asked like anyone else.
      game = game.guess('b', 'c', slip(game, 'Adele'));
      expect(game.pending?.responderId, 'c');
      game = game.answerLetMeGo('c', use: false);
      expect(game.headOf('c'), 'b');
    });

    test("letting it go answers the ask as normal, and a dropped player's card is skipped", () {
      var game = start(twists).guess('a', 'b', slip(start(twists), 'Fairuz')).answerLetMeGo('b', use: false);
      expect(game.headOf('b'), 'a');
      expect(game.hasCard('b'), isTrue, reason: 'not used');
      game = game.withAway({'c'}).guess('a', 'c', slip(game, 'Adele'));
      expect(game.pending, isNull);
      expect(game.headOf('c'), 'a');
    });
  });

  group('counter-catch', () {
    const twists = FamilyTwists(counterCatch: true);

    test('a right shot back flips the catch', () {
      var game = start(twists).guess('a', 'b', slip(start(twists), 'Fairuz'));
      expect(game.pending?.kind, PendingKind.counter);
      expect(game.counterTargetsFor('b'), ['a']);
      expect(game.checkCounter('b', 'c', slip(game, 'Adele')), FamilyActionError.invalidTarget);
      game = game.counterCatch('b', 'a', slip(game, 'Salah'));
      expect(game.headOf('a'), 'b');
      expect(game.headOf('b'), 'b');
      expect(game.turn, 'b');
      expect(game.revealed, containsAll([slip(game, 'Messi'), slip(game, 'Salah'), slip(game, 'Fairuz')]));
      expect(game.events.last.kind, AskKind.counter);
      expect(game.events.last.intoHead, 'b');
    });

    test('a wrong shot back, or a pass, lets the catch stand and the catcher goes again', () {
      final caught = start(twists).guess('a', 'b', slip(start(twists), 'Fairuz'));
      final missed = caught.counterCatch('b', 'a', slip(caught, 'Adele'));
      expect(missed.headOf('b'), 'a');
      expect(missed.turn, 'a');
      expect(missed.events.map((e) => (e.kind, e.correct)), [(AskKind.ask, true), (AskKind.counter, false)]);
      expect(missed.events.first.intoHead, 'a');
      final passed = caught.passCounter('b');
      expect(passed.headOf('b'), 'a');
      expect(passed.turn, 'a');
    });
  });

  group('revenge', () {
    const twists = FamilyTwists(revenge: true);

    test('the wrongly accused gets a free shot at the accuser, then plays their turn', () {
      var game = start(twists).guess('a', 'b', slip(start(twists), 'Adele'));
      expect(game.pending?.kind, PendingKind.revenge);
      expect(game.revengeSlipsFor('b').map((s) => s.text), unorderedEquals(['Messi', 'Salah']));
      game = game.revenge('b', slip(game, 'Messi'));
      expect(game.headOf('a'), 'b');
      expect(game.turn, 'b');
      expect(game.events.last.kind, AskKind.revenge);
    });

    test('a missed revenge costs nothing', () {
      var game = start(twists).guess('a', 'b', slip(start(twists), 'Adele'));
      game = game.revenge('b', slip(game, 'Chaplin'));
      expect(game.familyHeads, ['a', 'b', 'c', 'd']);
      expect(game.turn, 'b');
    });
  });

  group('wanted', () {
    const twists = FamilyTwists(wanted: true);

    test("catching the wanted name's writer earns an extra ask for the next miss", () {
      var game = start(twists);
      final wanted = game.wanted!;
      final writer = game.slips[wanted].writerId;
      // Make sure Omar isn't the wanted one: re-pick seeds until he's not.
      if (writer == 'a') return;
      game = game.guess('a', writer, wanted);
      expect(game.events.last.wantedCaught, isTrue);
      expect(game.bonus['a'], 1);
      expect(game.wanted, isNot(wanted));
      expect(game.revealed.contains(game.wanted), isFalse);
      // A miss spends the extra ask: Omar's family keeps the turn.
      final other = game.askableFor('a').first.id;
      final wrong = game.slips.firstWhere((s) => s.writerId != other && !game.revealed.contains(s.id)).id;
      game = game.guess('a', other, wrong);
      expect(game.turn, 'a');
      expect(game.bonus['a'], isNull);
    });
  });

  group('rumors', () {
    const twists = FamilyTwists(rumors: true);

    test('one anonymous rumor each, about any name still hidden', () {
      var game = start(twists);
      expect(game.canSpreadRumor('c'), isTrue);
      game = game.spreadRumor('c', 'b', slip(game, 'Messi'));
      expect(game.rumors.single.targetId, 'b');
      expect(game.canSpreadRumor('c'), isFalse);
      expect(game.spreadRumor('c', 'a', slip(game, 'Adele')), same(game));
      expect(start(FamilyTwists.none).canSpreadRumor('c'), isFalse);
    });
  });

  group('secret catches', () {
    const twists = FamilyTwists(secretCatches: true);

    test('turns go round every player, whatever the result, and a catch stays private', () {
      var game = start(twists);
      game = game.guess('a', 'b', slip(game, 'Fairuz'));
      expect(game.headOf('b'), 'a');
      expect(game.turnPlayer, 'b', reason: 'the next player, even though Omar was right');
      expect(game.canAsk('b'), isTrue, reason: 'Nour asks for her new family');
      expect(game.headSeenBy('c', 'b'), 'b', reason: 'Yara thinks Nour is still free');
      expect(game.headSeenBy('a', 'b'), 'a');
      final ask = game.events.last;
      expect(game.seesEvent('a', ask), isTrue);
      expect(game.seesEvent('b', ask), isTrue);
      expect(game.seesEvent('c', ask), isFalse);
      expect(game.knowsWriter('a', slip(game, 'Fairuz')), isTrue);
      expect(game.knowsWriter('c', slip(game, 'Fairuz')), isFalse);
    });

    test("anyone can still be asked; catching a secretly caught player brings their whole family", () {
      var game = start(twists);
      game = game.guess('a', 'b', slip(game, 'Fairuz')); // Nour joins Omar in secret.
      game = game.guess('b', 'c', slip(game, 'Chaplin')); // wrong, Yara's turn next
      expect(game.turnPlayer, 'c');
      // Yara asks Nour about Fairuz, not knowing she was caught: it's still right.
      expect(game.askableFor('c').map((p) => p.id), containsAll(['a', 'b', 'd']));
      game = game.guess('c', 'b', slip(game, 'Fairuz'));
      expect(game.headOf('a'), 'c');
      expect(game.headOf('b'), 'c');
    });

    test('the end reveals everything', () {
      var game = start(twists);
      game = game.guess('a', 'b', slip(game, 'Fairuz'));
      game = game.guess('b', 'c', slip(game, 'Adele'));
      game = game.guess('c', 'd', slip(game, 'Chaplin'));
      expect(game.isOver, isTrue);
      expect(game.headSeenBy('d', 'b'), 'a');
      expect(game.seesEvent('d', game.events.first), isTrue);
    });
  });

  test('the host can move on when the person the game waits on has dropped out', () {
    const twists = FamilyTwists(letMeGo: true);
    var game = start(twists).guess('a', 'b', slip(start(twists), 'Fairuz'));
    expect(game.turnStalled, isFalse);
    game = game.withAway({'b'});
    expect(game.turnStalled, isTrue);
    game = game.skipTurn();
    expect(game.pending, isNull);
    expect(game.headOf('b'), 'a', reason: 'as if they let it go');
  });
}
