import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/audio/game_sounds.dart';

import '../../family/domain/family_game.dart';
import '../domain/room.dart';
import '../domain/room_host.dart';
import 'join_page.dart';
import 'join_strings.dart';
import 'family_view.dart';

/// Reads a sound effect's bytes from the app bundle.
typedef SoundLoader = Future<Uint8List> Function(GameSound sound);

/// Serves the room over plain HTTP on this phone, so friends only need a browser.
///
/// Also serves the sound effects at `/sounds/<file>.wav`, for `browserSoundsJs`.
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
    SoundLoader? loadSound,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now,
       _loadSound = loadSound ?? _bundledSound;

  static const cookieName = 'family_id';
  static const _maxBodyBytes = 8 * 1024;

  /// Room for one drawing sent as a form field: a base64 data URL, URL-encoded.
  static const _maxInkFieldBytes = SlipInk.maxBytes * 2;

  final int preferredPort;
  final Random _random;
  final DateTime Function() _clock;
  final SoundLoader _loadSound;

  /// Loaded once, then served from memory.
  final _sounds = <GameSound, Uint8List>{};

  static Future<Uint8List> _bundledSound(GameSound sound) async =>
      (await rootBundle.load(sound.asset)).buffer.asUint8List();

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
        case (
          'POST',
          '/game/guess' ||
              '/game/suggest' ||
              '/game/unvote' ||
              '/game/say' ||
              '/game/letmego' ||
              '/game/counter' ||
              '/game/passcounter' ||
              '/game/revenge' ||
              '/game/passrevenge' ||
              '/game/rumor',
        ):
          await _familyAction(request, clientId, request.uri.pathSegments.last);
        case ('POST', '/game/claim'):
          await _claim(request, clientId);
        case ('GET', final path) when path.startsWith('/sounds/'):
          await _sound(response, path.substring('/sounds/'.length));
        case ('GET', final String path) when path.startsWith('/ink/'):
          _ink(request, response, path);
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
    final form = await _readForm(
      request,
      maxBytes: _room.handwritten ? _maxBodyBytes + _room.namesPerPlayer * _maxInkFieldBytes : _maxBodyBytes,
    );
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
    // A handwritten room sends each name as the pad's PNG data URL; anything else reads as no drawing.
    final fields = [for (var i = 0; i < _room.namesPerPlayer; i++) form['s$i'] ?? ''];
    final secrets = _room.handwritten ? const <String>[] : fields;
    final inks = _room.handwritten ? fields.map(SlipInk.fromDataUrl).toList() : const <SlipInk?>[];
    final team = int.tryParse(form['team'] ?? '');
    final error = _room.playersPickTeams && team == null
        ? SubmissionError.invalidTeam
        : _room.validate(name: name, secrets: secrets, inks: inks, playerId: clientId, team: team);
    if (error != null || clientId == null) {
      response.statusCode = error == SubmissionError.roomClosed ? HttpStatus.conflict : HttpStatus.badRequest;
      _html(
        response,
        error == SubmissionError.roomClosed
            ? JoinPage.reading(_room, strings, player)
            : JoinPage.form(
                _room,
                strings,
                player: player,
                name: name,
                secrets: secrets,
                inks: inks,
                error: error,
                team: team,
              ),
      );
      return;
    }
    _set(_room.withSubmission(playerId: clientId, name: name, secrets: secrets, inks: inks, team: team));
    response
      ..statusCode = HttpStatus.seeOther
      ..headers.set(HttpHeaders.locationHeader, '/');
  }

  /// A handwritten name in the family game, as `/ink/<slip id>.png`. Pages
  /// redraw often, so the drawing is revalidated by its ETag instead of resent.
  void _ink(HttpRequest request, HttpResponse response, String path) {
    final match = RegExp(r'^/ink/(\d{1,4})\.png$').firstMatch(path);
    final ink = match == null ? null : _room.family?.slip(int.parse(match.group(1)!))?.ink;
    if (ink == null) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    final etag = '"${ink.tag}"';
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..set(HttpHeaders.etagHeader, etag);
    if (request.headers.value(HttpHeaders.ifNoneMatchHeader) == etag) {
      response.statusCode = HttpStatus.notModified;
      return;
    }
    response.headers.contentType = ContentType('image', 'png');
    response.add(ink.png);
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
      'letmego' => (
        game.checkAnswer(clientId, PendingKind.letMeGo),
        game.answerLetMeGo(clientId, use: form['use'] == '1'),
      ),
      'counter' => (game.checkCounter(clientId, target, slip), game.counterCatch(clientId, target, slip)),
      'passcounter' => (game.checkAnswer(clientId, PendingKind.counter), game.passCounter(clientId)),
      'revenge' => (game.checkRevenge(clientId, slip), game.revenge(clientId, slip)),
      'passrevenge' => (game.checkAnswer(clientId, PendingKind.revenge), game.passRevenge(clientId)),
      'rumor' => (game.checkRumor(clientId, target, slip), game.spreadRumor(clientId, target, slip)),
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
  /// work around them.
  @visibleForTesting
  void checkPresence() {
    final game = _room.family;
    if (game == null) return;
    final now = _clock();
    final away = <String>{};
    for (final p in game.players) {
      // The host's phone is the server, so it never drops; the host app says when they step away.
      if (p.id == Player.hostId) {
        if (game.isAway(p.id)) away.add(p.id);
        continue;
      }
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

  Future<void> _sound(HttpResponse response, String file) async {
    final sound = GameSound.values.where((s) => s.file == file).firstOrNull;
    if (sound == null) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    final bytes = _sounds[sound] ??= await _loadSound(sound);
    response.headers
      ..contentType = ContentType('audio', 'wav')
      ..contentLength = bytes.length
      // The files never change while the app is installed.
      ..set(HttpHeaders.cacheControlHeader, 'public, max-age=86400');
    response.add(bytes);
  }

  void _json(HttpResponse response, Object? body) {
    response.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(jsonEncode(body));
  }

  Future<Map<String, String>?> _readForm(HttpRequest request, {int maxBytes = _maxBodyBytes}) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > maxBytes) return null;
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
