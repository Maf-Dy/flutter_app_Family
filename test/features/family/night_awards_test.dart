import 'dart:math';

import 'package:family_game/features/family/domain/family_game.dart';
import 'package:family_game/features/family/domain/night_awards.dart';
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
    (text: 'Fairuz', writerId: 'b'),
    (text: 'Adele', writerId: 'c'),
    (text: 'Chaplin', writerId: 'd'),
  ];

  FamilyGame start() {
    for (var seed = 0; ; seed++) {
      final game = FamilyGame.start(players: players, slips: names, chatEnabled: false, random: Random(seed));
      if (game.turn == 'a') return game;
    }
  }

  int slip(FamilyGame game, String writer) => game.slips.firstWhere((s) => s.writerId == writer).id;

  /// Omar catches Nour, wrongly accuses Yara, Yara wrongly accuses Sami, then Sami catches Yara and Omar.
  FamilyGame played() {
    var game = start();
    game = game.guess('a', 'b', slip(game, 'b')); // right: Nour joins Omar, Omar asks again
    game = game.guess('a', 'c', slip(game, 'd')); // wrong: the turn goes to Yara
    game = game.guess('c', 'd', slip(game, 'a')); // wrong: the turn goes to Sami
    expect(game.turn, 'd');
    game = game.guess('d', 'c', slip(game, 'c')); // right: Yara joins Sami
    game = game.guess('d', 'a', slip(game, 'a')); // right: Omar's family joins Sami
    return game;
  }

  test('the awards go to the first caught, the winner, the most wronged and the best catcher', () {
    final game = played();
    expect(game.isOver, isTrue);
    expect(game.winner, 'd');
    final awards = {for (final a in nightAwards(game)) a.kind: a};
    expect(awards[AwardKind.worstLiar]!.playerId, 'b');
    expect(awards[AwardKind.pokerFace]!.playerId, 'd');
    expect(awards[AwardKind.wronged]!.playerId, 'c', reason: 'a tie goes to whoever joined first');
    expect(awards[AwardKind.wronged]!.count, 1);
    expect(awards[AwardKind.detective]!.playerId, 'd');
    expect(awards[AwardKind.detective]!.count, 2);
  });

  test('no titles before anything happened', () {
    expect(nightAwards(start()), isEmpty);
  });

  test('the tree hangs everyone under whoever brought them in, the winner on top', () {
    final game = played();
    expect(familyTree(game), {'a': 'd', 'b': 'a', 'c': 'd', 'd': null});
    expect(familyTreeLines(game).map((l) => (l.playerId, l.depth)), [('d', 0), ('a', 1), ('b', 2), ('c', 1)]);
  });
}
