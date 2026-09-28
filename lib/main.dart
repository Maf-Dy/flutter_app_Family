import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app.dart';
import 'features/room/data/device_network.dart';
import 'features/room/data/lan_room_host.dart';
import 'features/room/data/udp_room_beacon.dart';
import 'features/settings/data/prefs_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  final settingsStore = PrefsSettingsStore();
  runApp(
    FamilyApp(
      network: DeviceNetwork(),
      createHost: LanRoomHost.new,
      beacon: UdpRoomBeacon(),
      finder: UdpRoomFinder(onListen: DeviceNetwork.holdMulticastLock, onCancel: DeviceNetwork.releaseMulticastLock),
      openRoomLink: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
      openWifiSettings: DeviceNetwork.openWifiSettings,
      settingsStore: settingsStore,
      settings: await settingsStore.load(),
    ),
  );
}

/// The bundled fonts are under the SIL Open Font License, which asks for its text to ship with them.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final (font, file) in const [
    ('Bricolage Grotesque', 'assets/fonts/OFL-bricolagegrotesque.txt'),
    ('Nunito', 'assets/fonts/OFL-nunito.txt'),
    ('Kalam', 'assets/fonts/OFL-kalam.txt'),
    ('Baloo Bhaijaan 2', 'assets/fonts/OFL-baloobhaijaan2.txt'),
    ('Aref Ruqaa', 'assets/fonts/OFL-arefruqaa.txt'),
  ]) {
    yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(file));
  }
}
