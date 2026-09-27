import 'dart:math';

import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/round/presentation/state/round_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final slips = [
    for (final (i, text) in ['Messi', 'Fairuz', 'Adele', 'Mr. Bean'].indexed)
      Slip(text: text, writerId: 'p$i', writerName: 'Player $i'),
  ];

  test('shuffles every slip exactly once', () {
    final cubit = RoundCubit(slips, random: Random(4));
    expect(cubit.state.slips.map((s) => s.text), unorderedEquals(slips.map((s) => s.text)));
    expect(cubit.state.stage, RoundStage.reading);
  });

  test('steps through the names within bounds', () {
    final cubit = RoundCubit(slips, random: Random(1))..previous();
    expect(cubit.state.index, 0);
    for (var i = 0; i < 10; i++) {
      cubit.next();
    }
    expect(cubit.state.index, 3);
    expect(cubit.state.isLast, isTrue);
    cubit.previous();
    expect(cubit.state.index, 2);
  });

  test('reading again starts over in the same order', () {
    final cubit = RoundCubit(slips, random: Random(2));
    final order = cubit.state.slips;
    cubit
      ..next()
      ..next()
      ..finishReading()
      ..readAgain();
    expect(cubit.state.stage, RoundStage.reading);
    expect(cubit.state.index, 0);
    expect(cubit.state.pass, 2);
    expect(cubit.state.slips, order);
  });

  test('reveals each slip once and knows when all are shown', () {
    final cubit = RoundCubit(slips, random: Random(3))
      ..finishReading()
      ..openReveal();
    expect(cubit.state.stage, RoundStage.reveal);
    cubit
      ..reveal(1)
      ..reveal(1)
      ..reveal(99);
    expect(cubit.state.revealed, {1});
    for (var i = 0; i < slips.length; i++) {
      cubit.reveal(i);
    }
    expect(cubit.state.allRevealed, isTrue);
    cubit.backToBoard();
    expect(cubit.state.stage, RoundStage.board);
  });
}
