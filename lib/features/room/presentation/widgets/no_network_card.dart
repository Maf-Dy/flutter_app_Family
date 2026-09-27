import 'package:flutter/material.dart';

import '../../domain/network_access.dart';
import '../state/room_cubit.dart';
import '../../../../core/l10n/l10n.dart';

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
            Text(context.l10n.noWifiAround, style: theme.textTheme.titleLarge),
            Text(
              connection.canCreateHotspot ? context.l10n.noWifiAroundCanCreate : context.l10n.noWifiAroundCannotCreate,
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
                  hotspotFailureText(context.l10n, failure),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (connection.canCreateHotspot)
              FilledButton.icon(
                onPressed: onCreateHotspot,
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: Text(context.l10n.createHotspot),
              ),
            if (failure == HotspotFailure.permissionBlocked)
              OutlinedButton(onPressed: onOpenSettings, child: Text(context.l10n.openSettings)),
            TextButton(onPressed: onCheckAgain, child: Text(context.l10n.checkAgain)),
          ],
        ),
      ),
    );
  }
}

/// Why the app's hotspot did not start, in the host's words.
String hotspotFailureText(AppLocalizations l10n, HotspotFailure failure) => switch (failure) {
  HotspotFailure.permissionDenied => l10n.hotspotPermissionDenied,
  HotspotFailure.permissionBlocked => l10n.hotspotPermissionBlocked,
  HotspotFailure.incompatibleMode => l10n.hotspotIncompatible,
  HotspotFailure.notAllowed => l10n.hotspotNotAllowed,
  HotspotFailure.unsupported => l10n.hotspotUnsupported,
  HotspotFailure.noAddress => l10n.hotspotNoAddress,
  HotspotFailure.failed => l10n.hotspotFailed,
};
