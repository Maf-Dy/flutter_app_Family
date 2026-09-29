import 'family_game.dart';

/// The funny titles handed out when a family game ends.
enum AwardKind {
  /// The first one caught: "أسوأ كداب".
  worstLiar,

  /// The head of the winning family, the last one nobody could read: "وش البوكر".
  pokerFace,

  /// The most wrongly accused: "أكتر واحد اتظلم".
  wronged,

  /// The most catches: "المخبر".
  detective,
}

/// One title, who earned it, and the count behind it where there is one.
typedef NightAward = ({AwardKind kind, String playerId, int count});

/// The awards of the night, in [AwardKind] order. A title nobody earned is left
/// out; ties go to whoever joined first.
List<NightAward> nightAwards(FamilyGame game) {
  final asks = [
    for (final e in game.events)
      if (!e.blocked) e,
  ];
  final firstCatch = asks.where((e) => e.caught).firstOrNull;
  int most(Map<String, int> counts) => counts.values.fold(0, (a, b) => a > b ? a : b);
  String? top(Map<String, int> counts) {
    final best = most(counts);
    if (best == 0) return null;
    return game.players.map((p) => p.id).firstWhere((id) => counts[id] == best);
  }

  final wronged = <String, int>{};
  final catches = <String, int>{};
  for (final e in asks) {
    if (!e.correct) wronged[e.targetId] = (wronged[e.targetId] ?? 0) + 1;
    if (e.caught) catches[e.askerId] = (catches[e.askerId] ?? 0) + 1;
  }
  final mostWronged = top(wronged);
  final detective = top(catches);
  final winner = game.winner;
  return [
    if (firstCatch != null) (kind: AwardKind.worstLiar, playerId: firstCatch.targetId, count: 1),
    if (winner != null) (kind: AwardKind.pokerFace, playerId: winner, count: 0),
    if (mostWronged != null) (kind: AwardKind.wronged, playerId: mostWronged, count: wronged[mostWronged]!),
    if (detective != null) (kind: AwardKind.detective, playerId: detective, count: catches[detective]!),
  ];
}

/// Who caught whom, as a tree: each player's parent is the person whose catch
/// brought them into the family they ended in. The winner is the root; anyone
/// else without a parent hangs off the winner too.
Map<String, String?> familyTree(FamilyGame game) {
  final parent = <String, String?>{for (final p in game.players) p.id: null};
  for (final e in game.events) {
    if (e.blocked || !e.caught) continue;
    parent[e.targetId] = e.askerId;
    // The rest of a swallowed family stay under whoever brought them in; its head comes along with the one caught.
    final head = e.swallowedHead;
    if (head != null && head != e.targetId && e.joined.contains(head)) parent[head] = e.targetId;
  }
  final root = game.winner ?? (game.players.isEmpty ? null : game.players.first.id);
  if (root == null) return parent;
  parent[root] = null;
  // Counter-catches can flip families both ways; any loop is cut at the root.
  for (final id in parent.keys.toList()) {
    final seen = <String>{id};
    var at = parent[id];
    while (at != null) {
      if (!seen.add(at)) {
        parent[id] = root;
        break;
      }
      at = parent[at];
    }
    if (id != root && parent[id] == null) parent[id] = root;
  }
  return parent;
}

/// The tree as lines to draw, depth first from the root: each player with how deep they sit.
List<({String playerId, int depth})> familyTreeLines(FamilyGame game) {
  final parent = familyTree(game);
  final root = parent.entries.where((e) => e.value == null).map((e) => e.key).firstOrNull;
  if (root == null) return const [];
  final order = [for (final p in game.players) p.id];
  final lines = <({String playerId, int depth})>[];
  void visit(String id, int depth) {
    lines.add((playerId: id, depth: depth));
    for (final child in order.where((c) => parent[c] == id)) {
      visit(child, depth + 1);
    }
  }

  visit(root, 0);
  return lines;
}
