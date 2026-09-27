import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/platform/haptics.dart';
import '../state/round_cubit.dart';
import '../widgets/flip.dart';
import '../widgets/paper_slip.dart';

class ReadAloudScreen extends StatelessWidget {
  const ReadAloudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoundCubit>().state;
    final cubit = context.read<RoundCubit>();
    final theme = Theme.of(context);
    final total = state.slips.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.pass == 1 ? 'Read aloud' : 'Read again'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Text(
              '${state.index + 1} / $total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _Progress(index: state.index, total: total),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320, minHeight: 150),
                    child: FlipIn(
                      key: ValueKey((state.pass, state.index)),
                      child: Semantics(
                        liveRegion: true,
                        label: 'Name ${state.index + 1} of $total',
                        child: PaperSlip(text: state.current.text, tiltDegrees: -2, large: true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              state.isLast ? 'That was the last one.' : 'Read it out, then tap Next.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: state.isLast
                        ? FilledButton.tonal(onPressed: cubit.readAgain, child: const Text('Read again'))
                        : FilledButton.tonal(
                            onPressed: state.isFirst ? null : cubit.previous,
                            child: const Text('Back'),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: state.isLast
                        ? FilledButton(onPressed: cubit.finishReading, child: const Text('Done reading'))
                        : FilledButton(
                            onPressed: () {
                              Haptics.tick();
                              cubit.next();
                            },
                            child: const Text('Next name'),
                          ),
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

class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (total > 20) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(value: (index + 1) / total, minHeight: 4),
      );
    }
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: i <= index ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
