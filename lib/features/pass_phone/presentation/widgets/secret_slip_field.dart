import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../room/domain/room.dart';

/// One secret name on a paper slip. It shows while you type in it and hides
/// itself as soon as you move on; tapping it again shows it to fix it.
class SecretSlipField extends StatefulWidget {
  const SecretSlipField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SecretSlipField> createState() => _SecretSlipFieldState();
}

class _SecretSlipFieldState extends State<SecretSlipField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final hidden = !_focus.hasFocus;
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: hidden,
      enableSuggestions: false,
      autocorrect: false,
      textCapitalization: TextCapitalization.words,
      maxLength: Room.maxSecretLength,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      style: TextStyle(
        fontFamily: AppFonts.hand,
        fontFamilyFallback: AppFonts.arabicHand,
        fontSize: 20,
        color: game.slipInk,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        counterText: '',
        filled: true,
        fillColor: game.slipPaper,
        labelStyle: TextStyle(color: game.slipInk.withValues(alpha: 0.7)),
        floatingLabelStyle: TextStyle(color: game.slipInk),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: game.slipEdge, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: game.slipInk, width: 2),
        ),
        suffixIcon: hidden && widget.controller.text.isNotEmpty
            ? Icon(Icons.visibility_off_rounded, color: game.slipInk.withValues(alpha: 0.6))
            : null,
      ),
    );
  }
}
