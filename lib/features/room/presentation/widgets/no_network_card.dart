import 'package:flutter/material.dart';

import '../../domain/network_access.dart';
import '../state/room_cubit.dart';

/// Shown when the phone is on no local network: offers the app's own hotspot.
class NoNetworkCard extends StatelessWidget {
  const NoNetworkCard({
    super.key,
    required this.connection,
    required this.onCreateHotspot,
    required this.onCheckAgain,
    required this.onOpenSettings,
  });

  final ConnectionMissing connection;
  final VoidCallback onCreateHotspot;
  final VoidCallback onCheckAgain;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = connection.failure;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text('No Wi-Fi around', style: theme.textTheme.titleLarge),
            Text(
              connection.canCreateHotspot
                  ? 'The app can make a private hotspot. Friends join it by scanning a code. '
                        'They lose mobile data while connected, which the game doesn\'t need.'
                  : 'Turn on your phone\'s hotspot in Settings, then come back here. '
                        'Friends join the hotspot and scan the code.',
              style: muted,
            ),
            if (failure != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _failureText(failure),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (connection.canCreateHotspot)
              FilledButton.icon(
                onPressed: connection.starting ? null : onCreateHotspot,
                icon: connection.starting
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering_rounded),
                label: Text(connection.starting ? 'Starting hotspot…' : 'Create hotspot'),
              ),
            if (failure == HotspotFailure.permissionBlocked)
              OutlinedButton(onPressed: onOpenSettings, child: const Text('Open settings')),
            TextButton(onPressed: onCheckAgain, child: const Text('Check again')),
          ],
        ),
      ),
    );
  }

  static String _failureText(HotspotFailure failure) => switch (failure) {
    HotspotFailure.permissionDenied =>
      'Android needs your permission to create the hotspot. On some phones it is called Location; the app never reads where you are.',
    HotspotFailure.permissionBlocked =>
      'The permission is turned off for Family Game. Allow it in Settings, then try again.',
    HotspotFailure.incompatibleMode =>
      'Your phone\'s own hotspot is already on. Friends can join that instead: tap Check again.',
    HotspotFailure.notAllowed =>
      'This phone doesn\'t let apps create a hotspot. Turn on your hotspot in Settings instead.',
    HotspotFailure.unsupported =>
      'This phone can\'t create a hotspot from an app. Turn on your hotspot in Settings instead.',
    HotspotFailure.noAddress => 'The hotspot started, but the room couldn\'t find it. Tap Check again.',
    HotspotFailure.failed =>
      'Android couldn\'t start the hotspot. Make sure Wi-Fi and Location are on, then try again.',
  };
}
