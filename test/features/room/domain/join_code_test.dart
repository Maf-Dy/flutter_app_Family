import 'package:family_game/features/room/domain/join_code.dart';
import 'package:family_game/features/room/domain/network_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the host\'s game link opens the room', () {
    expect(
      JoinCode.parse(' http://192.168.1.23:8182 \n'),
      isA<GameLink>().having((c) => c.url.toString(), 'url', 'http://192.168.1.23:8182'),
    );
    expect(JoinCode.parse('http://10.0.0.5:40111/'), isA<GameLink>());
    expect(JoinCode.parse('http://172.20.1.1:8182'), isA<GameLink>());
  });

  test('the host\'s Wi-Fi code reads back what the lobby put in it', () {
    for (final credentials in const [
      HotspotCredentials(ssid: 'AndroidShare_1234', password: 'secret12'),
      HotspotCredentials(ssid: r'Our;Wi:Fi,"home"\', password: r'p;a:s,s"\', security: HotspotSecurity.wpa3),
      HotspotCredentials(ssid: 'Open house', password: '', security: HotspotSecurity.open),
    ]) {
      final code = JoinCode.parse(credentials.qrPayload);
      expect(
        code,
        isA<WifiCode>()
            .having((c) => c.credentials.ssid, 'ssid', credentials.ssid)
            .having((c) => c.credentials.password, 'password', credentials.password)
            .having((c) => c.credentials.security, 'security', credentials.security),
      );
    }
  });

  test('anything else is not a game code', () {
    for (final text in [
      'https://192.168.1.23:8182',
      'http://example.com',
      'http://8.8.8.8:8182',
      'hello',
      'WIFI:T:WPA;P:nossid;;',
      '',
    ]) {
      expect(JoinCode.parse(text), isA<NotAGameCode>(), reason: text);
    }
  });
}
