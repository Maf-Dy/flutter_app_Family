import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../room/domain/room.dart';

part 'round_state.dart';

/// One round at the table: read the slips aloud, leave them on screen, and
/// optionally reveal who wrote each one.
class RoundCubit extends Cubit<RoundState> {
  RoundCubit(List<Slip> slips, {Random? random})
    : assert(slips.isNotEmpty, 'A round needs at least one slip'),
      super(RoundState(slips: List.unmodifiable([...slips]..shuffle(random))));

  void next() {
    if (!state.isLast) emit(state.copyWith(index: state.index + 1));
  }

  void previous() {
    if (!state.isFirst) emit(state.copyWith(index: state.index - 1));
  }

  /// Start another read-through from the first slip, same order.
  void readAgain() => emit(state.copyWith(stage: RoundStage.reading, index: 0, pass: state.pass + 1));

  void finishReading() => emit(state.copyWith(stage: RoundStage.board));

  void openReveal() => emit(state.copyWith(stage: RoundStage.reveal));

  void backToBoard() => emit(state.copyWith(stage: RoundStage.board));

  void reveal(int slipIndex) {
    if (slipIndex < 0 || slipIndex >= state.slips.length || state.revealed.contains(slipIndex)) return;
    emit(state.copyWith(revealed: {...state.revealed, slipIndex}));
  }
}
