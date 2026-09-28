import 'dart:math';

/// Fewest players on a team: one gives clues, at least one guesses.
const minTeamSize = 2;

/// Splits [playerIds] into [count] teams whose sizes differ by at most one.
///
/// [chosen] holds the team each player picked, if any. Picks are kept, then
/// everyone else is shuffled into the smallest teams. Picks that would leave a
/// team more than one player larger than another are kept anyway: a friend's
/// own choice wins over perfect balance, except that no team is left with
/// fewer than [minTeamSize] while other teams can spare a player.
List<List<String>> splitTeams({
  required List<String> playerIds,
  required int count,
  required Random random,
  Map<String, int?> chosen = const {},
}) {
  final teams = [for (var i = 0; i < count; i++) <String>[]];
  final free = <String>[];
  for (final id in playerIds) {
    final pick = chosen[id];
    if (pick != null && pick >= 0 && pick < count) {
      teams[pick].add(id);
    } else {
      free.add(id);
    }
  }
  free.shuffle(random);
  for (final id in free) {
    final smallest = teams.reduce((a, b) => b.length < a.length ? b : a);
    smallest.add(id);
  }
  // Too many friends picked the same team: move the latest picks along until
  // every team has a clue-giver and a guesser, when there are players enough.
  for (final small in teams) {
    while (small.length < minTeamSize) {
      final largest = teams.reduce((a, b) => b.length > a.length ? b : a);
      if (largest.length <= minTeamSize) break;
      small.add(largest.removeLast());
    }
  }
  return [for (final team in teams) List.unmodifiable(team)];
}

/// Moves [playerId] to the next team along, for the host rearranging by hand.
List<List<String>> moveToNextTeam(List<List<String>> teams, String playerId) {
  final from = teams.indexWhere((team) => team.contains(playerId));
  if (from < 0) return teams;
  final to = (from + 1) % teams.length;
  return [
    for (final (i, team) in teams.indexed)
      List.unmodifiable([
        for (final id in team)
          if (id != playerId || i == to) id,
        if (i == to && i != from) playerId,
      ]),
  ];
}
