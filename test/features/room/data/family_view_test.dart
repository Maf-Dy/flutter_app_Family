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

  group('house rules', () {
    const four = [...players, FamilyPlayer(id: 'd', name: 'Sami')];
    FamilyGame startWith(FamilyTwists twists) {
      for (var seed = 0; ; seed++) {
        final game = FamilyGame.start(
          players: four,
          slips: const [
            (text: 'Messi', writerId: 'a'),
            (text: 'Fairuz', writerId: 'b'),
            (text: 'Adele', writerId: 'c'),
            (text: 'Chaplin', writerId: 'd'),
          ],
          chatEnabled: true,
          random: Random(seed),
          twists: twists,
        );
        if (game.turnPlayer == 'a') return game;
      }
    }

    test('with secret catches, only the catcher\'s family learns the catch', () {
      final begun = startWith(const FamilyTwists(secretCatches: true));
      final game = begun.guess('a', 'b', slipBy(begun, 'b'));
      final omar = familyViewFor(game, 'a'), yara = familyViewFor(game, 'c');
      final pubB = familyPublicId(game, 'b'), pubA = familyPublicId(game, 'a');
      Map<String, Object?> nourIn(Map<String, Object?> view) =>
          listOf(view, 'players').firstWhere((p) => p['id'] == pubB);
      expect(nourIn(omar)['head'], pubA);
      expect(nourIn(yara)['head'], pubB, reason: 'Nour still looks free to everyone else');
      expect(listOf(yara, 'events').single, {'asker': pubA, 'hidden': true});
      expect(listOf(omar, 'events').single['correct'], isTrue);
      expect(listOf(yara, 'slips').where((s) => s.containsKey('writer') && s['mine'] != true), isEmpty);
      expect(yara['secret'], isTrue);
      expect(yara['turnPlayer'], isNot(pubA), reason: 'turns go round every player');
    });

    test('the person asked gets the "let me go" choice; everyone else waits', () {
      final begun = startWith(const FamilyTwists(letMeGo: true));
      final game = begun.guess('a', 'c', slipBy(begun, 'c'));
      final yara = familyViewFor(game, 'c'), sami = familyViewFor(game, 'd');
      expect(yara['pending'], {
        'kind': 'letMeGo',
        'asker': familyPublicId(game, 'a'),
        'responder': familyPublicId(game, 'c'),
        'mine': true,
        'slip': slipBy(game, 'c'),
      });
      expect((sami['pending']! as Map)['mine'], isFalse);
      expect((sami['pending']! as Map).containsKey('slip'), isFalse, reason: 'only the one asked sees the name');
      expect(yara['card'], isTrue);
      final after = familyViewFor(game.answerLetMeGo('c', use: true), 'c');
      expect(after['pending'], isNull);
      expect(after['card'], isFalse);
      expect(listOf(after, 'events').single['blocked'], isTrue);
    });

    test('rumors show to everyone, without who spread them', () {
      final begun = startWith(const FamilyTwists(rumors: true));
      final game = begun.spreadRumor('d', 'a', slipBy(begun, 'c'));
      final view = familyViewFor(game, 'b');
      expect(listOf(view, 'rumors').single, {'id': 1, 'target': familyPublicId(game, 'a'), 'slip': slipBy(game, 'c')});
      expect(jsonEncode(view['rumors']), isNot(contains(familyPublicId(game, 'd'))));
      expect(familyViewFor(game, 'd')['canRumor'], isFalse);
      expect(view['canRumor'], isTrue);
    });
  });
}
