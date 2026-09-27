import '../../family/domain/family_game.dart';

/// The family game as one phone may see it: everything public, plus its own
/// family's ideas and chat. Who wrote a name only shows once it is revealed.
Map<String, Object?> familyViewFor(FamilyGame game, String? playerId) {
  final inGame = playerId != null && game.player(playerId) != null;
  final myHead = inGame ? game.headOf(playerId) : null;
  return {
    'v': game.version,
    'me': inGame ? playerId : null,
    'myHead': myHead,
    'turn': game.turn,
    'winner': game.winner,
    'chatOn': game.chatEnabled,
    'players': [
      for (final p in game.players) {'id': p.id, 'name': p.name, 'head': game.headOf(p.id)},
    ],
    'slips': [
      for (final s in game.slips) {'id': s.id, 'text': s.text, if (game.revealed.contains(s.id)) 'writer': s.writerId},
    ],
    'families': [
      for (final head in game.familyHeads) {'head': head, 'members': game.membersOf(head)},
    ],
    'ideas': myHead == null
        ? const <Object?>[]
        : [
            for (final s in game.suggestionsFor(myHead))
              {'target': s.targetId, 'slip': s.slipId, 'votes': s.voters.length, 'mine': s.voters.contains(playerId)},
          ],
    'chat': myHead == null || !game.chatEnabled
        ? const <Object?>[]
        : [
            for (final m in game.chatFor(myHead)) {'id': m.id, 'author': m.authorId, 'text': m.text},
          ],
    'events': [
      for (final e in game.events.reversed.take(6))
        {'asker': e.askerId, 'target': e.targetId, 'slip': e.slipId, 'correct': e.correct},
    ],
  };
}
