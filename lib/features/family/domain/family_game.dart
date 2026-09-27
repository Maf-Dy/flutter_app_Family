import 'dart:math';

import 'package:flutter/foundation.dart';

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
  const ChatMessage({required this.id, required this.familyHead, required this.authorId, required this.text});

  static const maxLength = 200;

  final int id;

  /// The head of the family it was written in. Re-pointed when families merge.
  final String familyHead;
  final String authorId;
  final String text;
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

  FamilyActionError? _checkPick(String family, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (player(targetId) == null || headOf(targetId) == family) return FamilyActionError.invalidTarget;
    if (slip(slipId) == null || revealed.contains(slipId)) return FamilyActionError.invalidSlip;
    return null;
  }

  /// Why [askerId] can't make this guess right now, or null when they can.
  FamilyActionError? checkGuess(String askerId, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (headOf(askerId) != askerId) return FamilyActionError.notHead;
    if (turn != askerId) return FamilyActionError.notYourTurn;
    return _checkPick(askerId, targetId, slipId);
  }

  /// The head's guess. Check with [checkGuess] first.
  FamilyGame guess(String askerId, String targetId, int slipId) {
    if (checkGuess(askerId, targetId, slipId) != null) return this;
    // Duplicate names are allowed, so any hidden slip with the same text counts.
    final asked = slips[slipId].text.toLowerCase();
    final correct = hiddenSlips.any((s) => s.writerId == targetId && s.text.toLowerCase() == asked);
    final event = GuessEvent(askerId: askerId, targetId: targetId, slipId: slipId, correct: correct);
    if (!correct) {
      return _copy(turn: headOf(targetId), events: [...events, event], suggestions: {...suggestions}..remove(askerId));
    }
    final caught = headOf(targetId);
    return _copy(
      heads: {for (final MapEntry(:key, :value) in heads.entries) key: value == caught ? askerId : value},
      revealed: {
        ...revealed,
        for (final s in slips)
          if (s.writerId == targetId) s.id,
      },
      events: [...events, event],
      // The merged family starts planning afresh, and reads both families' chat.
      suggestions: {...suggestions}
        ..remove(askerId)
        ..remove(caught),
      chat: [
        for (final m in chat)
          m.familyHead == caught ? ChatMessage(id: m.id, familyHead: askerId, authorId: m.authorId, text: m.text) : m,
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

  FamilyGame say(String authorId, String text) {
    if (checkMessage(authorId, text) != null) return this;
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final message = ChatMessage(
      id: (chat.isEmpty ? 0 : chat.last.id) + 1,
      familyHead: headOf(authorId),
      authorId: authorId,
      text: clean.length > ChatMessage.maxLength ? clean.substring(0, ChatMessage.maxLength) : clean,
    );
    final all = [...chat, message];
    return _copy(chat: all.length > maxChat ? all.sublist(all.length - maxChat) : all);
  }

  /// Messages the family headed by [head] can read.
  List<ChatMessage> chatFor(String head) => [
    for (final m in chat)
      if (m.familyHead == head) m,
  ];

  FamilyGame _copy({
    Map<String, String>? heads,
    String? turn,
    Set<int>? revealed,
    Map<String, List<Suggestion>>? suggestions,
    List<ChatMessage>? chat,
    List<GuessEvent>? events,
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
  );
}
