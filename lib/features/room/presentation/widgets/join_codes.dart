import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/motion/motion.dart';
import '../../domain/network_access.dart';
import '../../../../core/l10n/l10n.dart';

/// QR code on a white tile: scanners need dark-on-light, in both themes.
class QrTile extends StatelessWidget {
  const QrTile({super.key, required this.data, required this.label, this.size = 112});

  final String data;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1D1A33);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: QrImageView(
        data: data,
        padding: EdgeInsets.zero,
        semanticsLabel: label,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ink),
      ),
    );
  }
}

/// The join link: QR, room code and link, with Share and Copy.
class JoinCard extends StatelessWidget {
  const JoinCard({super.key, required this.url, required this.code, this.caption});

  final String url;
  final String code;

  /// Defaults to "Scan to join".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            QrTile(data: url, label: context.l10n.qrForLink(url)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (caption ?? context.l10n.scanToJoin).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    code,
                    semanticsLabel: context.l10n.roomCodeLabel(code.split('').join(' ')),
                    style: theme.textTheme.headlineLarge?.copyWith(letterSpacing: 3),
                  ),
                  SelectableText(
                    url.replaceFirst('http://', ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SmallButton(
                        icon: Icons.share_rounded,
                        label: context.l10n.share,
                        onPressed: () => _share(context),
                      ),
                      _SmallButton(icon: Icons.copy_rounded, label: context.l10n.copy, onPressed: () => _copy(context)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: context.l10n.shareText(url),
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.linkCopied), duration: const Duration(seconds: 2)));
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: Theme.of(context).textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Two steps on the app's own hotspot: join the Wi-Fi, then open the game.
class HotspotCodes extends StatefulWidget {
  const HotspotCodes({super.key, required this.credentials, required this.url, required this.code});

  final HotspotCredentials credentials;
  final String url;
  final String code;

  @override
  State<HotspotCodes> createState() => _HotspotCodesState();
}

class _HotspotCodesState extends State<HotspotCodes> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (step, label) in [(1, context.l10n.stepJoinWifi), (2, context.l10n.stepOpenGame)]) ...[
              if (step == 2) const SizedBox(width: 8),
              Expanded(
                child: _StepTab(
                  step: step,
                  label: label,
                  selected: _step == step,
                  onTap: () => setState(() => _step = step),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.standard),
          transitionBuilder: Motion.fadeSwitch,
          child: _step == 1
              ? Card(
                  key: const ValueKey(1),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        QrTile(
                          data: widget.credentials.qrPayload,
                          label: context.l10n.qrForWifi(widget.credentials.ssid),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.scanWithCamera.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 6),
                              _Credential(label: context.l10n.wifi, value: widget.credentials.ssid),
                              if (widget.credentials.security != HotspotSecurity.open)
                                _Credential(label: context.l10n.password, value: widget.credentials.password),
                              const SizedBox(height: 6),
                              FilledButton.tonal(
                                onPressed: () => setState(() => _step = 2),
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                                child: Text(context.l10n.next),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : JoinCard(
                  key: const ValueKey(2),
                  url: widget.url,
                  code: widget.code,
                  caption: context.l10n.thenScanThis,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.privateHotspotNote(widget.credentials.ssid),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({required this.step, required this.label, required this.selected, required this.onTap});

  final int step;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.surface : scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: context.l10n.stepLabel(step, label),
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.onSurface : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: fg,
                    foregroundColor: selected ? scheme.onSurface : scheme.surface,
                    child: Text('$step', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Credential extends StatelessWidget {
  const _Credential({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          SelectableText(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
