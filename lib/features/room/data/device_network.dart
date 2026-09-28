import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/network_access.dart';

/// Real networking: the Wi-Fi address from Android itself, an interface scan for
/// hotspots, connectivity events, and the Android local-only hotspot through
/// `LocalHotspot.kt`.
class DeviceNetwork implements NetworkAccess {
  DeviceNetwork({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stopped') {
        _forgetHotspot();
        _hotspotStopped.add(null);
      }
    });
  }

  static const _channel = MethodChannel('family_game/hotspot');

  final Connectivity _connectivity;
  final _hotspotStopped = StreamController<void>.broadcast();
  int? _sdkInt;

  /// This phone's address on the app's own hotspot, while it runs.
  String? _appHotspotAddress;

  /// Addresses the app's hotspot had, and when it stopped. Just after it stops,
  /// its interface can linger for a moment, and serving the room there showed a
  /// dead link.
  final _formerHotspotAddresses = <String, DateTime>{};
  static const _lingerFor = Duration(seconds: 15);

  @override
  Stream<void> get changes => _connectivity.onConnectivityChanged.map((_) {});

  @override
  Stream<void> get hotspotStopped => _hotspotStopped.stream;

  @override
  Future<String?> findLanAddress() async {
    // Android knows which address belongs to the Wi-Fi network; guessing from
    // interface names picked the wrong one on some phones.
    final wifi = await _androidWifiAddress();
    if (wifi != null) return wifi;
    // A hotspot turned on in Settings, or iOS (en0 is Wi-Fi, bridge100 its hotspot).
    return pickLanAddress(await _interfaceAddresses(), exclude: _ownHotspot);
  }

  Set<String> get _ownHotspot {
    final cutoff = DateTime.now().subtract(_lingerFor);
    _formerHotspotAddresses.removeWhere((_, stoppedAt) => stoppedAt.isBefore(cutoff));
    return {?_appHotspotAddress, ..._formerHotspotAddresses.keys};
  }

  @override
  Future<bool> isOnWifi() async {
    if (Platform.isAndroid) return await _androidWifiAddress() != null;
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);
  }

  @override
  Future<bool> canCreateHotspot() async => (await _androidSdk() ?? 0) >= 26;

  @override
  Future<HotspotResult> startHotspot() async {
    final sdk = await _androidSdk();
    if (sdk == null || sdk < 26) return const HotspotFailed(HotspotFailure.unsupported);

    final permission = sdk >= 33 ? Permission.nearbyWifiDevices : Permission.locationWhenInUse;
    final status = await permission.request();
    if (status.isPermanentlyDenied || status.isRestricted) return const HotspotFailed(HotspotFailure.permissionBlocked);
    if (!status.isGranted && !status.isLimited) return const HotspotFailed(HotspotFailure.permissionDenied);

    final before = {for (final c in await _interfaceAddresses()) c.address};
    final Map<String, String?>? result;
    try {
      result = await _channel.invokeMapMethod<String, String?>('start');
    } on PlatformException catch (error) {
      return HotspotFailed(switch (error.code) {
        'unsupported' => HotspotFailure.unsupported,
        'permission' => HotspotFailure.permissionDenied,
        'incompatible' => HotspotFailure.incompatibleMode,
        'disallowed' => HotspotFailure.notAllowed,
        _ => HotspotFailure.failed,
      });
    }
    final ssid = result?['ssid'];
    final password = result?['password'] ?? '';
    if (ssid == null) {
      await stopHotspot();
      return const HotspotFailed(HotspotFailure.failed);
    }

    // The hotspot's own address is the new one that appears after it starts.
    final address = await _waitForNewAddress(before);
    if (address == null) {
      await stopHotspot();
      return const HotspotFailed(HotspotFailure.noAddress);
    }
    _appHotspotAddress = address;
    _formerHotspotAddresses.remove(address);
    final security = switch (result?['security']) {
      'open' => HotspotSecurity.open,
      'wpa3' => HotspotSecurity.wpa3,
      _ => HotspotSecurity.wpa,
    };
    return HotspotStarted(HotspotCredentials(ssid: ssid, password: password, security: security), address);
  }

  Future<String?> _waitForNewAddress(Set<String> before) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final fresh = [
        for (final c in await _interfaceAddresses())
          if (!before.contains(c.address)) c,
      ];
      final address = pickLanAddress(fresh);
      if (address != null) return address;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  void _forgetHotspot() {
    final address = _appHotspotAddress;
    if (address != null) _formerHotspotAddresses[address] = DateTime.now();
    _appHotspotAddress = null;
  }

  @override
  Future<void> stopHotspot() async {
    _forgetHotspot();
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      debugPrint('DeviceNetwork: could not stop hotspot ($error)');
    }
  }

  @override
  Future<bool> canReach(String address, int port) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(Uri.parse('http://$address:$port/status'));
      final response = await request.close().timeout(const Duration(seconds: 3));
      await response.drain<void>();
      return response.statusCode == HttpStatus.ok;
    } on Object catch (error) {
      debugPrint('DeviceNetwork: self-check of $address:$port failed ($error)');
      return false;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> openPermissionSettings() => openAppSettings();

  /// Keeps Android's Wi-Fi from dropping broadcasts while the app listens for rooms.
  static Future<void> holdMulticastLock() => _call('lockMulticast');

  static Future<void> releaseMulticastLock() => _call('unlockMulticast');

  /// So a friend can join the host's hotspot after scanning its Wi-Fi code.
  static Future<void> openWifiSettings() => _call('openWifiSettings');

  static Future<void> _call(String method) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException catch (error) {
      debugPrint('DeviceNetwork: $method failed ($error)');
    }
  }

  Future<List<({String interface, String address})>> _interfaceAddresses() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return [
      for (final interface in interfaces)
        for (final address in interface.addresses) (interface: interface.name, address: address.address),
    ];
  }

  /// The Wi-Fi address Android reports, unless it is the app's own hotspot:
  /// some phones list that as a Wi-Fi network too, which made the app think it
  /// had joined Wi-Fi and turn the hotspot off.
  Future<String?> _androidWifiAddress() async {
    if (!Platform.isAndroid) return null;
    try {
      final address = await _channel.invokeMethod<String>('wifiAddress');
      return _ownHotspot.contains(address) ? null : address;
    } on PlatformException catch (error) {
      debugPrint('DeviceNetwork: no Wi-Fi address from Android ($error)');
      return null;
    }
  }

  Future<int?> _androidSdk() async {
    if (!Platform.isAndroid) return null;
    try {
      return _sdkInt ??= await _channel.invokeMethod<int>('sdkInt');
    } on PlatformException {
      return null;
    }
  }
}

/// Picks the address friends should connect to from this phone's IPv4 interfaces,
/// skipping [exclude].
///
/// Only private LAN ranges count (mobile data is never reachable by friends).
/// Hotspot interfaces win over Wi-Fi: when the phone runs a hotspot, friends are
/// on it. Interface names differ by vendor, hence the prefix list.
@visibleForTesting
String? pickLanAddress(List<({String interface, String address})> candidates, {Set<String> exclude = const {}}) {
  const preference = ['ap', 'swlan', 'softap', 'wlan', 'bridge', 'en', 'eth'];
  int rank(String name) {
    final i = preference.indexWhere(name.toLowerCase().startsWith);
    return i < 0 ? preference.length : i;
  }

  final usable = [
    for (final c in candidates)
      if (_isPrivate(c.address) && !exclude.contains(c.address) && rank(c.interface) < preference.length) c,
  ]..sort((a, b) => rank(a.interface).compareTo(rank(b.interface)));
  return usable.isEmpty ? null : usable.first.address;
}

bool _isPrivate(String address) {
  final parts = address.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return false;
  final [a!, b!, _, _] = parts;
  return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
}
