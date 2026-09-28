import 'network_access.dart';

/// What the phone's camera read from a host's screen.
sealed class JoinCode {
  const JoinCode();

  /// Makes sense of a scanned QR code. The host shows two kinds: the game
  /// link, and, on the app's hotspot, the Wi-Fi code to scan first.
  static JoinCode parse(String raw) {
    final text = raw.trim();
    if (text.toUpperCase().startsWith('WIFI:')) return _wifi(text) ?? const NotAGameCode();
    final url = Uri.tryParse(text);
    // Rooms are served over plain HTTP on the local network, by IP address.
    if (url != null && url.scheme == 'http' && _isLocalAddress(url.host)) return GameLink(url);
    return const NotAGameCode();
  }

  static WifiCode? _wifi(String text) {
    final fields = <String, String>{};
    // Fields are "K:value;" and a value escapes \ ; , : " with a backslash.
    final body = text.substring(5);
    var key = StringBuffer();
    var value = StringBuffer();
    var inValue = false;
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (inValue) {
        if (c == r'\' && i + 1 < body.length) {
          value.write(body[++i]);
        } else if (c == ';') {
          fields[key.toString().toUpperCase()] = value.toString();
          key = StringBuffer();
          value = StringBuffer();
          inValue = false;
        } else {
          value.write(c);
        }
      } else if (c == ':') {
        inValue = true;
      } else if (c != ';') {
        key.write(c);
      }
    }
    final ssid = fields['S'];
    if (ssid == null || ssid.isEmpty) return null;
    final security = switch (fields['T']?.toUpperCase()) {
      'NOPASS' || '' || null => HotspotSecurity.open,
      'SAE' => HotspotSecurity.wpa3,
      _ => HotspotSecurity.wpa,
    };
    return WifiCode(HotspotCredentials(ssid: ssid, password: fields['P'] ?? '', security: security));
  }

  static bool _isLocalAddress(String host) {
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) return false;
    final [a!, b!, _, _] = parts;
    return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
  }
}

/// The game link: open it and you're in.
final class GameLink extends JoinCode {
  const GameLink(this.url);

  final Uri url;
}

/// The host's hotspot. Join this Wi-Fi first, then scan the game link.
final class WifiCode extends JoinCode {
  const WifiCode(this.credentials);

  final HotspotCredentials credentials;
}

/// Some other QR code.
final class NotAGameCode extends JoinCode {
  const NotAGameCode();
}
