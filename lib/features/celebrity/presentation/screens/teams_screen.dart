import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../room/domain/room.dart';
import '../state/celebrity_cubit.dart';
import '../../../room/presentation/team_style.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CelebrityCubit>();
    final game = context.watch<CelebrityCubit>().state.game;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pick = cubit.teamPick;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teams),
        actions: [
          if (pick != TeamPick.players)
            TextButton.icon(
              onPressed: cubit.reshuffle,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(l10n.reshuffle),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            if (pick != TeamPick.random)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  pick == TeamPick.host ? l10n.tapToMove : l10n.teamsChosenNote,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            for (final (i, team) in game.teams.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: teamColor(context, i),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          teamName(l10n, i),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: team.isEmpty
                            ? Text(l10n.teamNeedsPlayers, style: TextStyle(color: theme.colorScheme.error))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final id in team)
                                    if (pick == TeamPick.host)
                                      ActionChip(
                                        avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
                                        label: Text(cubit.nameOf(id)),
                                        onPressed: () => cubit.movePlayer(id),
                                      )
                                    else
                                      Chip(label: Text(cubit.nameOf(id))),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: game.teamsPlayable ? cubit.begin : null, child: Text(l10n.letsPlay)),
        ),
      ),
    );
  }
}
