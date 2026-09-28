import 'package:family_game/features/room/data/family_page.dart';
import 'package:family_game/features/room/data/join_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String esc(String value) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  test('the host\'s name can\'t break out of the page\'s script', () {
    final body = familyBody(const EnglishJoinStrings(), esc, hostName: '<!--</script><img src=x>');
    expect(body, isNot(contains('<!--')));
    expect(body, isNot(contains('<img')));
    expect(body, contains(r'\u003c!--\u003c/script>\u003cimg src=x>'));
  });

  test('a seat ask has its own error line, and a finished game says goodbye calmly', () {
    for (final strings in const [EnglishJoinStrings(), ArabicJoinStrings()]) {
      final body = familyBody(strings, esc, hostName: 'Mafdy');
      expect(body, contains('id="claimErr"'));
      expect(strings.family['gameOverBye'], isNotEmpty);
    }
  });
}
