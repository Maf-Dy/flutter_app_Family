import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../room/domain/room.dart';
import '../../celebrity_route.dart';
import '../../domain/celebrity_game.dart';
import '../../domain/teams.dart';

@immutable
final class CelebrityState {
  const CelebrityState({required this.game, required this.secondsLeft, required this.step});

  final CelebrityGame game;
  final int secondsLeft;

  /// Counts screen changes, so every stage change slides forward.
  final int step;

  CelebrityState copyWith({CelebrityGame? game, int? secondsLeft}) => CelebrityState(
    game: game ?? this.game,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    step: game != null && game.phase != this.game.phase ? step + 1 : step,
  );
}

/// Runs a team race: arranging teams, the turn clock, and scoring.
class CelebrityCubit extends Cubit<CelebrityState> {
  CelebrityCubit(this._args, {Random? random, @visibleForTesting this._runClock = true})
    : _random = random ?? Random(),
      super(
        CelebrityState(
          game: CelebrityGame.start(slips: _args.slips, teams: _initialTeams(_args, random ?? Random())),
          secondsLeft: _args.setup.turnSeconds,
          step: 0,
        ),
      );

  final CelebrityArgs _args;
  final Random _random;
  final bool _runClock;
  Timer? _clock;

  static List<List<String>> _initialTeams(CelebrityArgs args, Random random) => splitTeams(
    playerIds: [for (final p in args.players) p.id],
    count: args.setup.count,
    random: random,
    chosen: args.setup.pick == TeamPick.players ? {for (final p in args.players) p.id: p.team} : const {},
  );

  String nameOf(String playerId) {
    for (final p in _args.players) {
      if (p.id == playerId) return p.name;
    }
    return '';
  }

  TeamPick get teamPick => _args.setup.pick;

  void reshuffle() {
    if (teamPick == TeamPick.players) return;
    final teams = splitTeams(
      playerIds: [for (final p in _args.players) p.id],
      count: _args.setup.count,
      random: _random,
    );
    emit(state.copyWith(game: state.game.withTeams(teams)));
  }

  /// The host moves a player along to the next team.
  void movePlayer(String playerId) {
    if (teamPick != TeamPick.host) return;
    emit(state.copyWith(game: state.game.withTeams(moveToNextTeam(state.game.teams, playerId))));
  }

  void begin() => emit(state.copyWith(game: state.game.begin(_random)));

  void toHandOff() => emit(state.copyWith(game: state.game.toHandOff()));

  void startTurn() {
    final game = state.game.startTurn();
    if (identical(game, state.game)) return;
    emit(state.copyWith(game: game, secondsLeft: _args.setup.turnSeconds));
    if (_runClock) _clock = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void gotIt() {
    emit(state.copyWith(game: state.game.gotIt()));
    if (state.game.phase != CelebrityPhase.playing) _stopClock();
  }

  void skip() => emit(state.copyWith(game: state.game.skip()));

  /// One second of the turn clock.
  @visibleForTesting
  void tick() {
    if (state.game.phase != CelebrityPhase.playing) return _stopClock();
    final left = state.secondsLeft - 1;
    if (left > 0) return emit(state.copyWith(secondsLeft: left));
    _stopClock();
    emit(state.copyWith(game: state.game.timeUp(), secondsLeft: 0));
  }

  void nextTurn() => emit(state.copyWith(game: state.game.nextTurn(_random)));

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  @override
  Future<void> close() {
    _stopClock();
    return super.close();
  }
}
