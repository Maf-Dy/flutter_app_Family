import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The game's sound effects, each a short WAV under `assets/sounds/`.
enum GameSound {
  /// Suspense while a guess is being checked.
  drumroll('drumroll.wav'),

  /// A zaghrouta for a right answer.
  joy('zaghrouta.wav'),

  /// A sad trombone for a wrong one.
  wrong('trombone.wav');

  const GameSound(this.file);

  final String file;

  /// Path inside the app bundle, as `rootBundle` wants it.
  String get asset => 'assets/sounds/$file';
}

/// Plays sounds on the platform. Swapped for a fake in tests, so widget tests never reach a platform channel.
abstract interface class SoundPlayer {
  Future<void> play(GameSound sound);

  /// Cuts [sound] off if it is still playing.
  Future<void> stop(GameSound sound);

  Future<void> dispose();
}

/// Named sound moments, played only while the "Sound effects" setting is on.
/// Never throws: a sound that can't play is simply skipped.
class GameSounds {
  GameSounds(this._player, {required this._enabled});

  /// Plays nothing, for places with no sound.
  GameSounds.silent() : this(const SilentSoundPlayer(), enabled: () => false);

  final SoundPlayer _player;
  final bool Function() _enabled;

  /// A guess is locked in; the answer is coming.
  Future<void> drumroll() => _play(GameSound.drumroll);

  /// The guess was right.
  Future<void> joy() => _stopThenPlay(GameSound.joy);

  /// The guess was wrong.
  Future<void> wrong() => _stopThenPlay(GameSound.wrong);

  Future<void> _stopThenPlay(GameSound sound) async {
    await _guard(() => _player.stop(GameSound.drumroll));
    await _play(sound);
  }

  Future<void> _play(GameSound sound) async {
    if (!_enabled()) return;
    await _guard(() => _player.play(sound));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('GameSounds: $error');
    }
  }
}

/// Real playback with the audioplayers plugin: one player per sound, made on first use.
/// Mixes with music already playing and stays quiet when the phone is on silent.
class AudioSoundPlayer implements SoundPlayer {
  final _players = <GameSound, AudioPlayer>{};

  static final _context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: true,
  ).build();

  Future<AudioPlayer> _playerFor(GameSound sound) async {
    final existing = _players[sound];
    if (existing != null) return existing;
    final player = _players[sound] = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setAudioContext(_context);
    return player;
  }

  @override
  Future<void> play(GameSound sound) async {
    final player = await _playerFor(sound);
    await player.stop();
    // AssetSource paths are relative to `assets/`.
    await player.play(AssetSource('sounds/${sound.file}'));
  }

  @override
  Future<void> stop(GameSound sound) async {
    await _players[sound]?.stop();
  }

  @override
  Future<void> dispose() async {
    final players = [..._players.values];
    _players.clear();
    await Future.wait([for (final p in players) p.dispose()]);
  }
}

/// Plays nothing.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  Future<void> play(GameSound sound) async {}

  @override
  Future<void> stop(GameSound sound) async {}

  @override
  Future<void> dispose() async {}
}
