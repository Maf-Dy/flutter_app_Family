import 'package:flutter/foundation.dart';

enum RoomPhase {
  /// Friends can join and change their names.
  collecting,

  /// The host is reading; the bowl is closed until the next round.
  reading,
}

/// Why a submission was refused. Wording is chosen at the UI edge.
enum SubmissionError { roomClosed, missingName, missingSecret, tooLong }

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
  const Player({required this.id, required this.name, this.secrets = const [], this.isHost = false});

  static const hostId = 'host';

  final String id;
  final String name;
  final List<String> secrets;
  final bool isHost;

  bool get hasSubmitted => secrets.isNotEmpty;

  Player withSecrets(List<String> secrets) =>
      Player(id: id, name: name, secrets: List.unmodifiable(secrets), isHost: isHost);
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
    this.phase = RoomPhase.collecting,
    this.round = 1,
    this.players = const [],
  });

  static const minPlayers = 3;
  static const maxNamesPerPlayer = 3;
  static const maxNameLength = 30;
  static const maxSecretLength = 60;
  static const maxPlayers = 30;

  final String code;
  final String category;
  final int namesPerPlayer;
  final RoomPhase phase;
  final int round;

  /// In join order; that order also picks each player's colour.
  final List<Player> players;

  bool get isCollecting => phase == RoomPhase.collecting;
  List<Player> get playersIn => [
    for (final p in players)
      if (p.hasSubmitted) p,
  ];
  int get slipCount => players.fold(0, (sum, p) => sum + p.secrets.length);
  bool get canStart => playersIn.length >= minPlayers;
  int get playersNeeded => (minPlayers - playersIn.length).clamp(0, minPlayers);

  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  int joinIndexOf(String playerId) => players.indexWhere((p) => p.id == playerId);

  Player? get host => playerById(Player.hostId);
  int get hostSecretsLeft => namesPerPlayer - (host?.secrets.length ?? 0);

  List<Slip> get slips => [
    for (final p in players)
      for (final s in p.secrets) Slip(text: s, writerId: p.id, writerName: p.name),
  ];

  /// Checks a friend's form before it is accepted. Returns null when valid.
  SubmissionError? validate({required String name, required List<String> secrets}) {
    if (!isCollecting) return SubmissionError.roomClosed;
    final cleanName = tidy(name);
    final cleanSecrets = secrets.map(tidy).toList();
    if (cleanName.isEmpty) return SubmissionError.missingName;
    if (cleanSecrets.length != namesPerPlayer || cleanSecrets.any((s) => s.isEmpty)) {
      return SubmissionError.missingSecret;
    }
    if (cleanName.length > maxNameLength || cleanSecrets.any((s) => s.length > maxSecretLength)) {
      return SubmissionError.tooLong;
    }
    return null;
  }

  /// Adds a friend, or replaces what they sent before. Call [validate] first.
  Room withSubmission({required String playerId, required String name, required List<String> secrets}) {
    assert(validate(name: name, secrets: secrets) == null, 'Submission must be validated first');
    final player = Player(id: playerId, name: tidy(name), secrets: List.unmodifiable(secrets.map(tidy)));
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
    final clean = tidy(secret);
    if (!isCollecting || clean.isEmpty || clean.length > maxSecretLength || hostSecretsLeft <= 0) return this;
    final current = host;
    if (current == null) {
      return _copy(
        players: [
          ...players,
          Player(id: Player.hostId, name: 'You', secrets: List.unmodifiable([clean]), isHost: true),
        ],
      );
    }
    return _copy(
      players: [
        for (final p in players) p.isHost ? p.withSecrets([...p.secrets, clean]) : p,
      ],
    );
  }

  Room startReading() => _copy(phase: RoomPhase.reading);

  /// Back to collecting without clearing the bowl, e.g. the host left the reading early.
  Room reopen() => _copy(phase: RoomPhase.collecting);

  /// Same players, empty bowl: everyone writes new names.
  Room nextRound() =>
      _copy(phase: RoomPhase.collecting, round: round + 1, players: [for (final p in players) p.withSecrets(const [])]);

  Room _copy({RoomPhase? phase, int? round, List<Player>? players}) => Room(
    code: code,
    category: category,
    namesPerPlayer: namesPerPlayer,
    phase: phase ?? this.phase,
    round: round ?? this.round,
    players: players == null ? this.players : List.unmodifiable(players),
  );

  /// Trims and collapses whitespace so "  Lionel   Messi " reads as "Lionel Messi".
  static String tidy(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');
}
