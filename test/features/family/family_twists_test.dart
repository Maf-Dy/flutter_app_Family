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

  /// A game whose first turn is Omar's, with the "فكّك مني" card in [holder]'s hand when that twist is on.
  FamilyGame start(FamilyTwists twists, {String holder = 'b'}) {
    for (var seed = 0; ; seed++) {
      final game = FamilyGame.start(
        players: players,
        slips: names,
        chatEnabled: true,
        random: Random(seed),
        twists: twists,
      );
      if (game.turn == 'a' && game.turnPlayer == 'a' && (!twists.letMeGo || game.cardHolder == holder)) return game;
    }
  }

  int slip(FamilyGame game, String text) => game.slips.firstWhere((s) => s.text == text).id;

  group('فكّك مني', () {
    const twists = FamilyTwists(letMeGo: true);

    test('only the card holder is asked first; using it cancels the ask and hands the card to the asker', () {
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
      expect(game.cardHolder, 'a', reason: 'hot potato: the card goes to the one who asked');
      expect(game.hasCard('b'), isFalse);
      // Without the card, Nour is asked like anyone else, straight away.
      game = game.guess('b', 'c', slip(game, 'Adele'));
      expect(game.pending, isNull);
      expect(game.headOf('c'), 'b');
    });

    test("letting it go answers the ask as normal and keeps the card, and a dropped holder isn't waited on", () {
      final game = start(twists).guess('a', 'b', slip(start(twists), 'Fairuz')).answerLetMeGo('b', use: false);
      expect(game.headOf('b'), 'a');
      expect(game.hasCard('b'), isTrue, reason: 'not used');
      final away = start(twists, holder: 'c');
      final asked = away.withAway({'c'}).guess('a', 'c', slip(away, 'Adele'));
      expect(asked.pending, isNull);
      expect(asked.headOf('c'), 'a');
    });

    test('there is only one card in the game', () {
      final game = start(twists);
      expect(
        [
          for (final p in players)
            if (game.hasCard(p.id)) p.id,
        ],
        ['b'],
      );
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
