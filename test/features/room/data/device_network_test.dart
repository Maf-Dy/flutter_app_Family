import 'package:family_game/features/room/data/device_network.dart';
import 'package:family_game/features/room/domain/network_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickLanAddress', () {
    test('uses the Wi-Fi address', () {
      expect(pickLanAddress([(interface: 'wlan0', address: '192.168.1.23')]), '192.168.1.23');
    });

    test('prefers a hotspot interface over Wi-Fi', () {
      expect(
        pickLanAddress([(interface: 'wlan0', address: '192.168.1.23'), (interface: 'swlan0', address: '192.168.43.1')]),
        '192.168.43.1',
      );
    });

    test('ignores mobile data, loopback and public addresses', () {
      expect(
        pickLanAddress([
          (interface: 'rmnet_data0', address: '10.12.0.4'),
          (interface: 'lo', address: '127.0.0.1'),
          (interface: 'wlan0', address: '100.70.1.2'),
        ]),
        isNull,
      );
    });

    test('accepts every private range, including iPhone hotspot bridges', () {
      expect(pickLanAddress([(interface: 'bridge100', address: '172.20.10.1')]), '172.20.10.1');
      expect(pickLanAddress([(interface: 'en0', address: '10.0.0.8')]), '10.0.0.8');
      expect(pickLanAddress([(interface: 'eth0', address: '172.32.0.1')]), isNull);
    });
  });

  test('Wi-Fi QR payload escapes special characters', () {
    const credentials = HotspotCredentials(ssid: 'Family;Room', password: r'p:a"s\s');
    expect(credentials.qrPayload, r'WIFI:T:WPA;S:Family\;Room;P:p\:a\"s\\s;;');
  });
}
