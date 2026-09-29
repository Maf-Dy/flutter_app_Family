import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../round/presentation/widgets/flip.dart';
import '../../../round/presentation/widgets/paper_slip.dart';
import '../../../room/presentation/team_style.dart';
import '../state/celebrity_cubit.dart';
import '../widgets/scoreboard.dart';

/// The team on turn sees the name, talks it over, and picks who on the other
/// team wrote it, betting double when they're sure.
class PickScreen extends StatefulWidget {
  const PickScreen({super.key});

  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  String? _picked;
  bool _doubled = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final game = context.watch<CelebrityCubit>().state.game;
    final current = game.current;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final color = teamColor(context, game.team);
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: color,
        foregroundColor: onColor,
        title: Text(l10n.teamTurn(teamName(l10n, game.team))),
      ),
      body: SafeArea(
        // Not a lazy list: the players to pick stay built below the slip, even on a short landscape screen.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.faceOffWhoWrote, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (current != null)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: FlipIn(
                      key: ValueKey((game.bowl.length, current.text, current.writerId)),
                      child: Semantics(
                        liveRegion: true,
                        child: PaperSlip(text: current.text, ink: current.ink, tiltDegrees: -2, large: true),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                l10n.namesLeft(game.bowl.length),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.faceOffTalkItOver,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              for (final (i, team) in game.teams.indexed)
                if (i != game.team)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 6, backgroundColor: teamColor(context, i)),
                            const SizedBox(width: 8),
                            Text(teamName(l10n, i), style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final id in team)
                              ChoiceChip(
                                label: Text(cubit.nameOf(id)),
                                selected: _picked == id,
                                onSelected: (_) => setState(() => _picked = id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  value: _doubled,
                  onChanged: (value) => setState(() => _doubled = value),
                  secondary: const Icon(Icons.casino_rounded),
                  title: Text(l10n.faceOffDouble, style: theme.textTheme.titleMedium),
                  subtitle: Text(l10n.faceOffDoubleDetail),
                ),
              ),
              const SizedBox(height: 12),
              Scoreboard(game: game),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _picked == null ? null : () => cubit.guess(_picked!, doubled: _doubled),
            child: Text(_picked == null ? l10n.faceOffPickSomeone : l10n.faceOffLockIn(cubit.nameOf(_picked!))),
          ),
        ),
      ),
    );
  }
}
