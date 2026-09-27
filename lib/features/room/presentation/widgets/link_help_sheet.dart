import 'package:flutter/material.dart';

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
    final tips = [
      'Friends must be on the same Wi-Fi as this phone, with mobile data not taking over.',
      'Type the link exactly, including the number after the colon: $url',
      'Office, hotel, café and guest Wi-Fi often stop phones from seeing each other. '
          'The link then never opens, whatever you try. Use this phone\'s hotspot instead.',
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Link not opening?', style: theme.textTheme.headlineSmall),
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
              label: const Text('Use a hotspot instead'),
            ),
          ],
        ),
      ),
    );
  }
}
