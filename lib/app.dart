import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/room/domain/network_access.dart';
import 'features/room/domain/room_host.dart';

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key, required this.network, required this.createHost});

  final NetworkAccess network;
  final RoomHostFactory createHost;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NetworkAccess>.value(value: network),
        RepositoryProvider<RoomHostFactory>.value(value: createHost),
      ],
      child: MaterialApp(
        title: 'Family Game',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
