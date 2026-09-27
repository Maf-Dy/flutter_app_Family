import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../theme/game_colors.dart';

/// One line on the card: a label, a value, and an optional colour dot.
typedef ShareCardRow = ({String label, String value, Color? color});

/// A picture of the night, made to be posted in the family group.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.title, required this.subtitle, required this.rows, this.more = 0});

  static const width = 360.0;

  final String title;
  final String subtitle;
  final List<ShareCardRow> rows;

  /// Rows left off the card to keep it readable.
  final int more;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final game = context.gameColors;
    final l10n = context.l10n;
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.wordmark, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              CircleAvatar(radius: 3.5, backgroundColor: scheme.tertiary),
              const Spacer(),
              Text(subtitle, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 14),
          for (final row in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: game.slipPaper, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: TextStyle(color: game.slipInk, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  if (row.color != null) ...[
                    CircleAvatar(radius: 5, backgroundColor: row.color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    row.value,
                    style: TextStyle(color: game.slipInk, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          if (more > 0)
            Text(l10n.moreOnCard(more), style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Shows [card] and lets the host share it as a picture.
Future<void> showShareCard(BuildContext context, ShareCard card) => showDialog<void>(
  context: context,
  builder: (context) => _ShareCardDialog(card: card),
);

class _ShareCardDialog extends StatefulWidget {
  const _ShareCardDialog({required this.card});

  final ShareCard card;

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('No image data');
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.shareCardText,
          files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'family-game.png')],
        ),
      );
    } catch (error) {
      debugPrint('ShareCard: $error');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: RepaintBoundary(key: _boundary, child: widget.card),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.share_rounded),
              label: Text(context.l10n.share),
            ),
          ],
        ),
      ),
    );
  }
}
