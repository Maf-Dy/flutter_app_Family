import 'dart:math';

import 'package:family_game/features/celebrity/domain/teams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ids = [for (var i = 0; i < 7; i++) 'p$i'];

  test('random split is balanced and uses everyone once', () {
    final teams = splitTeams(playerIds: ids, count: 3, random: Random(1));
    expect(teams.map((t) => t.length).toList()..sort(), [2, 2, 3]);
    expect(teams.expand((t) => t), unorderedEquals(ids));
  });

  test('keeps players\' own picks and balances the rest in', () {
    final teams = splitTeams(playerIds: ids, count: 2, random: Random(2), chosen: {'p0': 0, 'p1': 0, 'p2': 0, 'p3': 1});
    expect(teams[0], containsAll(['p0', 'p1', 'p2']));
    expect(teams[1], contains('p3'));
    expect(teams[0].length + teams[1].length, 7);
    expect((teams[0].length - teams[1].length).abs(), lessThanOrEqualTo(1));
  });

  test('the host moves a player to the next team, wrapping around', () {
    final teams = [
      ['a', 'b'],
      ['c'],
    ];
    expect(moveToNextTeam(teams, 'a'), [
      ['b'],
      ['c', 'a'],
    ]);
    expect(moveToNextTeam(teams, 'c'), [
      ['a', 'b', 'c'],
      <String>[],
    ]);
  });

  test('never leaves a team empty, even when every friend picks the same team', () {
    final everyonePicksPurple = {for (final id in ids) id: 0};
    final teams = splitTeams(playerIds: ids, count: 3, random: Random(3), chosen: everyonePicksPurple);
    expect(teams.every((t) => t.isNotEmpty), isTrue);
    expect(teams.expand((t) => t), unorderedEquals(ids));
    // Only as many picks are overruled as it takes to fill the empty teams.
    expect(teams[0], hasLength(5));
  });

  test('fills empty teams with friends who did not pick before overruling a pick', () {
    final teams = splitTeams(
      playerIds: ['a', 'b', 'c', 'd'],
      count: 2,
      random: Random(4),
      chosen: {'a': 0, 'b': 0, 'c': 0},
    );
    expect(teams[0], containsAll(['a', 'b', 'c']));
    expect(teams[1], ['d']);
  });
}
