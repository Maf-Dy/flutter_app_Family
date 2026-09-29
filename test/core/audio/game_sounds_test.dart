import 'dart:typed_data';

import 'package:family_game/core/audio/game_sounds.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _BrokenPlayer implements SoundPlayer {
  @override
  Future<void> play(GameSound sound) => Future.error(StateError('no audio'));

  @override
  Future<void> stop(GameSound sound) => Future.error(StateError('no audio'));

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('plays each moment, and a result cuts the drumroll off', () async {
    final player = FakeSoundPlayer();
    final sounds = GameSounds(player, enabled: () => true);
    await sounds.drumroll();
    await sounds.joy();
    await sounds.wrong();
    expect(player.played, [GameSound.drumroll, GameSound.joy, GameSound.wrong]);
    expect(player.stopped, [GameSound.drumroll, GameSound.drumroll]);
  });

  test('stays quiet while the setting is off, and follows it as it changes', () async {
    final player = FakeSoundPlayer();
    var on = false;
    final sounds = GameSounds(player, enabled: () => on);
    await sounds.drumroll();
    await sounds.joy();
    expect(player.played, isEmpty);
    on = true;
    await sounds.wrong();
    expect(player.played, [GameSound.wrong]);
  });

  test('a sound that fails to play is skipped, not thrown', () async {
    final sounds = GameSounds(_BrokenPlayer(), enabled: () => true);
    await expectLater(sounds.drumroll(), completes);
    await expectLater(sounds.joy(), completes);
    await expectLater(GameSounds.silent().wrong(), completes);
  });

  test('every sound is bundled as a short 22 kHz mono 16-bit WAV', () async {
    for (final sound in GameSound.values) {
      final bytes = (await rootBundle.load(sound.asset)).buffer.asUint8List();
      final header = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: sound.file);
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE', reason: sound.file);
      expect(header.getUint16(22, Endian.little), 1, reason: '${sound.file} is mono');
      expect(header.getUint32(24, Endian.little), 22050, reason: sound.file);
      expect(header.getUint16(34, Endian.little), 16, reason: sound.file);
      expect(bytes.length, lessThan(120 * 1024), reason: sound.file);
    }
  });
}
