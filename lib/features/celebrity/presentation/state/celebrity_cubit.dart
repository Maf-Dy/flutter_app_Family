import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../room/domain/room.dart';
import '../../celebrity_route.dart';
import '../../domain/face_off_game.dart';
import '../../domain/teams.dart';

@immutable
final class CelebrityState {
  const CelebrityState({required this.game, required this.step});

  final FaceOffGame game;

  /// Counts screen changes, so every stage change slides forward.
  final int step;

  CelebrityState copyWith({required FaceOffGame game}) =>
      CelebrityState(game: game, step: game.phase != this.game.phase ? step + 1 : step);
}

/// Runs a face-off: arranging teams, the guesses, and scoring.
class CelebrityCubit extends Cubit<CelebrityState> {
  CelebrityCubit(this._args, {Random? random})
    : _random = random ?? Random(),
      super(
        CelebrityState(
          game: FaceOffGame.start(slips: _args.slips, teams: _initialTeams(_args, random ?? Random())),
          step: 0,
        ),
      );

  final CelebrityArgs _args;
  final Random _random;

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

  /// The host moves a player along to the next team. Also when friends picked
  /// their own, so a team left short can still be fixed.
  void movePlayer(String playerId) {
    if (teamPick == TeamPick.random) return;
    emit(state.copyWith(game: state.game.withTeams(moveToNextTeam(state.game.teams, playerId))));
  }

  void begin() => emit(state.copyWith(game: state.game.begin(_random)));

  void guess(String playerId, {required bool doubled}) =>
      emit(state.copyWith(game: state.game.guess(playerId, doubled: doubled)));

  void next() => emit(state.copyWith(game: state.game.next()));
}
