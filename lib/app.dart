import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/audio/game_sounds.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/room/domain/network_access.dart';
import 'features/room/domain/room_beacon.dart';
import 'features/room/domain/room_host.dart';
import 'features/room/presentation/screens/scan_screen.dart';
import 'features/room/presentation/state/nearby_rooms_cubit.dart';
import 'features/settings/domain/app_settings.dart';
import 'features/settings/presentation/state/settings_cubit.dart';

class FamilyApp extends StatelessWidget {
  const FamilyApp({
    super.key,
    required this.network,
    required this.createHost,
    required this.beacon,
    required this.finder,
    required this.openRoomLink,
    required this.openWifiSettings,
    required this.settingsStore,
    required this.settings,
    required this.soundPlayer,
  });

  final NetworkAccess network;
  final RoomHostFactory createHost;
  final RoomBeacon beacon;
  final RoomFinder finder;
  final OpenRoomLink openRoomLink;
  final OpenWifiSettings openWifiSettings;
  final SettingsStore settingsStore;

  /// Loaded before the first frame, so the right language shows from the start.
  final AppSettings settings;

  /// Plays [GameSounds], which stay quiet while the "Sound effects" setting is off.
  final SoundPlayer soundPlayer;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NetworkAccess>.value(value: network),
        RepositoryProvider<RoomHostFactory>.value(value: createHost),
        RepositoryProvider<RoomBeacon>.value(value: beacon),
        RepositoryProvider<RoomFinder>.value(value: finder),
        RepositoryProvider<OpenRoomLink>.value(value: openRoomLink),
        RepositoryProvider<OpenWifiSettings>.value(value: openWifiSettings),
        RepositoryProvider<ScanJoinCode>.value(value: scanWithCamera),
      ],
      child: BlocProvider(
        create: (_) => SettingsCubit(settingsStore, settings),
        child: RepositoryProvider<GameSounds>(
          create: (context) => GameSounds(soundPlayer, enabled: () => context.read<SettingsCubit>().state.soundEffects),
          child: BlocBuilder<SettingsCubit, AppSettings>(
            buildWhen: (previous, current) => previous.language != current.language,
            builder: (context, _) => MaterialApp(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              locale: context.read<SettingsCubit>().locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: AppRoutes.home,
              onGenerateRoute: AppRoutes.onGenerateRoute,
            ),
          ),
        ),
      ),
    );
  }
}
