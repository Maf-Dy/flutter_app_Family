import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/room.dart';
import '../domain/room_host.dart';
import 'join_page.dart';

/// Serves the room over plain HTTP on this phone, so friends only need a browser.
///
/// Listens on every IPv4 interface, so the same server keeps working when the
/// phone moves between Wi-Fi, its own hotspot, or the hotspot the app creates.
class LanRoomHost implements RoomHost {
  LanRoomHost({this.preferredPort = 8182, Random? random}) : _random = random ?? Random.secure();

  static const cookieName = 'family_id';
  static const _maxBodyBytes = 8 * 1024;

  final int preferredPort;
  final Random _random;
  final _changes = StreamController<Room>.broadcast();
  HttpServer? _server;
  late Room _room;

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
    _room = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  @override
  Future<void> close() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
    // Not awaited: a broadcast controller's close completes only once every
    // listener has seen "done", and a listener mid-cancel would stall shutdown.
    unawaited(_changes.close());
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      final clientId = _clientIdOf(request);
      if (clientId == null) {
        response.cookies.add(
          Cookie(cookieName, _newClientId())
            ..httpOnly = true
            ..sameSite = SameSite.lax
            ..path = '/',
        );
      }
      final player = clientId == null ? null : _room.playerById(clientId);
      switch ((request.method, request.uri.path)) {
        case ('GET', '/'):
          _html(response, _pageFor(player, editing: request.uri.queryParameters.containsKey('edit')));
        case ('POST', '/'):
          await _submit(request, clientId, player);
        case ('GET', '/status'):
          response.headers
            ..contentType = ContentType.json
            ..set(HttpHeaders.cacheControlHeader, 'no-store');
          response.write(jsonEncode({'count': _room.slipCount, 'version': JoinPage.versionFor(_room, player)}));
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

  String _pageFor(Player? player, {required bool editing}) {
    if (!_room.isCollecting) return JoinPage.reading(_room, player);
    if (player != null && player.hasSubmitted && !editing) return JoinPage.done(_room, player);
    if (player == null && _room.players.length >= Room.maxPlayers) return JoinPage.full(_room);
    return JoinPage.form(_room, player: player);
  }

  Future<void> _submit(HttpRequest request, String? clientId, Player? player) async {
    final response = request.response;
    final form = await _readForm(request);
    if (form == null) {
      response.statusCode = HttpStatus.requestEntityTooLarge;
      return;
    }
    final name = form['name'] ?? '';
    final secrets = [for (var i = 0; i < _room.namesPerPlayer; i++) form['s$i'] ?? ''];
    final error = _room.validate(name: name, secrets: secrets);
    // Without a cookie there is no stable identity yet; the cookie set on this
    // response makes the next attempt stick.
    if (error != null || clientId == null) {
      response.statusCode = error == SubmissionError.roomClosed ? HttpStatus.conflict : HttpStatus.badRequest;
      _html(
        response,
        error == SubmissionError.roomClosed
            ? JoinPage.reading(_room, player)
            : JoinPage.form(_room, player: player, name: name, secrets: secrets, error: error),
      );
      return;
    }
    _set(_room.withSubmission(playerId: clientId, name: name, secrets: secrets));
    response
      ..statusCode = HttpStatus.seeOther
      ..headers.set(HttpHeaders.locationHeader, '/');
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
