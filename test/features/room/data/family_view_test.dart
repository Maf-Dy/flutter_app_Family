import 'dart:math';

import 'package:family_game/features/family/domain/family_game.dart';
import 'package:family_game/features/room/data/family_view.dart';
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

  /// Omar's family (Omar and Nour) against Yara, with ideas and chat on both sides.
  FamilyGame midGame({bool chat = true}) {
    var game = start(chat: chat);
    if (game.turn != 'a') game = game.guess(game.turn, 'a', slipBy(game, game.turn == 'b' ? 'c' : 'b'));
    game = game.guess('a', 'b', slipBy(game, 'b'));
    return game
        .suggest('b', 'c', slipBy(game, 'c'))
        .suggest('c', 'a', slipBy(game, 'a'))
        .say('b', 'Yara wrote Adele')
        .say('c', 'Omar has Messi');
  }

  List<Map<String, Object?>> listOf(Map<String, Object?> view, String key) =>
      (view[key]! as List<Object?>).cast<Map<String, Object?>>();

  test('a player sees only their own family\'s ideas and chat', () {
    final game = midGame();
    final nour = familyViewFor(game, 'b');
    expect(nour['me'], 'b');
    expect(nour['myHead'], 'a');
    expect(listOf(nour, 'chat').map((m) => m['text']), ['Yara wrote Adele']);
    expect(listOf(nour, 'ideas').single, containsPair('target', 'c'));
    expect(listOf(nour, 'ideas').single, containsPair('mine', true));

    final yara = familyViewFor(game, 'c');
    expect(listOf(yara, 'chat').map((m) => m['text']), ['Omar has Messi']);
    expect(listOf(yara, 'ideas').single, containsPair('target', 'a'));
  });

  test('who wrote a name shows only once it is out', () {
    final game = midGame();
    final slips = listOf(familyViewFor(game, 'c'), 'slips');
    final withWriter = {for (final s in slips) s['text']: s['writer']};
    expect(withWriter, {'Messi': null, 'Fairuz': 'b', 'Adele': null});
  });

  test('watchers and strangers see the board, never ideas or chat', () {
    final game = midGame();
    for (final id in [null, 'someone-else']) {
      final view = familyViewFor(game, id);
      expect(view['me'], isNull);
      expect(view['myHead'], isNull);
      expect(view['chat'], isEmpty);
      expect(view['ideas'], isEmpty);
      expect(view['families'], hasLength(2));
    }
  });

  test('with chat off, no one gets messages', () {
    final view = familyViewFor(midGame(chat: false), 'b');
    expect(view['chatOn'], isFalse);
    expect(view['chat'], isEmpty);
  });
}
