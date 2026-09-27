import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/family_game.dart';
import '../../domain/family_table.dart';

@immutable
final class FamilyState {
  const FamilyState({required this.game, this.error});

  final FamilyGame game;

  /// Why the host's last move was refused. One-shot: the next state clears it.
  final FamilyActionError? error;
}

/// The host's seat at the family table. Friends play from their browsers; the
/// host plays here as [me], or only watches when [me] is null.
class FamilyCubit extends Cubit<FamilyState> {
  FamilyCubit({required this._table, required FamilyGame game, required this.me}) : super(FamilyState(game: game)) {
    _sub = _table.changes.listen((game) {
      if (!isClosed) emit(FamilyState(game: game));
    });
  }

  final FamilyTable _table;
  final String? me;
  late final StreamSubscription<FamilyGame> _sub;

  bool get isPlaying => me != null && state.game.player(me!) != null;

  /// The head of the host's family, or null when watching.
  String? get myHead => isPlaying ? state.game.headOf(me!) : null;

  void guess(String targetId, int slipId) =>
      _move((g, me) => g.checkGuess(me, targetId, slipId), (g, me) => g.guess(me, targetId, slipId));

  void suggest(String targetId, int slipId) =>
      _move((g, me) => g.checkSuggestion(me, targetId, slipId), (g, me) => g.suggest(me, targetId, slipId));

  void unvote() => _move((_, _) => null, (g, me) => g.unvote(me));

  void say(String text) => _move((g, me) => g.checkMessage(me, text), (g, me) => g.say(me, text));

  void _move(
    FamilyActionError? Function(FamilyGame game, String me) check,
    FamilyGame Function(FamilyGame game, String me) move,
  ) {
    final me = this.me;
    if (me == null || !isPlaying) return;
    final error = check(state.game, me);
    if (error != null) return emit(FamilyState(game: state.game, error: error));
    _table.apply((game) => move(game, me));
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
