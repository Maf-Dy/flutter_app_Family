import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../room/domain/room.dart';

/// Someone playing, with the name friends know them by.
@immutable
final class FamilyPlayer {
  const FamilyPlayer({required this.id, required this.name});

  final String id;
  final String name;
}

/// A name in play and who secretly wrote it.
@immutable
final class FamilySlip {
  const FamilySlip({required this.id, required this.text, required this.writerId});

  final int id;
  final String text;
  final String writerId;
}

/// A family member's idea for the head's next guess, with who backs it.
@immutable
final class Suggestion {
  const Suggestion({required this.targetId, required this.slipId, required this.voters});

  final String targetId;
  final int slipId;
  final Set<String> voters;
}

/// A private message inside one family.
@immutable
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.familyHead,
    required this.authorId,
    required this.text,
    this.nonce,
  });

  static const maxLength = 200;

  final int id;

  /// The head of the family it was written in. Re-pointed when families merge.
  final String familyHead;
  final String authorId;
  final String text;

  /// The sending phone's own id for this message, so a resend after a dropped
  /// connection isn't posted twice. Null for messages from the host's screen.
  final String? nonce;
}

/// A guess everyone can see, right or wrong.
@immutable
final class GuessEvent {
  const GuessEvent({required this.askerId, required this.targetId, required this.slipId, required this.correct});

  final String askerId;
  final String targetId;
  final int slipId;
  final bool correct;
}

enum ClaimStatus { pending, approved, denied }

/// Someone on a new phone or browser asking to take back the seat of a player
/// whose phone dropped out. The host decides.
@immutable
final class SeatClaim {
  const SeatClaim({required this.clientId, required this.playerId, this.status = ClaimStatus.pending});

  /// The browser asking. Never shown to other phones.
  final String clientId;

  /// The player whose seat they want back.
  final String playerId;
  final ClaimStatus status;
}

enum FamilyActionError {
  gameOver,
  notYourTurn,

  /// Only the head of the family makes the guess.
  notHead,

  /// The person asked is already in the asking family, or doesn't exist.
  invalidTarget,

  /// The name is already revealed, or doesn't exist.
  invalidSlip,
  chatOff,
  emptyMessage,
}

/// The classic Family game, refereed by the app: each player starts as their
/// own family. On your family's turn the head asks someone outside it "did you
/// write …?". Right, and that person's whole family joins yours and you go
/// again; wrong, and the turn passes to the family of the person asked. The
/// last family standing wins.
///
/// Immutable; every change bumps [version] so phones know when to redraw.
@immutable
final class FamilyGame {
  const FamilyGame._({
    required this.players,
    required this.slips,
    required this.heads,
    required this.turn,
    required this.revealed,
    required this.suggestions,
    required this.chat,
    required this.events,
    required this.chatEnabled,
    required this.version,
    this.away = const {},
    this.claims = const [],
  });

  factory FamilyGame.start({
    required List<FamilyPlayer> players,
    required List<({String text, String writerId})> slips,
    required bool chatEnabled,
    required Random random,
  }) {
    assert(players.length >= 2, 'A family game needs players');
    return FamilyGame._(
      players: List.unmodifiable(players),
      slips: List.unmodifiable([
        for (final (i, s) in ([...slips]..shuffle(random)).indexed)
          FamilySlip(id: i, text: s.text, writerId: s.writerId),
      ]),
      heads: Map.unmodifiable({for (final p in players) p.id: p.id}),
      turn: players[random.nextInt(players.length)].id,
      revealed: const {},
      suggestions: const {},
      chat: const [],
      events: const [],
      chatEnabled: chatEnabled,
      version: 1,
    );
  }

  static const maxChat = 150;

  final List<FamilyPlayer> players;
  final List<FamilySlip> slips;

  /// Each player's family, named by its head.
  final Map<String, String> heads;

  /// The head whose family is asking.
  final String turn;
  final Set<int> revealed;

  /// Per family head, the family's ideas for the next guess.
  final Map<String, List<Suggestion>> suggestions;
  final List<ChatMessage> chat;
  final List<GuessEvent> events;
  final bool chatEnabled;
  final int version;

  /// Players whose phone hasn't been heard from for a few seconds.
  final Set<String> away;

  /// Requests to take back a dropped player's seat, oldest first.
  final List<SeatClaim> claims;

  static const maxClaims = 10;

  String headOf(String playerId) => heads[playerId] ?? playerId;

  /// Heads still in the game, in join order.
  List<String> get familyHeads => [
    for (final p in players)
      if (heads[p.id] == p.id) p.id,
  ];

  List<String> membersOf(String head) => [
    for (final p in players)
      if (heads[p.id] == head) p.id,
  ];

  bool get isOver => familyHeads.length <= 1;
  String? get winner => isOver ? familyHeads.first : null;

  FamilyPlayer? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nameOf(String id) => player(id)?.name ?? '';

  FamilySlip? slip(int id) => id >= 0 && id < slips.length ? slips[id] : null;

  List<FamilySlip> get hiddenSlips => [
    for (final s in slips)
      if (!revealed.contains(s.id)) s,
  ];

  /// People the family headed by [head] may ask about.
  List<FamilyPlayer> targetsFor(String head) => [
    for (final p in players)
      if (headOf(p.id) != head) p,
  ];

  /// Whether [playerId]'s names are out: they were caught, so asking them again can't be right.
  bool isCaught(String playerId) => slips.any((s) => s.writerId == playerId && revealed.contains(s.id));

  /// The people worth asking: outside the family headed by [head], and not caught yet.
  List<FamilyPlayer> askableFor(String head) => [
    for (final p in targetsFor(head))
      if (!isCaught(p.id)) p,
  ];

  bool isAway(String playerId) => away.contains(playerId);

  /// Whether everyone in the family headed by [head] has dropped out.
  bool familyAway(String head) {
    final members = membersOf(head);
    return members.isNotEmpty && members.every(away.contains);
  }

  /// Whether [playerId] makes the guess now: the head on their family's turn,
  /// or any member still here when the head's phone has dropped out.
  bool canAsk(String playerId) {
    if (isOver || player(playerId) == null) return false;
    final family = headOf(playerId);
    if (turn != family) return false;
    return family == playerId || (away.contains(family) && !away.contains(playerId));
  }

  FamilyActionError? _checkPick(String family, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (player(targetId) == null || headOf(targetId) == family || isCaught(targetId)) {
      return FamilyActionError.invalidTarget;
    }
    if (slip(slipId) == null || revealed.contains(slipId)) return FamilyActionError.invalidSlip;
    return null;
  }

  /// Why [askerId] can't make this guess right now, or null when they can.
  FamilyActionError? checkGuess(String askerId, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (turn != headOf(askerId)) return FamilyActionError.notYourTurn;
    if (!canAsk(askerId)) return FamilyActionError.notHead;
    return _checkPick(turn, targetId, slipId);
  }

  /// The guess for the family whose turn it is. Check with [checkGuess] first.
  FamilyGame guess(String askerId, String targetId, int slipId) {
    if (checkGuess(askerId, targetId, slipId) != null) return this;
    final family = turn;
    // Duplicate names are allowed, so any hidden slip with the same text counts.
    final asked = Room.matchKey(slips[slipId].text);
    final correct = hiddenSlips.any((s) => s.writerId == targetId && Room.matchKey(s.text) == asked);
    final event = GuessEvent(askerId: askerId, targetId: targetId, slipId: slipId, correct: correct);
    if (!correct) {
      return _copy(turn: headOf(targetId), events: [...events, event], suggestions: {...suggestions}..remove(family));
    }
    final caught = headOf(targetId);
    return _copy(
      heads: {for (final MapEntry(:key, :value) in heads.entries) key: value == caught ? family : value},
      revealed: {
        ...revealed,
        for (final s in slips)
          if (s.writerId == targetId) s.id,
      },
      events: [...events, event],
      // The merged family starts planning afresh, and reads both families' chat.
      suggestions: {...suggestions}
        ..remove(family)
        ..remove(caught),
      chat: [
        for (final m in chat)
          m.familyHead == caught
              ? ChatMessage(id: m.id, familyHead: family, authorId: m.authorId, text: m.text, nonce: m.nonce)
              : m,
      ],
    );
  }

  /// A member backs an idea for the next guess. Each member backs one idea at a time.
  FamilyActionError? checkSuggestion(String memberId, String targetId, int slipId) =>
      player(memberId) == null ? FamilyActionError.invalidTarget : _checkPick(headOf(memberId), targetId, slipId);

  FamilyGame suggest(String memberId, String targetId, int slipId) {
    if (checkSuggestion(memberId, targetId, slipId) != null) return this;
    final family = headOf(memberId);
    final ideas = [
      for (final s in suggestions[family] ?? const <Suggestion>[])
        if (!(s.targetId == targetId && s.slipId == slipId)) _without(s, memberId),
    ];
    final existing = (suggestions[family] ?? const <Suggestion>[]).where(
      (s) => s.targetId == targetId && s.slipId == slipId,
    );
    final backed = Suggestion(
      targetId: targetId,
      slipId: slipId,
      voters: Set.unmodifiable({...?existing.firstOrNull?.voters, memberId}),
    );
    return _copy(
      suggestions: {
        ...suggestions,
        family: List.unmodifiable([backed, ...ideas.where((s) => s.voters.isNotEmpty)]),
      },
    );
  }

  /// A member withdraws their backing.
  FamilyGame unvote(String memberId) {
    final family = headOf(memberId);
    final ideas = suggestions[family];
    if (ideas == null) return this;
    return _copy(
      suggestions: {
        ...suggestions,
        family: List.unmodifiable([
          for (final s in ideas)
            if (_without(s, memberId) case final left when left.voters.isNotEmpty) left,
        ]),
      },
    );
  }

  static Suggestion _without(Suggestion s, String memberId) => s.voters.contains(memberId)
      ? Suggestion(targetId: s.targetId, slipId: s.slipId, voters: Set.unmodifiable({...s.voters}..remove(memberId)))
      : s;

  /// The family's ideas, most backed first.
  List<Suggestion> suggestionsFor(String head) =>
      [...?suggestions[head]]..sort((a, b) => b.voters.length.compareTo(a.voters.length));

  FamilyActionError? checkMessage(String authorId, String text) {
    if (!chatEnabled) return FamilyActionError.chatOff;
    if (player(authorId) == null) return FamilyActionError.invalidTarget;
    if (text.trim().isEmpty) return FamilyActionError.emptyMessage;
    return null;
  }

  /// Posts [text] to the author's family. A [nonce] the author already used is
  /// a resend of a message that did arrive, so it changes nothing.
  FamilyGame say(String authorId, String text, {String? nonce}) {
    if (checkMessage(authorId, text) != null) return this;
    if (nonce != null && chat.any((m) => m.authorId == authorId && m.nonce == nonce)) return this;
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final message = ChatMessage(
      id: (chat.isEmpty ? 0 : chat.last.id) + 1,
      familyHead: headOf(authorId),
      authorId: authorId,
      text: clean.length > ChatMessage.maxLength ? clean.substring(0, ChatMessage.maxLength) : clean,
      nonce: nonce,
    );
    final all = [...chat, message];
    return _copy(chat: all.length > maxChat ? all.sublist(all.length - maxChat) : all);
  }

  /// Messages the family headed by [head] can read.
  List<ChatMessage> chatFor(String head) => [
    for (final m in chat)
      if (m.familyHead == head) m,
  ];

  /// Who has dropped out. Returns this game unchanged when nothing changed.
  ///
  /// Asks for the seat of someone who came back are dropped: the seat is theirs
  /// again. Refusals are kept, so a refused phone can't simply ask again.
  FamilyGame withAway(Set<String> ids) {
    final next = {
      for (final id in ids)
        if (player(id) != null) id,
    };
    if (next.length == away.length && next.every(away.contains)) return this;
    return _copy(
      away: next,
      claims: [
        for (final c in claims)
          if (c.status == ClaimStatus.denied || next.contains(c.playerId)) c,
      ],
    );
  }

  /// Passes the turn on from a family whose phones have all dropped out.
  /// Only the host can do this; the game never skips anyone by itself.
  FamilyGame skipTurn() {
    if (isOver || !familyAway(turn)) return this;
    final order = familyHeads;
    final next = order[(order.indexOf(turn) + 1) % order.length];
    return _copy(turn: next, suggestions: {...suggestions}..remove(turn));
  }

  /// Players whose seat someone may ask for: dropped out, and not the host's phone.
  List<FamilyPlayer> get claimable => [
    for (final p in players)
      if (away.contains(p.id)) p,
  ];

  /// [clientId]'s latest ask.
  SeatClaim? claimOf(String clientId) {
    for (final c in claims.reversed) {
      if (c.clientId == clientId) return c;
    }
    return null;
  }

  /// Whether the host already turned [clientId] away from [playerId]'s seat.
  bool wasRefused(String clientId, String playerId) =>
      claims.any((c) => c.clientId == clientId && c.playerId == playerId && c.status == ClaimStatus.denied);

  /// [clientId] asks to take back [playerId]'s seat. Replaces any earlier open
  /// ask from the same browser, so each browser has at most one; a browser the
  /// host turned away can't ask for that seat again this game.
  FamilyGame claimSeat(String clientId, String playerId) {
    if (isOver || player(clientId) != null || !away.contains(playerId) || wasRefused(clientId, playerId)) {
      return this;
    }
    final others = [
      for (final c in claims)
        if (c.clientId != clientId || c.status == ClaimStatus.denied) c,
    ];
    final all = [...others, SeatClaim(clientId: clientId, playerId: playerId)];
    return _copy(claims: all.length > maxClaims ? all.sublist(all.length - maxClaims) : all);
  }

  /// The host lets [clientId] back in, or turns them away. A seat is only
  /// handed over while its player is still away.
  FamilyGame resolveClaim(String clientId, {required bool approve}) {
    final claim = claimOf(clientId);
    if (claim == null || claim.status != ClaimStatus.pending) return this;
    if (approve && !away.contains(claim.playerId)) return this;
    return _copy(
      claims: [
        for (final c in claims)
          identical(c, claim)
              ? SeatClaim(
                  clientId: c.clientId,
                  playerId: c.playerId,
                  status: approve ? ClaimStatus.approved : ClaimStatus.denied,
                )
              : c,
      ],
    );
  }

  /// Forgets [clientId]'s ask, once the seat was handed over.
  FamilyGame dropClaim(String clientId) => claimOf(clientId) == null
      ? this
      : _copy(
          claims: [
            for (final c in claims)
              if (c.clientId != clientId) c,
          ],
        );

  List<SeatClaim> get pendingClaims => [
    for (final c in claims)
      if (c.status == ClaimStatus.pending) c,
  ];

  FamilyGame _copy({
    Map<String, String>? heads,
    String? turn,
    Set<int>? revealed,
    Map<String, List<Suggestion>>? suggestions,
    List<ChatMessage>? chat,
    List<GuessEvent>? events,
    Set<String>? away,
    List<SeatClaim>? claims,
  }) => FamilyGame._(
    players: players,
    slips: slips,
    heads: heads == null ? this.heads : Map.unmodifiable(heads),
    turn: turn ?? this.turn,
    revealed: revealed == null ? this.revealed : Set.unmodifiable(revealed),
    suggestions: suggestions == null ? this.suggestions : Map.unmodifiable(suggestions),
    chat: chat == null ? this.chat : List.unmodifiable(chat),
    events: events == null ? this.events : List.unmodifiable(events),
    chatEnabled: chatEnabled,
    version: version + 1,
    away: away == null ? this.away : Set.unmodifiable(away),
    claims: claims == null ? this.claims : List.unmodifiable(claims),
  );
}
