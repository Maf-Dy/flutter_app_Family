/// Wi-Fi name, password and security of the hotspot the app created.
final class HotspotCredentials {
  const HotspotCredentials({required this.ssid, required this.password, this.security = HotspotSecurity.wpa});

  final String ssid;
  final String password;
  final HotspotSecurity security;

  /// The standard Wi-Fi QR payload phone cameras understand.
  String get qrPayload => switch (security) {
    HotspotSecurity.open => 'WIFI:T:nopass;S:${_escape(ssid)};;',
    HotspotSecurity.wpa => 'WIFI:T:WPA;S:${_escape(ssid)};P:${_escape(password)};;',
    HotspotSecurity.wpa3 => 'WIFI:T:SAE;S:${_escape(ssid)};P:${_escape(password)};;',
  };

  static String _escape(String value) => value.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');
}

/// How the app's hotspot is secured; decides the Wi-Fi QR code's type.
enum HotspotSecurity {
  open,

  /// WPA2, or WPA2/WPA3 transition mode that WPA2 phones can still join.
  wpa,

  /// WPA3 only. Needs "SAE" in the QR code.
  wpa3,
}

enum HotspotFailure {
  /// Not Android 8+, for example an iPhone.
  unsupported,

  /// The user said no; asking again is allowed.
  permissionDenied,

  /// The user said "don't ask again"; only Settings can fix it.
  permissionBlocked,

  /// Another hotspot or tethering mode is already on, or this phone cannot run
  /// a hotspot while it is connected to Wi-Fi.
  incompatibleMode,

  /// The device or its owner blocks hotspots.
  notAllowed,

  /// Android gave no reason. On Android 8 to 12 this usually means Location is off.
  failed,

  /// The hotspot started but no address showed up to serve the room on.
  noAddress,
}

sealed class HotspotResult {
  const HotspotResult();
}

final class HotspotStarted extends HotspotResult {
  const HotspotStarted(this.credentials, this.address);

  final HotspotCredentials credentials;

  /// This phone's address on the new hotspot; friends who join it open the room here.
  final String address;
}

final class HotspotFailed extends HotspotResult {
  const HotspotFailed(this.failure);

  final HotspotFailure failure;
}

/// What the room needs from the phone's networking.
abstract interface class NetworkAccess {
  /// The address friends reach: this phone's Wi-Fi address, or its address on a
  /// hotspot the user turned on in Settings. Never the app's own hotspot, which
  /// [startHotspot] reports separately. Null when there is no local network.
  Future<String?> findLanAddress();

  /// Whether the phone is connected to a Wi-Fi network (as a client, not a hotspot).
  Future<bool> isOnWifi();

  /// Fires when connectivity may have changed and [findLanAddress] is worth re-checking.
  Stream<void> get changes;

  /// Whether [startHotspot] can work on this device at all.
  Future<bool> canCreateHotspot();

  Future<HotspotResult> startHotspot();

  Future<void> stopHotspot();

  /// Fires when the system turned the app's hotspot off.
  Stream<void> get hotspotStopped;

  /// Whether this phone can open its own room at [address]:[port]. A failure means
  /// the address is wrong; success does not prove other phones can reach it.
  Future<bool> canReach(String address, int port);

  /// Opens this app's system settings, for a permission the user blocked.
  Future<void> openPermissionSettings();
}
