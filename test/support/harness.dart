import 'package:family_game/core/audio/game_sounds.dart';
import 'package:family_game/core/l10n/l10n.dart';
import 'package:family_game/core/router/app_router.dart';
import 'package:family_game/core/theme/app_theme.dart';
import 'package:family_game/features/room/domain/network_access.dart';
import 'package:family_game/features/room/domain/room_beacon.dart';
import 'package:family_game/features/room/domain/room_host.dart';
import 'package:family_game/features/room/presentation/screens/scan_screen.dart';
import 'package:family_game/features/room/presentation/state/nearby_rooms_cubit.dart';
import 'package:family_game/features/settings/domain/app_settings.dart';
import 'package:family_game/features/settings/presentation/state/settings_cubit.dart';
import 'package:flutter/material.dart';

import 'fakes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FakeSettingsStore implements SettingsStore {
  AppSettings saved = const AppSettings();

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

/// The app's providers, routes, theme and translations around fakes.
///
/// [direction] forces a text direction without changing the language, so
/// English finders still work while the layout is checked right to left.
Widget testApp({
  required NetworkAccess network,
  required RoomHostFactory createHost,
  RoomBeacon? beacon,
  RoomFinder? finder,
  OpenRoomLink? openRoomLink,
  ScanJoinCode? scan,
  OpenWifiSettings? openWifiSettings,
  SettingsStore? settingsStore,
  SoundPlayer? soundPlayer,
  AppSettings settings = const AppSettings(hostName: 'Mafdy'),
  Locale locale = const Locale('en'),
  TextDirection? direction,
  bool dark = false,
  bool reducedMotion = true,
  GlobalKey? boundaryKey,
}) {
  final app = MultiRepositoryProvider(
    providers: [
      RepositoryProvider<NetworkAccess>.value(value: network),
      RepositoryProvider<RoomHostFactory>.value(value: createHost),
      RepositoryProvider<RoomBeacon>.value(value: beacon ?? FakeRoomBeacon()),
      RepositoryProvider<RoomFinder>.value(value: finder ?? FakeRoomFinder()),
      RepositoryProvider<OpenRoomLink>.value(value: openRoomLink ?? (_) async => true),
      RepositoryProvider<ScanJoinCode>.value(value: scan ?? (_) async => null),
      RepositoryProvider<OpenWifiSettings>.value(value: openWifiSettings ?? () async {}),
    ],
    child: BlocProvider(
      create: (_) => SettingsCubit(settingsStore ?? FakeSettingsStore(), settings),
      child: RepositoryProvider<GameSounds>(
        create: (context) => GameSounds(
          soundPlayer ?? FakeSoundPlayer(),
          enabled: () => context.read<SettingsCubit>().state.soundEffects,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Reduced motion also stops the looping animations, so pumpAndSettle can settle.
          builder: (context, child) {
            Widget result = MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
              child: child!,
            );
            if (direction != null) result = Directionality(textDirection: direction, child: result);
            return result;
          },
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    ),
  );
  return boundaryKey == null ? app : RepaintBoundary(key: boundaryKey, child: app);
}
