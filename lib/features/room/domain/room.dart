import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../family/domain/family_game.dart';

import 'category.dart';

export 'category.dart';
export '../../family/domain/family_game.dart' show FamilyTwists;

/// How the room plays once the names are in.
enum GameMode {
  /// Read the names aloud, then play at the table.
  classic,

  /// Face-off: teams take turns guessing which player on another team wrote each name.
  celebrity,

  /// The classic game refereed by the app: families form on everyone's phones,
  /// and the head of each family makes the guess.
  family,
}

/// How players end up in teams in [GameMode.celebrity].
enum TeamPick {
  /// The app shuffles players into balanced teams.
  random,

  /// Friends choose on the join page; anyone who doesn't is balanced in.
  players,

  /// The host moves players between teams.
  host,
}

/// Team settings for [GameMode.celebrity].
@immutable
final class TeamSetup {
  const TeamSetup({this.count = 2, this.pick = TeamPick.random});

  static const minTeams = 2;
  static const maxTeams = 4;

  final int count;
  final TeamPick pick;

  TeamSetup copyWith({int? count, TeamPick? pick}) => TeamSetup(count: count ?? this.count, pick: pick ?? this.pick);

  @override
  bool operator ==(Object other) => other is TeamSetup && other.count == count && other.pick == pick;

  @override
  int get hashCode => Object.hash(count, pick);
}

enum RoomPhase {
  /// Friends can join and change their names.
  collecting,

  /// The host is reading; the bowl is closed until the next round.
  reading,
}

/// Why a submission was refused. Wording is chosen at the UI edge.
enum SubmissionError {
  roomClosed,
  missingName,
  missingSecret,
  tooLong,

  /// Someone already put this name in the bowl, and the room asks for different names.
  duplicate,

  /// A team was chosen that the room doesn't have.
  invalidTeam,

  /// Another player already goes by this name, so the reveal couldn't tell them apart.
  nameTaken,
}

/// One name in the bowl.
@immutable
final class Slip {
  const Slip({required this.text, required this.writerId, required this.writerName});

  final String text;
  final String writerId;
  final String writerName;
}

@immutable
final class Player {
  const Player({required this.id, required this.name, this.secrets = const [], this.isHost = false, this.team});

  static const hostId = 'host';

  final String id;
  final String name;
  final List<String> secrets;
  final bool isHost;

  /// The team the player chose on the join page (0-based), if the room lets them choose.
  final int? team;

  bool get hasSubmitted => secrets.isNotEmpty;

  Player withSecrets(List<String> secrets) =>
      Player(id: id, name: name, secrets: List.unmodifiable(secrets), isHost: isHost, team: team);
}

/// A game room: who joined, what they wrote, and whether the bowl is open.
///
/// Immutable. Every change returns a new [Room], so the host server and the
/// lobby screen always see the same consistent snapshot.
@immutable
final class Room {
  const Room({
    required this.code,
    required this.category,
    required this.namesPerPlayer,
    required this.hostName,
    this.allowDuplicates = true,
    this.mode = GameMode.classic,
    this.teamSetup = const TeamSetup(),
    this.familyChat = true,
    this.familyTwists = FamilyTwists.none,
    this.family,
    this.phase = RoomPhase.collecting,
    this.round = 1,
    this.players = const [],
  });

  static const minPlayers = 3;
  static const maxNamesPerPlayer = 3;

  /// Face-off gets easy with few names: once some writers are known, the rest
  /// follow by elimination. So it starts at 3 each and allows up to 5.
  static const maxFaceOffNames = 5;
  static const defaultFaceOffNames = 3;

  static int maxNamesFor(GameMode mode) => mode == GameMode.celebrity ? maxFaceOffNames : maxNamesPerPlayer;

  /// Names each after switching to [mode]: Face-off starts at 3 each, the other modes cap it again.
  static int namesForMode(int current, GameMode mode) => mode == GameMode.celebrity
      ? current.clamp(defaultFaceOffNames, maxFaceOffNames)
      : current.clamp(1, maxNamesPerPlayer);
  static const maxNameLength = 30;
  static const maxSecretLength = 60;
  static const maxPlayers = 30;

  final String code;
  final GameCategory category;
  final int namesPerPlayer;

  /// What the host is called in the lobby and the reveal.
  final String hostName;

  /// Whether two slips may carry the same name. Different spellings of one
  /// person always get through; that is part of the fun.
  final bool allowDuplicates;
  final GameMode mode;

  /// Only used in [GameMode.celebrity].
  final TeamSetup teamSetup;

  /// Whether families can message each other in [GameMode.family].
  final bool familyChat;

  /// House rules for [GameMode.family].
  final FamilyTwists familyTwists;

  /// The game in progress in [GameMode.family], once it has started.
  final FamilyGame? family;
  final RoomPhase phase;
  final int round;

  /// In join order; that order also picks each player's colour.
  final List<Player> players;

  bool get isCollecting => phase == RoomPhase.collecting;

  /// Players with all their names in. The host drops names in one at a time,
  /// so a host part-way through isn't in yet.
  List<Player> get playersIn => [
    for (final p in players)
      if (p.secrets.length >= namesPerPlayer) p,
  ];
  int get slipCount => players.fold(0, (sum, p) => sum + p.secrets.length);

  /// Players needed before the game can start: every team needs two players,
  /// so the other teams have someone to choose between.
  int get requiredPlayers => switch (mode) {
    GameMode.classic => minPlayers,
    GameMode.celebrity => teamSetup.count * 2,
    GameMode.family => minPlayers,
  };
  bool get canStart => playersIn.length >= requiredPlayers;
  int get playersNeeded => (requiredPlayers - playersIn.length).clamp(0, requiredPlayers);

  /// Whether friends pick their team on the join page.
  bool get playersPickTeams => mode == GameMode.celebrity && teamSetup.pick == TeamPick.players;

  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  int joinIndexOf(String playerId) => players.indexWhere((p) => p.id == playerId);

  Player? get host => playerById(Player.hostId);
  int get hostSecretsLeft => namesPerPlayer - (host?.secrets.length ?? 0);

  /// The names that go into the game: only from players who are all in.
  List<Slip> get slips => [
    for (final p in playersIn)
      for (final s in p.secrets) Slip(text: s, writerId: p.id, writerName: p.name),
  ];

  /// Checks a friend's form before it is accepted. Returns null when valid.
  /// [playerId] lets a friend resubmit their own names without clashing with themselves.
  SubmissionError? validate({required String name, required List<String> secrets, String? playerId, int? team}) {
    if (!isCollecting) return SubmissionError.roomClosed;
    if (team != null && (!playersPickTeams || team < 0 || team >= teamSetup.count)) return SubmissionError.invalidTeam;
    final cleanName = tidy(name);
    final cleanSecrets = secrets.map(tidy).toList();
    if (cleanName.isEmpty) return SubmissionError.missingName;
    if (_nameTaken(cleanName, exceptPlayer: playerId)) return SubmissionError.nameTaken;
    if (cleanSecrets.length != namesPerPlayer || cleanSecrets.any((s) => s.isEmpty)) {
      return SubmissionError.missingSecret;
    }
    if (cleanName.length > maxNameLength || cleanSecrets.any((s) => s.length > maxSecretLength)) {
      return SubmissionError.tooLong;
    }
    if (!allowDuplicates && _clashes(cleanSecrets, exceptPlayer: playerId)) return SubmissionError.duplicate;
    return null;
  }

  /// Why the host's own [secret] can't go in the bowl, or null when it can.
  SubmissionError? validateHostSecret(String secret) {
    final clean = tidy(secret);
    if (!isCollecting) return SubmissionError.roomClosed;
    if (clean.isEmpty) return SubmissionError.missingSecret;
    if (clean.length > maxSecretLength) return SubmissionError.tooLong;
    if (!allowDuplicates && _clashes([...?host?.secrets, clean], exceptPlayer: Player.hostId)) {
      return SubmissionError.duplicate;
    }
    return null;
  }

  bool _nameTaken(String name, {String? exceptPlayer}) {
    final key = matchKey(name);
    if (key.isEmpty) return false;
    if (matchKey(hostName) == key) return true;
    return players.any((p) => p.id != exceptPlayer && !p.isHost && matchKey(p.name) == key);
  }

  bool _clashes(List<String> secrets, {String? exceptPlayer}) {
    final taken = <String>{
      for (final p in players)
        if (p.id != exceptPlayer)
          for (final s in p.secrets) matchKey(s),
    };
    final mine = <String>{};
    for (final s in secrets) {
      final key = matchKey(s);
      if (taken.contains(key) || !mine.add(key)) return true;
    }
    return false;
  }

  /// Adds a friend, or replaces what they sent before. Call [validate] first.
  Room withSubmission({required String playerId, required String name, required List<String> secrets, int? team}) {
    assert(
      validate(name: name, secrets: secrets, playerId: playerId, team: team) == null,
      'Submission must be validated first',
    );
    final player = Player(id: playerId, name: tidy(name), secrets: List.unmodifiable(secrets.map(tidy)), team: team);
    final index = joinIndexOf(playerId);
    if (index < 0 && players.length >= maxPlayers) return this;
    return _copy(
      players: [
        if (index < 0) ...[...players, player] else for (final (i, p) in players.indexed) i == index ? player : p,
      ],
    );
  }

  /// Adds one of the host's own secret names, up to [namesPerPlayer].
  Room withHostSecret(String secret) {
    if (validateHostSecret(secret) != null || hostSecretsLeft <= 0) return this;
    final clean = tidy(secret);
    final current = host;
    if (current == null) {
      return _copy(
        players: [
          ...players,
          Player(id: Player.hostId, name: hostName, secrets: List.unmodifiable([clean]), isHost: true),
        ],
      );
    }
    return _copy(
      players: [
        for (final p in players) p.isHost ? p.withSecrets([...p.secrets, clean]) : p,
      ],
    );
  }

  /// The host takes a friend out of the room, e.g. an old entry left behind when
  /// their phone lost its cookie and they joined again. Only before the reading.
  Room withoutPlayer(String playerId) {
    final player = playerById(playerId);
    if (!isCollecting || player == null || player.isHost) return this;
    return _copy(
      players: [
        for (final p in players)
          if (p.id != playerId) p,
      ],
    );
  }

  Room startReading() => _copy(phase: RoomPhase.reading);

  /// Closes the bowl and deals the names into a [FamilyGame] everyone plays on their phone.
  Room startFamily(Random random) => _copy(
    phase: RoomPhase.reading,
    family: FamilyGame.start(
      players: [for (final p in playersIn) FamilyPlayer(id: p.id, name: p.name)],
      slips: [for (final s in slips) (text: s.text, writerId: s.writerId)],
      chatEnabled: familyChat,
      random: random,
      twists: familyTwists,
    ),
  );

  Room withFamily(FamilyGame game) => family == null ? this : _copy(family: game);

  /// Back to collecting without clearing the bowl, e.g. the host left the reading early.
  Room reopen() => _copy(phase: RoomPhase.collecting, clearFamily: true);

  /// Same players, empty bowl: everyone writes new names.
  Room nextRound() => _copy(
    phase: RoomPhase.collecting,
    round: round + 1,
    players: [for (final p in players) p.withSecrets(const [])],
    clearFamily: true,
  );

  Room _copy({RoomPhase? phase, int? round, List<Player>? players, FamilyGame? family, bool clearFamily = false}) =>
      Room(
        code: code,
        category: category,
        namesPerPlayer: namesPerPlayer,
        hostName: hostName,
        allowDuplicates: allowDuplicates,
        mode: mode,
        teamSetup: teamSetup,
        familyChat: familyChat,
        familyTwists: familyTwists,
        family: clearFamily ? null : family ?? this.family,
        phase: phase ?? this.phase,
        round: round ?? this.round,
        players: players == null ? this.players : List.unmodifiable(players),
      );

  /// Trims and collapses whitespace so "  Lionel   Messi " reads as "Lionel Messi".
  static String tidy(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// A spelling-tolerant key for spotting the same name twice: ignores case,
  /// spaces, punctuation, Arabic diacritics and the usual Arabic letter variants
  /// (أ إ آ ا, ة ه, ى ي). Real misspellings still count as different names.
  static String matchKey(String name) {
    final key = _lettersKey(name);
    return key.isEmpty ? tidy(name) : key;
  }

  static String _lettersKey(String name) => tidy(name)
      .toLowerCase()
      .replaceAll(RegExp('[ً-ٰٟـ]'), '')
      .replaceAll(RegExp('[آأإٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
}
