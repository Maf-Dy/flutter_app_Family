import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/room/data/device_network.dart';
import 'features/room/data/lan_room_host.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(FamilyApp(network: DeviceNetwork(), createHost: LanRoomHost.new));
}

/// The bundled fonts are under the SIL Open Font License, which asks for its text to ship with them.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final (font, file) in const [
    ('Bricolage Grotesque', 'assets/fonts/OFL-bricolagegrotesque.txt'),
    ('Nunito', 'assets/fonts/OFL-nunito.txt'),
    ('Kalam', 'assets/fonts/OFL-kalam.txt'),
  ]) {
    yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(file));
  }
}
