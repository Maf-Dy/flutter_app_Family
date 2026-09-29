import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/family_game.dart';
import '../../domain/family_table.dart';

/// The host's seat at the family table. Friends play from their browsers; the
/// host plays here as [me], or only watches when [me] is null.
///
/// Every move returns why it was refused, or null once it is on the table.
class FamilyCubit extends Cubit<FamilyGame> {
  FamilyCubit({required this._table, required FamilyGame game, required this.me}) : super(game) {
    _sub = _table.changes.listen((game) {
      if (!isClosed) emit(game);
    });
  }

  final FamilyTable _table;
  final String? me;
  late final StreamSubscription<FamilyGame> _sub;

  bool get isPlaying => me != null && state.player(me!) != null;

  /// The head of the host's family, or null when watching.
  String? get myHead => isPlaying ? state.headOf(me!) : null;

  FamilyActionError? guess(String targetId, int slipId) =>
      _move((g, me) => g.checkGuess(me, targetId, slipId), (g, me) => g.guess(me, targetId, slipId));

  FamilyActionError? suggest(String targetId, int slipId) =>
      _move((g, me) => g.checkSuggestion(me, targetId, slipId), (g, me) => g.suggest(me, targetId, slipId));

  FamilyActionError? unvote() => _move((_, _) => null, (g, me) => g.unvote(me));

  /// The host left the app (a call, another app, the lock screen) or came back.
  /// While away, a family member asks for them, as for any friend who dropped.
  void setAway(bool away) {
    final me = this.me;
    if (me == null || !isPlaying) return;
    _table.apply((game) => game.withAway(away ? {...game.away, me} : ({...game.away}..remove(me))));
  }

  /// Passes the turn on from a family whose phones all dropped out. The host decides, even when only watching.
  void skipTurn() => _table.apply((game) => game.skipTurn());

  /// Lets someone on a new phone back in as a dropped player, or turns them away.
  void resolveClaim(String clientId, {required bool approve}) =>
      _table.apply((game) => game.resolveClaim(clientId, approve: approve));

  /// The host, asked about, says "فكّك مني" ([use]) or lets it be answered.
  FamilyActionError? answerLetMeGo({required bool use}) =>
      _move((g, me) => g.checkAnswer(me, PendingKind.letMeGo), (g, me) => g.answerLetMeGo(me, use: use));

  FamilyActionError? counterCatch(String targetId, int slipId) =>
      _move((g, me) => g.checkCounter(me, targetId, slipId), (g, me) => g.counterCatch(me, targetId, slipId));

  FamilyActionError? passCounter() =>
      _move((g, me) => g.checkAnswer(me, PendingKind.counter), (g, me) => g.passCounter(me));

  FamilyActionError? revenge(int slipId) =>
      _move((g, me) => g.checkRevenge(me, slipId), (g, me) => g.revenge(me, slipId));

  FamilyActionError? passRevenge() =>
      _move((g, me) => g.checkAnswer(me, PendingKind.revenge), (g, me) => g.passRevenge(me));

  FamilyActionError? spreadRumor(String targetId, int slipId) =>
      _move((g, me) => g.checkRumor(me, targetId, slipId), (g, me) => g.spreadRumor(me, targetId, slipId));

  FamilyActionError? say(String text) => _move((g, me) => g.checkMessage(me, text), (g, me) => g.say(me, text));

  FamilyActionError? _move(
    FamilyActionError? Function(FamilyGame game, String me) check,
    FamilyGame Function(FamilyGame game, String me) move,
  ) {
    final me = this.me;
    if (me == null || !isPlaying) return FamilyActionError.invalidTarget;
    // Checked against the table itself: a friend's move may have landed since this screen last redrew.
    final game = _table.game ?? state;
    final error = check(game, me);
    if (error == null) _table.apply((game) => move(game, me));
    return error;
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
