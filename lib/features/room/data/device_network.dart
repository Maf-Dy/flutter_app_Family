import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/network_access.dart';

/// Real networking: interface scan for the address, connectivity events, and the
/// Android local-only hotspot through `LocalHotspot.kt`.
class DeviceNetwork implements NetworkAccess {
  DeviceNetwork({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stopped') _hotspotStopped.add(null);
    });
  }

  static const _channel = MethodChannel('family_game/hotspot');

  final Connectivity _connectivity;
  final _hotspotStopped = StreamController<void>.broadcast();
  int? _sdkInt;

  @override
  Stream<void> get changes => _connectivity.onConnectivityChanged.map((_) {});

  @override
  Stream<void> get hotspotStopped => _hotspotStopped.stream;

  @override
  Future<String?> findLanAddress() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return pickLanAddress([
      for (final interface in interfaces)
        for (final address in interface.addresses) (interface: interface.name, address: address.address),
    ]);
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

    try {
      final result = await _channel.invokeMapMethod<String, String?>('start');
      final ssid = result?['ssid'];
      final password = result?['password'];
      if (ssid == null || password == null) return const HotspotFailed(HotspotFailure.failed);
      return HotspotStarted(HotspotCredentials(ssid: ssid, password: password));
    } on PlatformException catch (error) {
      return HotspotFailed(switch (error.code) {
        'unsupported' => HotspotFailure.unsupported,
        'permission' => HotspotFailure.permissionDenied,
        'incompatible' => HotspotFailure.incompatibleMode,
        'disallowed' => HotspotFailure.notAllowed,
        _ => HotspotFailure.failed,
      });
    }
  }

  @override
  Future<void> stopHotspot() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      debugPrint('DeviceNetwork: could not stop hotspot ($error)');
    }
  }

  @override
  Future<void> openPermissionSettings() => openAppSettings();

  Future<int?> _androidSdk() async {
    if (!Platform.isAndroid) return null;
    try {
      return _sdkInt ??= await _channel.invokeMethod<int>('sdkInt');
    } on PlatformException {
      return null;
    }
  }
}

/// Picks the address friends should connect to from this phone's IPv4 interfaces.
///
/// Only private LAN ranges count (mobile data is never reachable by friends).
/// Hotspot interfaces win over Wi-Fi: when the phone runs a hotspot, friends are
/// on it. Interface names differ by vendor, hence the prefix list.
@visibleForTesting
String? pickLanAddress(List<({String interface, String address})> candidates) {
  const preference = ['ap', 'swlan', 'softap', 'wlan', 'bridge', 'en', 'eth'];
  int rank(String name) {
    final i = preference.indexWhere(name.toLowerCase().startsWith);
    return i < 0 ? preference.length : i;
  }

  final usable = [
    for (final c in candidates)
      if (_isPrivate(c.address) && rank(c.interface) < preference.length) c,
  ]..sort((a, b) => rank(a.interface).compareTo(rank(b.interface)));
  return usable.isEmpty ? null : usable.first.address;
}

bool _isPrivate(String address) {
  final parts = address.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return false;
  final [a!, b!, _, _] = parts;
  return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
}
