import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';

/// The host's own secret name, typed hidden so the table can't read it.
class HostSecretField extends StatefulWidget {
  const HostSecretField({super.key, required this.onSubmit, required this.label});

  /// Returns whether the name was accepted; the field only clears when it was.
  final bool Function(String secret) onSubmit;
  final String label;

  @override
  State<HostSecretField> createState() => _HostSecretFieldState();
}

class _HostSecretFieldState extends State<HostSecretField> {
  final _controller = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    if (!widget.onSubmit(_controller.text)) return;
    _controller.clear();
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            obscureText: _hidden,
            enableSuggestions: false,
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.label,
              counterText: '',
              suffixIcon: IconButton(
                tooltip: _hidden ? context.l10n.show : context.l10n.hide,
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: context.l10n.dropInBowl,
          onPressed: _submit,
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
