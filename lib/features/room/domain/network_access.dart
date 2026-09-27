/// Wi-Fi name and password of the hotspot the app created.
final class HotspotCredentials {
  const HotspotCredentials({required this.ssid, required this.password});

  final String ssid;
  final String password;

  /// The standard Wi-Fi QR payload phone cameras understand.
  String get qrPayload => 'WIFI:T:WPA;S:${_escape(ssid)};P:${_escape(password)};;';

  static String _escape(String value) => value.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');
}

enum HotspotFailure {
  /// Not Android 8+, for example an iPhone.
  unsupported,

  /// The user said no; asking again is allowed.
  permissionDenied,

  /// The user said "don't ask again"; only Settings can fix it.
  permissionBlocked,

  /// Another hotspot or tethering mode is already on.
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
  const HotspotStarted(this.credentials);

  final HotspotCredentials credentials;
}

final class HotspotFailed extends HotspotResult {
  const HotspotFailed(this.failure);

  final HotspotFailure failure;
}

/// What the room needs from the phone's networking.
abstract interface class NetworkAccess {
  /// The local address friends can reach, on Wi-Fi or on a hotspot this phone
  /// runs. Null when the phone is on no local network at all.
  Future<String?> findLanAddress();

  /// Fires when connectivity may have changed and [findLanAddress] is worth re-checking.
  Stream<void> get changes;

  /// Whether [startHotspot] can work on this device at all.
  Future<bool> canCreateHotspot();

  Future<HotspotResult> startHotspot();

  Future<void> stopHotspot();

  /// Fires when the system turned the app's hotspot off.
  Stream<void> get hotspotStopped;

  /// Opens this app's system settings, for a permission the user blocked.
  Future<void> openPermissionSettings();
}
