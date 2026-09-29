import 'package:family_game/core/audio/game_sounds.dart';
import 'package:family_game/features/room/data/browser_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines window.sfx with the three sounds and a remembered mute', () {
    expect(browserSoundsJs, contains('window.sfx'));
    for (final call in ['drumroll:', 'joy:', 'wrong:', 'setMuted:', 'get muted()']) {
      expect(browserSoundsJs, contains(call));
    }
    expect(browserSoundsJs, contains('localStorage'));
    expect(browserSoundsJs, contains('decodeAudioData'));
  });

  test('asks for the files the host serves', () {
    for (final sound in GameSound.values) {
      expect(browserSoundsJs, contains("'/sounds/${sound.file}'"));
    }
  });

  test('can sit inside a script tag', () {
    expect(browserSoundsJs.toLowerCase(), isNot(contains('</script')));
    expect(browserSoundsJs, isNot(contains(r'$')));
  });
}
