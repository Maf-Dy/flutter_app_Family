import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/game_exit.dart';
import '../../../celebrity/celebrity_route.dart';
import '../../../room/domain/room.dart';
import '../../../round/round_route.dart';
import '../../domain/pass_bowl.dart';

enum PassStage {
  /// Category, names each, the game.
  setup,

  /// One person types their name and secret names.
  typing,

  /// Their names are hidden; the phone goes to the next person.
  passed,

  /// Classic only: the phone goes to whoever reads the names out.
  reader,
}

@immutable
final class PassPhoneState {
  const PassPhoneState({
    this.category = const GameCategory.preset(PresetCategory.famousPeople),
    this.namesPerPlayer = 1,
    this.allowDuplicates = true,
    this.mode = GameMode.classic,
    this.teamSetup = const TeamSetup(),
    this.stage = PassStage.setup,
    this.bowl,
    this.lastName,
    this.step = 0,
  });

  final GameCategory category;
  final int namesPerPlayer;
  final bool allowDuplicates;

  /// [GameMode.classic] or [GameMode.celebrity]; the family game needs everyone's phone.
  final GameMode mode;
  final TeamSetup teamSetup;
  final PassStage stage;

  /// Null until passing starts.
  final PassBowl? bowl;

  /// Whose names just went in, for the "in the bowl" screen.
  final String? lastName;

  /// Counts screen changes, so every change slides forward, even typing to typing.
  final int step;

  PassPhoneState copyWith({
    GameCategory? category,
    int? namesPerPlayer,
    bool? allowDuplicates,
    GameMode? mode,
    TeamSetup? teamSetup,
    PassStage? stage,
    PassBowl? bowl,
    bool clearBowl = false,
    String? lastName,
  }) => PassPhoneState(
    category: category ?? this.category,
    namesPerPlayer: namesPerPlayer ?? this.namesPerPlayer,
    allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    mode: mode ?? this.mode,
    teamSetup: teamSetup ?? this.teamSetup,
    stage: stage ?? this.stage,
    bowl: clearBowl ? null : bowl ?? this.bowl,
    lastName: lastName ?? this.lastName,
    step: stage != null && stage != this.stage || stage == PassStage.typing ? step + 1 : step,
  );
}

/// The one-phone game: settings, then each person's turn, then the game itself.
class PassPhoneCubit extends Cubit<PassPhoneState> {
  PassPhoneCubit() : super(const PassPhoneState());

  void selectCategory(GameCategory category) => emit(state.copyWith(category: category));

  void setNamesPerPlayer(int count) => emit(state.copyWith(namesPerPlayer: count.clamp(1, Room.maxNamesPerPlayer)));

  void setAllowDuplicates(bool allow) => emit(state.copyWith(allowDuplicates: allow));

  void setMode(GameMode mode) {
    if (mode == GameMode.family) return;
    emit(state.copyWith(mode: mode));
  }

  /// Friends can't pick teams on a join page here, so that choice becomes random.
  void setTeamSetup(TeamSetup setup) =>
      emit(state.copyWith(teamSetup: setup.pick == TeamPick.players ? setup.copyWith(pick: TeamPick.random) : setup));

  void begin() {
    if (state.stage != PassStage.setup) return;
    emit(
      state.copyWith(
        stage: PassStage.typing,
        bowl: PassBowl.start(
          category: state.category,
          namesPerPlayer: state.namesPerPlayer,
          allowDuplicates: state.allowDuplicates,
          mode: state.mode,
          teamSetup: state.teamSetup,
        ),
      ),
    );
  }

  /// Puts one person's names in the bowl and hides them. Returns why not, or null.
  PassError? submit({required String name, required List<String> secrets}) {
    final bowl = state.bowl;
    if (bowl == null || state.stage != PassStage.typing) return PassError.full;
    final error = bowl.validate(name: name, secrets: secrets);
    if (error != null) return error;
    emit(
      state.copyWith(
        stage: PassStage.passed,
        bowl: bowl.submit(name: name, secrets: secrets),
        lastName: Room.tidy(name),
      ),
    );
    return null;
  }

  /// The next person took the phone.
  void next() {
    if (state.stage == PassStage.passed) emit(state.copyWith(stage: PassStage.typing));
  }

  /// Leaving someone's turn without saving, once someone is in: back to the hand-off.
  void cancelTurn() {
    if (state.stage == PassStage.typing && (state.bowl?.playersIn.isNotEmpty ?? false)) {
      emit(state.copyWith(stage: PassStage.passed));
    }
  }

  /// Throws the bowl away and goes back to setup.
  void stop() => emit(state.copyWith(stage: PassStage.setup, clearBowl: true));

  /// Everyone's in. Classic hands the phone to a reader first; Team race goes straight to the teams.
  void everyoneIn() {
    if (state.stage != PassStage.passed || !(state.bowl?.canStart ?? false)) return;
    if (state.mode == GameMode.classic) emit(state.copyWith(stage: PassStage.reader));
  }

  /// Back from the reader hand-off to passing, with the names kept.
  void backToPassing() {
    if (state.stage == PassStage.reader) emit(state.copyWith(stage: PassStage.passed));
  }

  RoundArgs? roundArgs() {
    final bowl = state.bowl;
    if (bowl == null || !bowl.canStart || state.mode != GameMode.classic) return null;
    return RoundArgs(category: state.category, slips: bowl.slips, players: [for (final p in bowl.players) p.id]);
  }

  CelebrityArgs? celebrityArgs() {
    final bowl = state.bowl;
    if (bowl == null || !bowl.canStart || state.mode != GameMode.celebrity) return null;
    return CelebrityArgs(
      category: state.category,
      slips: bowl.slips,
      players: [for (final p in bowl.playersIn) (id: p.id, name: p.name, team: null)],
      setup: state.teamSetup,
    );
  }

  /// Back from the game. A new round keeps everyone and empties the bowl;
  /// leaving the game early keeps the names and goes back to passing.
  void afterGame(GameExit? exit) {
    final bowl = state.bowl;
    if (bowl == null) return;
    switch (exit) {
      case GameExit.newRound:
        emit(state.copyWith(stage: PassStage.typing, bowl: bowl.nextRound()));
      case GameExit.endGame:
        break;
      case null:
        emit(state.copyWith(stage: PassStage.passed));
    }
  }
}
