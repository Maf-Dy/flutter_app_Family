import 'dart:math';

import 'package:family_game/core/audio/game_sounds.dart';
import 'package:family_game/core/l10n/l10n.dart';
import 'package:family_game/core/theme/app_theme.dart';
import 'package:family_game/features/celebrity/celebrity_route.dart';
import 'package:family_game/features/celebrity/presentation/screens/reveal_screen.dart';
import 'package:family_game/features/celebrity/presentation/state/celebrity_cubit.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late FakeSoundPlayer player;
  late CelebrityCubit cubit;

  setUp(() {
    player = FakeSoundPlayer();
    cubit = CelebrityCubit(
      CelebrityArgs(
        category: const GameCategory.preset(PresetCategory.famousPeople),
        slips: [
          for (final (i, text) in ['Messi', 'Fairuz', 'Adele', 'Mr. Bean'].indexed)
            Slip(text: text, writerId: 'p$i', writerName: 'P$i'),
        ],
        players: [for (var i = 0; i < 4; i++) (id: 'p$i', name: 'P$i', team: i ~/ 2)],
        setup: const TeamSetup(pick: TeamPick.players),
      ),
      random: Random(3),
    )..begin();
  });

  tearDown(() => cubit.close());

  /// The team on turn guesses the current name, rightly or not.
  void guess({required bool right}) {
    final game = cubit.state.game;
    final writer = game.current!.writerId;
    cubit.guess(right ? writer : game.suspects.firstWhere((id) => id != writer), doubled: false);
  }

  Future<void> pumpReveal(WidgetTester tester, {bool reducedMotion = false, bool soundOn = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
        home: RepositoryProvider<GameSounds>.value(
          value: GameSounds(player, enabled: () => soundOn),
          child: BlocProvider.value(value: cubit, child: const RevealScreen()),
        ),
      ),
    );
  }

  FilledButton nextButton(WidgetTester tester) => tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('a drumroll, then right with a zaghrouta', (tester) async {
    guess(right: true);
    await pumpReveal(tester);
    expect(find.text('And the answer is…'), findsOneWidget);
    expect(find.text('Right!'), findsNothing);
    expect(find.text(cubit.state.game.lastGuess!.slip.text), findsOneWidget, reason: 'the slip shows');
    expect(nextButton(tester).onPressed, isNull, reason: 'no moving on before the answer');
    expect(player.played, [GameSound.drumroll]);

    await tester.pump(RevealScreen.defaultSuspense);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Right!'), findsOneWidget);
    expect(find.text('And the answer is…'), findsNothing);
    expect(
      find.textContaining(cubit.state.game.lastGuess!.slip.writerName),
      findsNothing,
      reason: 'who wrote it stays secret',
    );
    expect(nextButton(tester).onPressed, isNotNull);
    expect(player.played, [GameSound.drumroll, GameSound.joy]);
  });

  testWidgets('wrong gets the sad trombone, and a tap skips the drumroll', (tester) async {
    guess(right: false);
    await pumpReveal(tester);
    expect(player.played, [GameSound.drumroll]);
    await tester.tap(find.text('And the answer is…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Wrong!'), findsOneWidget);
    expect(player.played, [GameSound.drumroll, GameSound.wrong]);
    // The skipped drumroll doesn't reveal a second time.
    await tester.pump(RevealScreen.defaultSuspense);
    expect(player.played, [GameSound.drumroll, GameSound.wrong]);
  });

  testWidgets('reduced motion: no drumroll, the answer shows at once', (tester) async {
    guess(right: true);
    await pumpReveal(tester, reducedMotion: true);
    expect(find.text('Right!'), findsOneWidget);
    expect(player.played, [GameSound.joy]);
  });

  testWidgets('sound effects off: the same beat, in silence', (tester) async {
    guess(right: false);
    await pumpReveal(tester, soundOn: false);
    await tester.pump(RevealScreen.defaultSuspense);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Wrong!'), findsOneWidget);
    expect(player.played, isEmpty);
  });
}
