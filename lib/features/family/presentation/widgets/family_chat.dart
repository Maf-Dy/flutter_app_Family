import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/family_game.dart';

/// The host's family's private chat. Newest at the bottom.
class FamilyChat extends StatefulWidget {
  const FamilyChat({super.key, required this.game, required this.me, required this.myHead, required this.onSend});

  final FamilyGame game;
  final String me;
  final String myHead;

  /// Returns whether the message went out.
  final bool Function(String text) onSend;

  @override
  State<FamilyChat> createState() => _FamilyChatState();
}

class _FamilyChatState extends State<FamilyChat> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().isEmpty) return;
    if (widget.onSend(_text.text)) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final messages = widget.game.chatFor(widget.myHead);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.familyChatSwitch, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (messages.isEmpty)
              Text(l10n.familyNoMessages, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  // Reversed, so the newest message sits at the bottom and stays in view.
                  reverse: true,
                  shrinkWrap: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[messages.length - 1 - i];
                    final mine = m.authorId == widget.me;
                    return Align(
                      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                widget.game.nameOf(m.authorId),
                                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            Text(m.text, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    maxLength: ChatMessage.maxLength,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: l10n.familyChatHint, counterText: ''),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(tooltip: l10n.familySend, onPressed: _send, icon: const Icon(Icons.send_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
