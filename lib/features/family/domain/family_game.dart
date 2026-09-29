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
  const FamilySlip({required this.id, required this.text, required this.writerId, this.ink});

  final int id;
  final String text;
  final String writerId;

  /// The name as written by hand, when the room asked for handwriting.
  final SlipInk? ink;
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

/// Optional twists on the family game, switched on when the room opens.
@immutable
final class FamilyTwists {
  const FamilyTwists({this.secretCatches = false, this.rumors = false, this.letMeGo = false});

  static const none = FamilyTwists();

  /// Only the asking family sees the result. A caught person joins in secret
  /// and keeps playing as if free; turns go round every player, so nobody can
  /// tell from the turn order who was caught.
  final bool secretCatches;

  /// Once a game, each player may spread an anonymous rumor: "X wrote Y".
  final bool rumors;

  /// "فكّك مني": one card goes round the game. Whoever holds it may cancel an
  /// ask about them: nobody learns whether it was right, the asker loses the
  /// turn, and the card passes to the asker.
  final bool letMeGo;

  bool get any => secretCatches || rumors || letMeGo;

  FamilyTwists copyWith({bool? secretCatches, bool? rumors, bool? letMeGo}) => FamilyTwists(
    secretCatches: secretCatches ?? this.secretCatches,
    rumors: rumors ?? this.rumors,
    letMeGo: letMeGo ?? this.letMeGo,
  );

  @override
  bool operator ==(Object other) =>
      other is FamilyTwists &&
      other.secretCatches == secretCatches &&
      other.rumors == rumors &&
      other.letMeGo == letMeGo;

  @override
  int get hashCode => Object.hash(secretCatches, rumors, letMeGo);
}

/// A guess, right or wrong. With secret catches only the families involved see it.
@immutable
final class GuessEvent {
  const GuessEvent({
    required this.askerId,
    required this.targetId,
    required this.slipId,
    required this.correct,
    this.blocked = false,
    this.swallowedHead,
    this.intoHead,
    this.joined = const [],
  });

  final String askerId;
  final String targetId;
  final int slipId;

  /// Whether the target wrote the name. Meaningless when [blocked].
  final bool correct;

  /// The target said "فكّك مني": the ask was cancelled unanswered.
  final bool blocked;

  /// The head of the family that was swallowed, when this guess caught someone.
  final String? swallowedHead;

  /// The head of the family that swallowed it.
  final String? intoHead;

  /// Everyone who changed family because of this guess.
  final List<String> joined;

  bool get caught => swallowedHead != null;
}

/// Something the game waits on before anyone else can ask.
enum PendingKind {
  /// The person asked may say "فكّك مني".
  letMeGo,
}

@immutable
final class PendingMove {
  const PendingMove({required this.kind, required this.askerId, required this.targetId, required this.slipId});

  final PendingKind kind;

  /// Who made the ask this waits on.
  final String askerId;

  /// Who was asked. They answer the pending move.
  final String targetId;
  final int slipId;

  String get responderId => targetId;
}

/// An anonymous rumor everyone sees: "they say [targetId] wrote [slipId]".
@immutable
final class Rumor {
  const Rumor({required this.id, required this.authorId, required this.targetId, required this.slipId});

  final int id;

  /// Never shown to anyone.
  final String authorId;
  final String targetId;
  final int slipId;
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

  /// The game waits on someone's answer to "فكّك مني".
  waiting,

  /// That twist is off, not yours to answer, or already used.
  notAllowed,

  /// A name typed from memory matches none still in play.
  unknownName,
}

/// The classic Family game, refereed by the app: each player starts as their
/// own family. On your family's turn the head asks someone outside it "did you
/// write …?". Right, and that person's whole family joins yours and you go
/// again; wrong, and the turn passes to the family of the person asked. The
/// last family standing wins. [FamilyTwists] add optional house rules.
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
    this.twists = FamilyTwists.none,
    this.turnPlayer = '',
    this.known = const {},
    this.pending,
    this.cardHolder,
    this.rumors = const [],
    this.seed = 0,
  });

  factory FamilyGame.start({
    required List<FamilyPlayer> players,
    required List<({String text, String writerId})> slips,
    required bool chatEnabled,
    required Random random,
    FamilyTwists twists = FamilyTwists.none,

    /// The drawing behind each of [slips], by position, for handwritten names.
    List<SlipInk?> inks = const [],
  }) {
    assert(players.length >= 2, 'A family game needs players');
    final dealt = [
      for (final (i, (j, s)) in ([...slips.indexed]..shuffle(random)).indexed)
        FamilySlip(id: i, text: s.text, writerId: s.writerId, ink: j < inks.length ? inks[j] : null),
    ];
    final first = players[random.nextInt(players.length)].id;
    final seed = random.nextInt(1 << 30);
    final game = FamilyGame._(
      players: List.unmodifiable(players),
      slips: List.unmodifiable(dealt),
      heads: Map.unmodifiable({for (final p in players) p.id: p.id}),
      turn: first,
      revealed: const {},
      suggestions: const {},
      chat: const [],
      events: const [],
      chatEnabled: chatEnabled,
      version: 1,
      twists: twists,
      turnPlayer: first,
      // Everyone knows their own names.
      known: Map.unmodifiable({
        for (final p in players)
          p.id: Set<int>.unmodifiable({
            for (final s in dealt)
              if (s.writerId == p.id) s.id,
          }),
      }),
      seed: seed,
      // The one "فكّك مني" card starts with someone at random.
      cardHolder: twists.letMeGo ? players[seed % players.length].id : null,
    );
    return game;
  }

  static const maxChat = 150;
  static const maxRumors = 30;

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

  final FamilyTwists twists;

  /// With secret catches, turns go round every player, not every family: the
  /// player asking now. Otherwise the same as [turn].
  final String turnPlayer;

  /// Per family head, the names that family knows the writer of. Everyone
  /// knows their own; a catch shares what both families knew.
  final Map<String, Set<int>> known;

  /// What the game waits on before the next ask.
  final PendingMove? pending;

  /// Who holds the one "فكّك مني" card, when that twist is on.
  final String? cardHolder;

  /// Players who already spread their rumor are in here as authors.
  final List<Rumor> rumors;

  /// Fixed per game, so the same game always deals the same way.
  final int seed;

  bool get secret => twists.secretCatches;

  /// Who asks now: the head on their family's turn, or with secret catches the player on turn.
  String get asker => secret ? turnPlayer : turn;

  /// The one person the game waits on to answer, if any.
  String? get waitingOn => pending?.responderId;

  /// Whether the turn is stuck on someone whose phone dropped out, so only the host can move it on.
  bool get turnStalled {
    if (isOver) return false;
    final waiting = waitingOn;
    if (waiting != null) return away.contains(waiting);
    return secret ? away.contains(turnPlayer) : familyAway(turn);
  }

  Set<int> knownBy(String head) => known[head] ?? const {};

  /// Whether the family headed by [head] knows who wrote slip [slipId]: always
  /// for revealed names, and with secret catches only for names it caught.
  bool knowsWriter(String head, int slipId) =>
      secret ? knownBy(head).contains(slipId) || isOver : revealed.contains(slipId);

  bool hasCard(String playerId) => twists.letMeGo && cardHolder == playerId;

  bool canSpreadRumor(String playerId) =>
      twists.rumors && !isOver && player(playerId) != null && !rumors.any((r) => r.authorId == playerId);

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

  /// Everyone the family headed by [head] may ask: anyone outside it. The app
  /// doesn't narrow it down; remembering who is worth asking is the game.
  List<FamilyPlayer> askableFor(String head) => targetsFor(head);

  /// Whether names are drawn by hand, so they're picked from the drawings instead of typed.
  bool get handwritten => slips.any((s) => s.ink != null);

  /// The slip a name typed from memory means, for the family headed by [head]:
  /// a name still open to that family that reads the same as [text]. When
  /// [targetId] wrote one of them, that one; with no [head], any name not out yet.
  /// Null when no such name is left.
  int? slipNamed(String text, {String? head, String? targetId}) {
    final key = Room.matchKey(text);
    if (key.isEmpty) return null;
    final open = [
      for (final s in slips)
        if (s.text.isNotEmpty &&
            Room.matchKey(s.text) == key &&
            (head == null ? !revealed.contains(s.id) : !knowsWriter(head, s.id)))
          s,
    ];
    if (open.isEmpty) return null;
    return (open.where((s) => s.writerId == targetId).firstOrNull ?? open.first).id;
  }

  bool isAway(String playerId) => away.contains(playerId);

  /// Whether everyone in the family headed by [head] has dropped out.
  bool familyAway(String head) {
    final members = membersOf(head);
    return members.isNotEmpty && members.every(away.contains);
  }

  /// Whether [playerId] makes the guess now: the head on their family's turn,
  /// or any member still here when the head's phone has dropped out.
  bool canAsk(String playerId) {
    if (isOver || pending != null || player(playerId) == null) return false;
    if (secret) return playerId == turnPlayer;
    final family = headOf(playerId);
    if (turn != family) return false;
    return family == playerId || (away.contains(family) && !away.contains(playerId));
  }

  FamilyActionError? _checkPick(String family, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (player(targetId) == null || headOf(targetId) == family) {
      return FamilyActionError.invalidTarget;
    }
    if (slip(slipId) == null || knowsWriter(family, slipId)) return FamilyActionError.invalidSlip;
    return null;
  }

  /// Why [askerId] can't make this guess right now, or null when they can.
  FamilyActionError? checkGuess(String askerId, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (pending != null) return FamilyActionError.waiting;
    if (secret ? askerId != turnPlayer : turn != headOf(askerId)) return FamilyActionError.notYourTurn;
    if (!canAsk(askerId)) return FamilyActionError.notHead;
    return _checkPick(headOf(askerId), targetId, slipId);
  }

  /// The guess for the family whose turn it is. Check with [checkGuess] first.
  ///
  /// With "فكّك مني" on, the person asked answers first ([answerLetMeGo]).
  FamilyGame guess(String askerId, String targetId, int slipId) {
    if (checkGuess(askerId, targetId, slipId) != null) return this;
    if (hasCard(targetId) && !away.contains(targetId)) {
      return _copy(
        pending: PendingMove(kind: PendingKind.letMeGo, askerId: askerId, targetId: targetId, slipId: slipId),
      );
    }
    return _settleAsk(askerId, targetId, slipId);
  }

  /// Whether [targetId] wrote a name the same as slip [slipId]. Duplicate names
  /// are allowed, so either copy counts. Names already caught don't count again,
  /// except with secret catches, where nobody else knows they were caught.
  bool _wrote(String targetId, int slipId) {
    final asked = slips[slipId];
    return slips.any((s) => s.writerId == targetId && (secret || !revealed.contains(s.id)) && _sameName(s, asked));
  }

  static bool _sameName(FamilySlip a, FamilySlip b) =>
      a.id == b.id || (a.text.isNotEmpty && Room.matchKey(a.text) == Room.matchKey(b.text));

  /// An ask gets its answer.
  FamilyGame _settleAsk(String askerId, String targetId, int slipId) {
    final family = headOf(askerId);
    final correct = _wrote(targetId, slipId);
    final event = GuessEvent(askerId: askerId, targetId: targetId, slipId: slipId, correct: correct);
    final cleared = {...suggestions}..remove(family);
    if (correct) {
      return _swallow(into: family, person: targetId, event: event)._nextTurn(askerId, keep: true);
    }
    return _copy(events: [...events, event], suggestions: cleared)._afterMiss(askerId, targetId);
  }

  /// After a wrong ask: the turn goes to the family asked.
  FamilyGame _afterMiss(String askerId, String targetId) => _nextTurn(askerId, keep: false, toward: headOf(targetId));

  /// Hands the turn on after [askerId]'s move. [keep]: their family asks again.
  /// [toward]: the family the turn goes to, when it doesn't stay.
  FamilyGame _nextTurn(String askerId, {required bool keep, String? toward}) {
    if (isOver) return _copy(clearPending: true);
    if (secret) {
      // Turns go round everyone, so the turn order gives no catch away.
      final next = _playerAfter(askerId);
      return _copy(clearPending: true, turnPlayer: next, turn: headOf(next));
    }
    final head = keep ? headOf(askerId) : headOf(toward ?? _headAfter(headOf(askerId)));
    return _copy(clearPending: true, turn: head, turnPlayer: head);
  }

  String _playerAfter(String playerId) {
    final i = players.indexWhere((p) => p.id == playerId);
    return players[(i + 1) % players.length].id;
  }

  /// The next family in join order after the one headed by [head].
  String _headAfter(String head) {
    final order = familyHeads;
    final i = order.indexOf(head);
    return i < 0 ? order.first : order[(i + 1) % order.length];
  }

  Set<int> _slipsBy(String playerId) => {
    for (final s in slips)
      if (s.writerId == playerId) s.id,
  };

  /// [person] was caught: their whole family joins the family headed by [into].
  FamilyGame _swallow({required String into, required String person, required GuessEvent event}) {
    final caught = headOf(person);
    final joined = membersOf(caught);
    final recorded = GuessEvent(
      askerId: event.askerId,
      targetId: event.targetId,
      slipId: event.slipId,
      correct: event.correct,
      swallowedHead: caught,
      intoHead: into,
      joined: List.unmodifiable(joined),
    );
    final history = [...events, recorded];
    final merged = _copy(
      heads: {for (final MapEntry(:key, :value) in heads.entries) key: value == caught ? into : value},
      revealed: {...revealed, ..._slipsBy(person)},
      events: history,
      known: {
        for (final MapEntry(:key, :value) in known.entries)
          if (key != caught) key: key == into ? {...value, ...knownBy(caught), ..._slipsBy(person)} : value,
      },
      // The merged family starts planning afresh, and reads both families' chat.
      suggestions: {...suggestions}
        ..remove(into)
        ..remove(caught),
      chat: [
        for (final m in chat)
          m.familyHead == caught
              ? ChatMessage(id: m.id, familyHead: into, authorId: m.authorId, text: m.text, nonce: m.nonce)
              : m,
      ],
      turn: turn == caught ? into : turn,
    );
    return merged;
  }

  /// Why [playerId] can't answer what the game waits on, or null when they can.
  FamilyActionError? checkAnswer(String playerId, PendingKind kind) {
    if (isOver) return FamilyActionError.gameOver;
    final move = pending;
    if (move == null || move.kind != kind || move.responderId != playerId) return FamilyActionError.notAllowed;
    return null;
  }

  /// The person asked says "فكّك مني" ([use]) or lets the ask be answered.
  FamilyGame answerLetMeGo(String playerId, {required bool use}) {
    if (checkAnswer(playerId, PendingKind.letMeGo) != null) return this;
    final move = pending!;
    final cleared = _copy(clearPending: true);
    if (!use) return cleared._settleAsk(move.askerId, move.targetId, move.slipId);
    final event = GuessEvent(
      askerId: move.askerId,
      targetId: move.targetId,
      slipId: move.slipId,
      correct: false,
      blocked: true,
    );
    return cleared
        ._copy(
          events: [...events, event],
          // Hot potato: the card passes to the one who asked.
          cardHolder: move.askerId,
          suggestions: {...suggestions}..remove(headOf(move.askerId)),
        )
        ._nextTurn(move.askerId, keep: false);
  }

  FamilyActionError? checkRumor(String authorId, String targetId, int slipId) {
    if (isOver) return FamilyActionError.gameOver;
    if (!canSpreadRumor(authorId)) return FamilyActionError.notAllowed;
    if (player(targetId) == null) return FamilyActionError.invalidTarget;
    if (slip(slipId) == null || revealed.contains(slipId)) return FamilyActionError.invalidSlip;
    return null;
  }

  /// [authorId] spreads their one anonymous rumor: "they say [targetId] wrote [slipId]".
  FamilyGame spreadRumor(String authorId, String targetId, int slipId) {
    if (checkRumor(authorId, targetId, slipId) != null) return this;
    final rumor = Rumor(
      id: (rumors.isEmpty ? 0 : rumors.last.id) + 1,
      authorId: authorId,
      targetId: targetId,
      slipId: slipId,
    );
    return _copy(rumors: [...rumors, rumor]);
  }

  /// Names the family headed by [head] may still ask about: any whose writer it doesn't know.
  List<FamilySlip> slipsOpenTo(String head) => [
    for (final s in slips)
      if (!knowsWriter(head, s.id)) s,
  ];

  /// Whether [viewerId] sees who wrote slip [slipId] on the board.
  bool writerShownTo(String? viewerId, int slipId) {
    if (!secret || isOver) return revealed.contains(slipId);
    return viewerId != null && player(viewerId) != null && knowsWriter(headOf(viewerId), slipId);
  }

  /// The families as [viewerId] sees them, by head in join order. With secret
  /// catches everyone outside the viewer's family looks like they're on their own.
  List<String> familyHeadsSeenBy(String? viewerId) => [
    for (final p in players)
      if (headSeenBy(viewerId, p.id) == p.id) p.id,
  ];

  List<String> membersSeenBy(String? viewerId, String head) => [
    for (final p in players)
      if (headSeenBy(viewerId, p.id) == head) p.id,
  ];

  /// Guesses [viewerId] may see. With secret catches, others' asks show only
  /// that someone asked: [GuessEvent]s for the viewer's own family and asks
  /// about the viewer come through whole.
  bool seesEvent(String? viewerId, GuessEvent e) {
    if (!secret || isOver) return true;
    if (viewerId == null || player(viewerId) == null) return false;
    final family = headOf(viewerId);
    return e.askerId == viewerId ||
        e.targetId == viewerId ||
        headOf(e.askerId) == family ||
        e.joined.contains(viewerId) ||
        e.intoHead == family;
  }

  /// The family [viewerId] sees [playerId] in: the truth, or with secret
  /// catches only for their own family (others look like they're on their own).
  String headSeenBy(String? viewerId, String playerId) {
    if (!secret || isOver) return headOf(playerId);
    if (viewerId != null && player(viewerId) != null && headOf(playerId) == headOf(viewerId)) {
      return headOf(playerId);
    }
    return playerId;
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
  ///
  /// When the game waits on a dropped player's answer, it goes on as if they
  /// passed.
  FamilyGame skipTurn() {
    if (!turnStalled) return this;
    final move = pending;
    if (move != null) {
      return switch (move.kind) {
        PendingKind.letMeGo => answerLetMeGo(move.responderId, use: false),
      };
    }
    if (secret) {
      final next = _playerAfter(turnPlayer);
      return _copy(turnPlayer: next, turn: headOf(next), suggestions: {...suggestions}..remove(turn));
    }
    final order = familyHeads;
    final next = order[(order.indexOf(turn) + 1) % order.length];
    return _copy(turn: next, turnPlayer: next, suggestions: {...suggestions}..remove(turn));
  }

  /// Players whose seat someone may ask for: dropped out, and not the host's phone.
  /// The host's seat is never up for grabs: their phone runs the game.
  List<FamilyPlayer> get claimable => [
    for (final p in players)
      if (away.contains(p.id) && p.id != Player.hostId) p,
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
    if (isOver ||
        playerId == Player.hostId ||
        player(clientId) != null ||
        !away.contains(playerId) ||
        wasRefused(clientId, playerId)) {
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
    String? turnPlayer,
    Map<String, Set<int>>? known,
    PendingMove? pending,
    bool clearPending = false,
    String? cardHolder,
    List<Rumor>? rumors,
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
    twists: twists,
    turnPlayer: turnPlayer ?? this.turnPlayer,
    known: known == null
        ? this.known
        : Map.unmodifiable({for (final e in known.entries) e.key: Set<int>.unmodifiable(e.value)}),
    pending: pending ?? (clearPending ? null : this.pending),
    cardHolder: cardHolder ?? this.cardHolder,
    rumors: rumors == null
        ? this.rumors
        : List.unmodifiable(rumors.length > maxRumors ? rumors.sublist(rumors.length - maxRumors) : rumors),
    seed: seed,
  );
}
