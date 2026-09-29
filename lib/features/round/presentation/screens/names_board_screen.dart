import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../state/round_cubit.dart';
import '../widgets/paper_slip.dart';
import '../../../../core/l10n/l10n.dart';

/// The phone goes down on the table here, the slips folded so nobody can read
/// the names off it. Nothing moves once they have settled, so the screen does
/// not pull eyes away from the game.
class NamesBoardScreen extends StatefulWidget {
  const NamesBoardScreen({super.key});

  @override
  State<NamesBoardScreen> createState() => _NamesBoardScreenState();
}

class _NamesBoardScreenState extends State<NamesBoardScreen> with SingleTickerProviderStateMixin {
  static const _stagger = Duration(milliseconds: 60);
  late final AnimationController _settle;
  late final int _count;

  @override
  void initState() {
    super.initState();
    _count = context.read<RoundCubit>().state.slips.length;
    final staggered = _stagger * math.min(_count, 20);
    _settle = AnimationController(vsync: this, duration: Motion.settle + staggered);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.isReduced(context)) {
      _settle.value = 1;
    } else if (!_settle.isAnimating && _settle.value == 0) {
      _settle.forward();
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoundCubit>().state;
    final cubit = context.read<RoundCubit>();
    final theme = Theme.of(context);
    final total = _settle.duration!.inMilliseconds;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.namesOnTheTable)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                context.l10n.boardHintHidden,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final columns = math.max(2, (constraints.maxWidth - 32) ~/ 170);
                  final width = (constraints.maxWidth - 32 - gap * (columns - 1)) / columns;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap + 4,
                      children: [
                        for (final (i, _) in state.slips.indexed)
                          SizedBox(
                            width: width,
                            child: _SettleIn(
                              animation: CurvedAnimation(
                                parent: _settle,
                                curve: Interval(
                                  (_stagger.inMilliseconds * math.min(i, 20)) / total,
                                  ((_stagger.inMilliseconds * math.min(i, 20)) + Motion.settle.inMilliseconds) / total,
                                  curve: Motion.spring,
                                ),
                              ),
                              // Folded: playing from memory is the game, so the names stay hidden until "Who wrote what?".
                              child: PaperSlip(text: '?', tiltDegrees: slipTilt(i)),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonal(onPressed: cubit.readAgain, child: Text(context.l10n.readAgain)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: FilledButton(onPressed: cubit.openReveal, child: Text(context.l10n.whoWroteWhat)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettleIn extends AnimatedWidget {
  const _SettleIn({required Animation<double> animation, required this.child}) : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, (1 - t) * -16), child: child),
    );
  }
}
