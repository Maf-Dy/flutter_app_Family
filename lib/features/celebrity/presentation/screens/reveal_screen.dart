import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/audio/game_sounds.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../round/presentation/widgets/paper_slip.dart';
import '../../../room/presentation/team_style.dart';
import '../../domain/face_off_game.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/scoreboard.dart';

/// Whether the guess was right, and the points it won or lost, after a short
/// drumroll. Who wrote the name stays secret until the results, so a reveal
/// can't be used to rule players out.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key, this.suspense = defaultSuspense});

  /// How long the drumroll beat lasts. None when the system asks for reduced motion.
  static const defaultSuspense = Duration(milliseconds: 1200);

  final Duration suspense;

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> with SingleTickerProviderStateMixin {
  late final _beat = AnimationController(vsync: this);
  bool _started = false;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final duration = Motion.of(context, widget.suspense);
    if (duration == Duration.zero) {
      _reveal(rebuild: false);
      return;
    }
    context.read<GameSounds>().drumroll();
    _beat.duration = duration;
    _beat.forward().whenComplete(() {
      if (mounted) _reveal();
    });
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  void _reveal({bool rebuild = true}) {
    if (_revealed) return;
    _beat.stop();
    final correct = context.read<CelebrityCubit>().state.game.lastGuess?.correct ?? false;
    final sounds = context.read<GameSounds>();
    if (correct) {
      Haptics.point();
      sounds.joy();
    } else {
      Haptics.timeUp();
      sounds.wrong();
    }
    // Before the first build there is nothing to rebuild yet.
    if (rebuild) {
      setState(() => _revealed = true);
    } else {
      _revealed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final game = context.watch<CelebrityCubit>().state.game;
    final guess = game.lastGuess!;
    final l10n = context.l10n;
    final team = teamName(l10n, game.team);
    final last = game.next().phase == FaceOffPhase.finished;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(l10n.teamTurn(team))),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A tap skips the drumroll.
          onTap: _revealed ? null : _reveal,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: PaperSlip(text: guess.slip.text, ink: guess.slip.ink, tiltDegrees: -2),
                ),
              ),
              const SizedBox(height: 16),
              if (_revealed) _Result(game: game, guess: guess) else _Drumroll(beat: _beat),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _revealed ? cubit.next : null,
            child: Text(last ? l10n.seeResults : l10n.nextTeam),
          ),
        ),
      ),
    );
  }
}

/// Three dots that bounce in turn while the drumroll plays.
class _Drumroll extends StatelessWidget {
  const _Drumroll({required this.beat});

  final Animation<double> beat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: context.l10n.faceOffSuspense,
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: AnimatedBuilder(
                animation: beat,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Transform.translate(
                        offset: Offset(0, -18 * _bounce(beat.value * 4 - i * 0.18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: CircleAvatar(radius: 9, backgroundColor: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Text(context.l10n.faceOffSuspense, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }

  /// 0 to 1 and back, once per whole number of [t].
  static double _bounce(double t) {
    final f = t - t.floorToDouble();
    return t < 0 ? 0 : Curves.easeOut.transform(1 - (2 * f - 1).abs());
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.game, required this.guess});

  final FaceOffGame game;
  final FaceOffGuess guess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final team = teamName(l10n, guess.team);
    final color = guess.correct ? context.gameColors.live : theme.colorScheme.error;
    final points = switch (guess.points) {
      0 => l10n.faceOffNoPoints(team),
      < 0 => l10n.faceOffLosesPoint(team),
      final won => l10n.turnScore(won, team),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: Motion.of(context, Motion.settle),
          curve: Motion.spring,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Icon(guess.correct ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 72, color: color),
                const SizedBox(height: 6),
                Text(
                  guess.correct ? l10n.faceOffRight : l10n.faceOffWrong,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          points,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(color: teamColor(context, guess.team)),
        ),
        if (guess.doubled) ...[
          const SizedBox(height: 4),
          Text(
            l10n.faceOffWasDouble,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.faceOffWritersAtEnd,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Scoreboard(game: game),
      ],
    );
  }
}
