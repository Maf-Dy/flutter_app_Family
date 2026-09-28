import 'dart:convert';
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
    expect(nour['me'], 'p1');
    expect(nour['myHead'], 'p0');
    expect(listOf(nour, 'chat').map((m) => m['text']), ['Yara wrote Adele']);
    expect(listOf(nour, 'ideas').single, containsPair('target', 'p2'));
    expect(listOf(nour, 'ideas').single, containsPair('mine', true));

    final yara = familyViewFor(game, 'c');
    expect(listOf(yara, 'chat').map((m) => m['text']), ['Omar has Messi']);
    expect(listOf(yara, 'ideas').single, containsPair('target', 'p0'));
  });

  test('who wrote a name shows only once it is out', () {
    final game = midGame();
    final slips = listOf(familyViewFor(game, 'c'), 'slips');
    final withWriter = {for (final s in slips) s['text']: s['writer']};
    expect(withWriter, {'Messi': null, 'Fairuz': 'p1', 'Adele': null});
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

  test('phones see who dropped out, who asks, and how a seat ask is going', () {
    final game = midGame().withAway({'a'});
    final nour = familyViewFor(game, 'b');
    expect(nour['away'], ['p0']);
    expect(nour['canAsk'], game.turn == 'a', reason: 'Nour asks for Omar while he is away');
    expect(nour['claimable'], isEmpty, reason: 'players already have a seat');

    final stranger = familyViewFor(game.claimSeat('x', 'a'), 'x');
    expect(listOf(stranger, 'claimable').single['name'], 'Omar');
    expect(stranger['myClaim'], {'player': 'p0', 'status': 'pending'});
    expect(familyViewFor(game.claimSeat('x', 'a'), 'y')['myClaim'], isNull, reason: 'each phone sees only its own ask');

    final refused = familyViewFor(game.claimSeat('x', 'a').resolveClaim('x', approve: false), 'x');
    expect(refused['claimable'], isEmpty, reason: 'a refused phone isn\'t offered that seat again');
  });

  test('phones never see anyone\'s real id, which is their cookie', () {
    // Ids that can't turn up by accident anywhere else in the view.
    const secret = [
      FamilyPlayer(id: 'secret-omar', name: 'Omar'),
      FamilyPlayer(id: 'secret-nour', name: 'Nour'),
      FamilyPlayer(id: 'secret-yara', name: 'Yara'),
    ];
    var game = FamilyGame.start(
      players: secret,
      slips: const [(text: 'Messi', writerId: 'secret-omar'), (text: 'Adele', writerId: 'secret-yara')],
      chatEnabled: true,
      random: Random(1),
    );
    final turn = game.turn;
    final other = secret.firstWhere((p) => p.id != turn && game.slips.any((s) => s.writerId == p.id)).id;
    game = game
        .guess(turn, other, game.slips.firstWhere((s) => s.writerId == other).id)
        .say(turn, 'hi')
        .withAway({'secret-nour'})
        .claimSeat('secret-stranger', 'secret-nour');
    for (final viewer in [...secret.map((p) => p.id), 'secret-stranger', null]) {
      final json = jsonEncode(familyViewFor(game, viewer));
      expect(json, isNot(contains('secret-')), reason: 'viewer $viewer');
    }
    expect(familyPlayerIdFor(game, familyPublicId(game, 'secret-nour')), 'secret-nour');
    expect(familyPlayerIdFor(game, 'p3'), isNull);
    expect(familyPlayerIdFor(game, 'secret-nour'), isNull, reason: 'real ids are not accepted in their place');
  });

  test('a phone marks the names it wrote, so they are not offered as a guess', () {
    final game = start();
    final slips = [for (final s in (familyViewFor(game, 'b')['slips'] as List)) s as Map];
    expect(
      [
        for (final s in slips)
          if (s['mine'] == true) s['text'],
      ],
      ['Fairuz'],
    );
    final watcher = [for (final s in (familyViewFor(game, 'zz')['slips'] as List)) s as Map];
    expect(watcher.any((s) => s.containsKey('mine')), isFalse);
  });
}
