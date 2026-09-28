import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../family/domain/family_game.dart';
import '../domain/room.dart';
import '../domain/room_host.dart';
import 'join_page.dart';
import 'join_strings.dart';
import 'family_view.dart';

/// Serves the room over plain HTTP on this phone, so friends only need a browser.
///
/// Listens on every IPv4 interface, so the same server keeps working when the
/// phone moves between Wi-Fi, its own hotspot, or the hotspot the app creates.
class LanRoomHost implements RoomHost {
  LanRoomHost({
    this.preferredPort = 8182,
    Random? random,
    DateTime Function()? clock,
    this.awayAfter = const Duration(seconds: 6),
    this.presenceTick = const Duration(seconds: 1),
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now;

  static const cookieName = 'family_id';
  static const _maxBodyBytes = 8 * 1024;

  final int preferredPort;
  final Random _random;
  final DateTime Function() _clock;

  /// How long a friend's phone can go quiet before the game shows them as offline.
  /// Their page asks for news every 1.5 s, so this is a few missed calls.
  final Duration awayAfter;
  final Duration presenceTick;
  final _changes = StreamController<Room>.broadcast();
  HttpServer? _server;
  Timer? _presence;
  late Room _room;

  /// When each friend's phone was last heard from.
  final _seen = <String, DateTime>{};

  @override
  Room get room => _room;

  @override
  Stream<Room> get changes => _changes.stream;

  @override
  Future<int> open(Room room) async {
    _room = room;
    final server = await _bind();
    _server = server;
    server.listen(_handle, onError: (Object error) => debugPrint('LanRoomHost: $error'));
    _presence = Timer.periodic(presenceTick, (_) => _presenceTick());
    return server.port;
  }

  Future<HttpServer> _bind() async {
    try {
      return await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
    } on SocketException {
      // Port taken, e.g. by a room that is still closing: let the system pick one.
      try {
        return await HttpServer.bind(InternetAddress.anyIPv4, 0);
      } on SocketException catch (error) {
        throw RoomHostException(error.message);
      }
    }
  }

  @override
  void update(Room Function(Room room) change) => _set(change(_room));

  void _set(Room next) {
    if (identical(next, _room)) return;
    // A new family game (e.g. a new round): old sightings say nothing about it.
    if (next.family != null && !identical(next.family!.players, _room.family?.players)) _seen.clear();
    _room = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  @override
  Future<void> close() async {
    final server = _server;
    _server = null;
    _presence?.cancel();
    _presence = null;
    await server?.close(force: true);
    // Not awaited: a broadcast controller's close completes only once every
    // listener has seen "done", and a listener mid-cancel would stall shutdown.
    unawaited(_changes.close());
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      var clientId = _clientIdOf(request);
      if (clientId == null) {
        final fresh = _newClientId();
        response.cookies.add(_cookie(fresh));
        // A first visit that posts straight away (cookies were cleared, or the
        // page came from another address) still gets its names in.
        if (request.method == 'POST' && request.uri.path == '/') clientId = fresh;
      } else {
        clientId = _takeBackSeat(clientId, response);
        _heardFrom(clientId);
      }
      final player = clientId == null ? null : _room.playerById(clientId);
      final strings = JoinStrings.forAcceptLanguage(request.headers.value(HttpHeaders.acceptLanguageHeader));
      switch ((request.method, request.uri.path)) {
        case ('GET', '/'):
          _html(response, _pageFor(strings, player, editing: request.uri.queryParameters.containsKey('edit')));
        case ('POST', '/'):
          await _submit(request, strings, clientId, player);
        case ('GET', '/status'):
          response.headers
            ..contentType = ContentType.json
            ..set(HttpHeaders.cacheControlHeader, 'no-store');
          response.write(jsonEncode({'count': _room.slipCount, 'version': JoinPage.versionFor(_room, player)}));
        case ('GET', '/game'):
          final game = _room.family;
          if (game == null) {
            response.statusCode = HttpStatus.notFound;
          } else {
            _json(response, familyViewFor(game, clientId));
          }
        case ('POST', '/game/guess' || '/game/suggest' || '/game/unvote' || '/game/say'):
          await _familyAction(request, clientId, request.uri.pathSegments.last);
        case ('POST', '/game/claim'):
          await _claim(request, clientId);
        case ('GET', '/favicon.ico'):
          response.statusCode = HttpStatus.noContent;
        default:
          response.statusCode = HttpStatus.notFound;
          response.write('Not found');
      }
    } catch (error) {
      debugPrint('LanRoomHost: request failed ($error)');
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  }

  String _pageFor(JoinStrings strings, Player? player, {required bool editing}) {
    if (_room.family != null) return JoinPage.family(_room, strings, player);
    if (!_room.isCollecting) return JoinPage.reading(_room, strings, player);
    if (player != null && player.hasSubmitted && !editing) return JoinPage.done(_room, strings, player);
    if (player == null && _room.players.length >= Room.maxPlayers) return JoinPage.full(_room, strings);
    return JoinPage.form(_room, strings, player: player);
  }

  Future<void> _submit(HttpRequest request, JoinStrings strings, String? clientId, Player? player) async {
    final response = request.response;
    final form = await _readForm(request);
    if (form == null) {
      response.statusCode = HttpStatus.requestEntityTooLarge;
      return;
    }
    // A page left open from an earlier room on this address: show this room's form instead.
    final code = form['code'];
    if (code != null && code != _room.code) {
      response
        ..statusCode = HttpStatus.seeOther
        ..headers.set(HttpHeaders.locationHeader, '/');
      return;
    }
    final name = form['name'] ?? '';
    final secrets = [for (var i = 0; i < _room.namesPerPlayer; i++) form['s$i'] ?? ''];
    final team = int.tryParse(form['team'] ?? '');
    final error = _room.playersPickTeams && team == null
        ? SubmissionError.invalidTeam
        : _room.validate(name: name, secrets: secrets, playerId: clientId, team: team);
    if (error != null || clientId == null) {
      response.statusCode = error == SubmissionError.roomClosed ? HttpStatus.conflict : HttpStatus.badRequest;
      _html(
        response,
        error == SubmissionError.roomClosed
            ? JoinPage.reading(_room, strings, player)
            : JoinPage.form(_room, strings, player: player, name: name, secrets: secrets, error: error, team: team),
      );
      return;
    }
    _set(_room.withSubmission(playerId: clientId, name: name, secrets: secrets, team: team));
    response
      ..statusCode = HttpStatus.seeOther
      ..headers.set(HttpHeaders.locationHeader, '/');
  }

  /// A move in the family game from a friend's phone. Answers `{"error": null}` or the reason it was refused.
  Future<void> _familyAction(HttpRequest request, String? clientId, String action) async {
    final response = request.response;
    final form = await _readForm(request);
    final game = _room.family;
    if (game == null || form == null || clientId == null || game.player(clientId) == null) {
      response.statusCode = HttpStatus.forbidden;
      _json(response, {'error': 'notPlaying'});
      return;
    }
    // Phones name players by their public id; the real id is someone's cookie.
    final target = familyPlayerIdFor(game, form['target'] ?? '') ?? '';
    final slip = int.tryParse(form['slip'] ?? '') ?? -1;
    final text = form['text'] ?? '';
    final (error, next) = switch (action) {
      'guess' => (game.checkGuess(clientId, target, slip), game.guess(clientId, target, slip)),
      'suggest' => (game.checkSuggestion(clientId, target, slip), game.suggest(clientId, target, slip)),
      'unvote' => (null, game.unvote(clientId)),
      _ => (game.checkMessage(clientId, text), game.say(clientId, text, nonce: _nonceOf(form))),
    };
    if (error == null) _set(_room.withFamily(next));
    response.statusCode = error == null ? HttpStatus.ok : HttpStatus.conflict;
    _json(response, {'error': error?.name});
  }

  /// Lasts a whole evening, so closing the browser doesn't turn a friend into a stranger.
  Cookie _cookie(String value) => Cookie(cookieName, value)
    ..maxAge = const Duration(hours: 12).inSeconds
    ..httpOnly = true
    ..sameSite = SameSite.lax
    ..path = '/';

  /// A chat message's id from the sending phone, used to ignore resends.
  static String? _nonceOf(Map<String, String> form) {
    final nonce = form['cid'] ?? '';
    return RegExp(r'^[0-9A-Za-z_-]{1,40}$').hasMatch(nonce) ? nonce : null;
  }

  /// Once the host lets a new browser back in as a dropped player, it gets that
  /// player's id, so from now on it simply is them. Only while that player is
  /// still away: if their own phone came back first, the seat stays theirs.
  String _takeBackSeat(String clientId, HttpResponse response) {
    final game = _room.family;
    final claim = game?.claimOf(clientId);
    if (game == null || claim == null || claim.status != ClaimStatus.approved) return clientId;
    if (!game.isAway(claim.playerId)) {
      _set(_room.withFamily(game.dropClaim(clientId)));
      return clientId;
    }
    response.cookies.add(_cookie(claim.playerId));
    _set(_room.withFamily(game.dropClaim(clientId)));
    return claim.playerId;
  }

  void _heardFrom(String clientId) {
    final game = _room.family;
    if (game == null || game.player(clientId) == null) return;
    _seen[clientId] = _clock();
    if (game.isAway(clientId)) _set(_room.withFamily(game.withAway({...game.away}..remove(clientId))));
  }

  /// Forgets when friends were last heard from, so no one shows as offline
  /// just because this phone itself was asleep. Everyone gets a fresh
  /// [awayAfter] to call in.
  void resetPresence() {
    _seen.clear();
    _lastTick = null;
  }

  DateTime? _lastTick;

  void _presenceTick() {
    final now = _clock();
    final last = _lastTick;
    // Ticks stop while the app is paused; a long gap means the host's phone
    // slept, not that every friend went quiet.
    if (last != null && now.difference(last) > awayAfter) resetPresence();
    _lastTick = now;
    checkPresence();
  }

  /// Marks friends whose phones have gone quiet as offline, so the game can
  /// work around them. The host's own phone is the server, so it never drops.
  @visibleForTesting
  void checkPresence() {
    final game = _room.family;
    if (game == null) return;
    final now = _clock();
    final away = <String>{};
    for (final p in game.players) {
      if (p.id == Player.hostId) continue;
      final seen = _seen.putIfAbsent(p.id, () => now);
      if (now.difference(seen) > awayAfter) away.add(p.id);
    }
    final next = game.withAway(away);
    if (!identical(next, game)) _set(_room.withFamily(next));
  }

  /// Someone not in the game asks for a dropped player's seat; the host decides.
  Future<void> _claim(HttpRequest request, String? clientId) async {
    final response = request.response;
    final form = await _readForm(request);
    final game = _room.family;
    final playerId = game == null ? null : familyPlayerIdFor(game, form?['player'] ?? '');
    final next = game == null || clientId == null || playerId == null ? null : game.claimSeat(clientId, playerId);
    // Refused, too: someone still playing, a seat the host already turned this browser away from.
    if (next == null || identical(next, game)) {
      response.statusCode = HttpStatus.conflict;
      _json(response, {'error': 'claimRefused'});
      return;
    }
    _set(_room.withFamily(next));
    _json(response, {'error': null});
  }

  void _json(HttpResponse response, Object? body) {
    response.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(jsonEncode(body));
  }

  Future<Map<String, String>?> _readForm(HttpRequest request) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBodyBytes) return null;
    }
    try {
      return Uri.splitQueryString(utf8.decode(bytes));
    } on FormatException {
      return const {};
    }
  }

  String? _clientIdOf(HttpRequest request) {
    for (final cookie in request.cookies) {
      if (cookie.name == cookieName && RegExp(r'^[0-9a-f]{32}$').hasMatch(cookie.value)) return cookie.value;
    }
    return null;
  }

  String _newClientId() => [for (var i = 0; i < 16; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  void _html(HttpResponse response, String html) {
    response.headers
      ..contentType = ContentType.html
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(html);
  }
}
