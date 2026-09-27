import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

/// A coloured circle with the player's initial. Colour follows join order, and
/// the initial means no one depends on colour alone.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.name, required this.joinIndex, this.size = 32});

  final String name;
  final int joinIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.player(joinIndex), shape: BoxShape.circle),
        child: Text(
          initial,
          style: TextStyle(color: colors.onPlayer, fontWeight: FontWeight.w800, fontSize: size * 0.42, height: 1),
        ),
      ),
    );
  }
}
