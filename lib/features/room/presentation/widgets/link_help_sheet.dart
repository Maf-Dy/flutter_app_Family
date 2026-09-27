import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';

/// "Link not opening?": the usual reasons, and the hotspot as the way out.
Future<void> showLinkHelp(BuildContext context, {required String url, required VoidCallback onUseHotspot}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LinkHelp(url: url, onUseHotspot: onUseHotspot),
    );

class _LinkHelp extends StatelessWidget {
  const _LinkHelp({required this.url, required this.onUseHotspot});

  final String url;
  final VoidCallback onUseHotspot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tips = [l10n.linkHelpSameWifi, l10n.linkHelpTypeExactly(url), l10n.linkHelpIsolation];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.linkNotOpening, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: CircleAvatar(radius: 3, backgroundColor: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tip, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onUseHotspot();
              },
              icon: const Icon(Icons.wifi_tethering_rounded),
              label: Text(l10n.useHotspotInstead),
            ),
          ],
        ),
      ),
    );
  }
}
