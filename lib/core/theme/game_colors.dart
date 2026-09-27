import 'package:flutter/material.dart';

/// Colours the Material [ColorScheme] has no slot for: the paper slips, the
/// "live" hosting state and one colour per player.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.slipPaper,
    required this.slipEdge,
    required this.slipInk,
    required this.live,
    required this.liveContainer,
    required this.players,
    required this.onPlayer,
  });

  static const light = GameColors(
    slipPaper: Color(0xFFFFE7A0),
    slipEdge: Color(0xFFE9C868),
    slipInk: Color(0xFF2A2440),
    live: Color(0xFF18896D),
    liveContainer: Color(0xFFD5F3EA),
    players: [
      Color(0xFF4A3FCF),
      Color(0xFFD9480F),
      Color(0xFF18896D),
      Color(0xFFB8327A),
      Color(0xFF1C7ED6),
      Color(0xFF8E6A00),
    ],
    onPlayer: Color(0xFFFFFFFF),
  );

  static const dark = GameColors(
    slipPaper: Color(0xFFEFD68A),
    slipEdge: Color(0xFFC9AE5C),
    slipInk: Color(0xFF2A2440),
    live: Color(0xFF4FD1AE),
    liveContainer: Color(0xFF123D33),
    players: [
      Color(0xFF8F85FF),
      Color(0xFFFF8A50),
      Color(0xFF4FD1AE),
      Color(0xFFF07AB8),
      Color(0xFF5BB0FF),
      Color(0xFFE0B94A),
    ],
    onPlayer: Color(0xFF14121F),
  );

  final Color slipPaper;
  final Color slipEdge;
  final Color slipInk;
  final Color live;
  final Color liveContainer;
  final List<Color> players;
  final Color onPlayer;

  /// Players keep their colour for the whole room, assigned in join order.
  Color player(int joinIndex) => players[joinIndex % players.length];

  @override
  GameColors copyWith({
    Color? slipPaper,
    Color? slipEdge,
    Color? slipInk,
    Color? live,
    Color? liveContainer,
    List<Color>? players,
    Color? onPlayer,
  }) => GameColors(
    slipPaper: slipPaper ?? this.slipPaper,
    slipEdge: slipEdge ?? this.slipEdge,
    slipInk: slipInk ?? this.slipInk,
    live: live ?? this.live,
    liveContainer: liveContainer ?? this.liveContainer,
    players: players ?? this.players,
    onPlayer: onPlayer ?? this.onPlayer,
  );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    return GameColors(
      slipPaper: Color.lerp(slipPaper, other.slipPaper, t)!,
      slipEdge: Color.lerp(slipEdge, other.slipEdge, t)!,
      slipInk: Color.lerp(slipInk, other.slipInk, t)!,
      live: Color.lerp(live, other.live, t)!,
      liveContainer: Color.lerp(liveContainer, other.liveContainer, t)!,
      players: [
        for (var i = 0; i < players.length; i++) Color.lerp(players[i], other.players[i % other.players.length], t)!,
      ],
      onPlayer: Color.lerp(onPlayer, other.onPlayer, t)!,
    );
  }
}

extension GameColorsContext on BuildContext {
  GameColors get gameColors => Theme.of(this).extension<GameColors>()!;
}
