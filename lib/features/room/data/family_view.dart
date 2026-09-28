import '../../family/domain/family_game.dart';

/// The id phones use for a player: their place in the game. A player's real id
/// is their browser's cookie, so it never leaves the server — anyone who learned
/// it could set that cookie and play as them.
String familyPublicId(FamilyGame game, String playerId) {
  final index = game.players.indexWhere((p) => p.id == playerId);
  return index < 0 ? '' : 'p$index';
}

/// The real id behind a [familyPublicId], or null when it names no one.
String? familyPlayerIdFor(FamilyGame game, String publicId) {
  final match = RegExp(r'^p(\d{1,3})$').firstMatch(publicId);
  final index = match == null ? -1 : int.parse(match.group(1)!);
  return index >= 0 && index < game.players.length ? game.players[index].id : null;
}

/// The family game as one phone may see it: everything public, plus its own
/// family's ideas and chat. Who wrote a name only shows once it is revealed.
/// Players appear by their [familyPublicId] only.
///
/// [playerId] is the phone's id; for someone not in the game it is only used
/// to tell them how their ask for a dropped player's seat is going.
Map<String, Object?> familyViewFor(FamilyGame game, String? playerId) {
  String pub(String id) => familyPublicId(game, id);
  String? pubOrNull(String? id) => id == null ? null : pub(id);
  final inGame = playerId != null && game.player(playerId) != null;
  final myHead = inGame ? game.headOf(playerId) : null;
  final claim = inGame || playerId == null ? null : game.claimOf(playerId);
  return {
    'v': game.version,
    'me': inGame ? pub(playerId) : null,
    'myHead': pubOrNull(myHead),
    'canAsk': inGame && game.canAsk(playerId),
    'turn': pub(game.turn),
    'away': [for (final id in game.away) pub(id)],
    'claimable': inGame || game.isOver
        ? const <Object?>[]
        : [
            for (final p in game.claimable)
              if (playerId == null || !game.wasRefused(playerId, p.id)) {'id': pub(p.id), 'name': p.name},
          ],
    'myClaim': claim == null ? null : {'player': pub(claim.playerId), 'status': claim.status.name},
    'winner': pubOrNull(game.winner),
    'chatOn': game.chatEnabled,
    'players': [
      for (final p in game.players) {'id': pub(p.id), 'name': p.name, 'head': pub(game.headOf(p.id))},
    ],
    'slips': [
      for (final s in game.slips)
        {'id': s.id, 'text': s.text, if (game.revealed.contains(s.id)) 'writer': pub(s.writerId)},
    ],
    'families': [
      for (final head in game.familyHeads)
        {
          'head': pub(head),
          'members': [for (final m in game.membersOf(head)) pub(m)],
        },
    ],
    'ideas': myHead == null
        ? const <Object?>[]
        : [
            for (final s in game.suggestionsFor(myHead))
              {
                'target': pub(s.targetId),
                'slip': s.slipId,
                'votes': s.voters.length,
                'mine': s.voters.contains(playerId),
              },
          ],
    'chat': myHead == null || !game.chatEnabled
        ? const <Object?>[]
        : [
            for (final m in game.chatFor(myHead)) {'id': m.id, 'author': pub(m.authorId), 'text': m.text},
          ],
    'events': [
      for (final e in game.events.reversed.take(6))
        {'asker': pub(e.askerId), 'target': pub(e.targetId), 'slip': e.slipId, 'correct': e.correct},
    ],
  };
}
