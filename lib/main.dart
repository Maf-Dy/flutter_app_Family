import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/room/data/device_network.dart';
import 'features/room/data/lan_room_host.dart';
import 'features/settings/data/prefs_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  final settingsStore = PrefsSettingsStore();
  runApp(
    FamilyApp(
      network: DeviceNetwork(),
      createHost: LanRoomHost.new,
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
