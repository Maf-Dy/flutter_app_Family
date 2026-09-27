part of 'round_cubit.dart';

enum RoundStage { reading, board, reveal }

@immutable
final class RoundState {
  const RoundState({
    required this.slips,
    this.stage = RoundStage.reading,
    this.index = 0,
    this.pass = 1,
    this.revealed = const {},
  });

  /// Shuffled once per round; the board and the reveal keep this order.
  final List<Slip> slips;
  final RoundStage stage;

  /// The slip on screen while reading.
  final int index;

  /// 1 on the first read-through, 2 on the second, and so on.
  final int pass;

  /// Slips turned over on the "who wrote what" stage.
  final Set<int> revealed;

  Slip get current => slips[index];
  bool get isFirst => index == 0;
  bool get isLast => index == slips.length - 1;
  bool get allRevealed => revealed.length == slips.length;

  RoundState copyWith({RoundStage? stage, int? index, int? pass, Set<int>? revealed}) => RoundState(
    slips: slips,
    stage: stage ?? this.stage,
    index: index ?? this.index,
    pass: pass ?? this.pass,
    revealed: revealed == null ? this.revealed : Set.unmodifiable(revealed),
  );
}
