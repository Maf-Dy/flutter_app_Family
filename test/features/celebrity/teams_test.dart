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
}
