import 'dart:math';

import 'package:family_game/features/pass_phone/domain/pass_bowl.dart';
import 'package:family_game/features/room/domain/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/ink.dart';

void main() {
  const room = Room(
    code: 'K7Q4',
    category: GameCategory.preset(PresetCategory.famousPeople),
    namesPerPlayer: 2,
    hostName: 'Mafdy',
    handwritten: true,
    allowDuplicates: false,
  );

  group('SlipInk', () {
    test('takes a PNG within the limits, and nothing else', () {
      expect(SlipInk.tryParse(tinyPng), isNotNull);
      expect(SlipInk.tryParse(pngHeader(480, 240))!.width, 480);
      expect(SlipInk.tryParse(pngHeader(481, 10)), isNull, reason: 'too wide');
      expect(SlipInk.tryParse(pngHeader(10, 241)), isNull, reason: 'too tall');
      expect(SlipInk.tryParse(pngHeader(0, 10)), isNull);
      expect(SlipInk.tryParse(pngHeader(10, 10, extra: SlipInk.maxBytes)), isNull, reason: 'over 80 KB');
      expect(SlipInk.tryParse('GIF89a not a png at all, no no no no'.codeUnits), isNull);
      expect(SlipInk.tryParse(const []), isNull);
    });

    test('round-trips through a data URL, and refuses other kinds', () {
      final ink = SlipInk.tryParse(tinyPng)!;
      expect(SlipInk.fromDataUrl(ink.toDataUrl()), ink);
      expect(SlipInk.fromDataUrl(''), isNull);
      expect(SlipInk.fromDataUrl('data:image/jpeg;base64,${ink.toDataUrl().split(',').last}'), isNull);
      expect(SlipInk.fromDataUrl('data:image/png;base64,%%%'), isNull);
    });

    test('tells drawings apart by their bytes', () {
      expect(testInk(1), testInk(1));
      expect(testInk(1), isNot(testInk(2)));
      expect(testInk(1).tag, isNot(testInk(2).tag));
    });
  });

  group('a handwritten room', () {
    test('is off by default', () {
      expect(
        const Room(code: 'A', category: GameCategory.custom('x'), namesPerPlayer: 1, hostName: 'M').handwritten,
        isFalse,
      );
    });

    test('takes one drawing per name, and a missing drawing is a missing name', () {
      expect(room.validate(name: 'Omar', inks: [testInk(1), testInk(2)]), isNull);
      expect(room.validate(name: 'Omar', inks: [testInk(1), null]), SubmissionError.missingSecret);
      expect(room.validate(name: 'Omar', inks: [testInk(1)]), SubmissionError.missingSecret);
      expect(room.validate(name: 'Omar', secrets: ['Messi', 'Salah']), SubmissionError.missingSecret);
      expect(room.validate(name: '', inks: [testInk(1), testInk(2)]), SubmissionError.missingName);
    });

    test('never counts two drawings as the same name', () {
      final first = room.withSubmission(playerId: 'a', name: 'Omar', inks: [testInk(1), testInk(1)]);
      expect(first.validate(name: 'Sara', inks: [testInk(1), testInk(1)], playerId: 'b'), isNull);
      final both = first.withSubmission(playerId: 'b', name: 'Sara', inks: [testInk(1), testInk(1)]);
      expect(both.slipCount, 4);
    });

    test('keeps a marker text for each drawing and hands the drawings to the slips', () {
      final next = room
          .withSubmission(playerId: 'a', name: 'Omar', inks: [testInk(1), testInk(2)])
          .withSubmission(playerId: 'b', name: 'Sara', inks: [testInk(3), testInk(4)])
          .withHostSecret('', ink: testInk(5))
          .withHostSecret('', ink: testInk(6));
      expect(next.playerById('a')!.secrets, [SlipInk.marker, SlipInk.marker]);
      expect(next.host!.inks, [testInk(5), testInk(6)]);
      expect(next.slips.map((s) => s.ink), [testInk(1), testInk(2), testInk(3), testInk(4), testInk(5), testInk(6)]);
      expect(next.slips.every((s) => s.text == SlipInk.marker), isTrue);
      expect(next.canStart, isTrue);
      expect(next.nextRound().players.every((p) => p.inks.isEmpty && p.secrets.isEmpty), isTrue);
    });

    test('the host needs a drawing too', () {
      expect(room.validateHostSecret('Messi'), SubmissionError.missingSecret);
      expect(identical(room.withHostSecret('Messi'), room), isTrue);
      expect(room.validateHostSecret('', ink: testInk()), isNull);
    });

    test('a typed room ignores drawings', () {
      const typed = Room(code: 'A', category: GameCategory.custom('x'), namesPerPlayer: 1, hostName: 'M');
      final next = typed.withSubmission(playerId: 'a', name: 'Omar', secrets: ['Messi'], inks: [testInk()]);
      expect(next.slips.single.ink, isNull);
      expect(next.slips.single.text, 'Messi');
    });

    test('the family game gets each slip with its own drawing', () {
      final ready = room
          .withSubmission(playerId: 'a', name: 'Omar', inks: [testInk(1), testInk(2)])
          .withSubmission(playerId: 'b', name: 'Sara', inks: [testInk(3), testInk(4)])
          .withSubmission(playerId: 'c', name: 'Nour', inks: [testInk(5), testInk(6)]);
      final game = Room(
        code: ready.code,
        category: ready.category,
        namesPerPlayer: 2,
        hostName: 'Mafdy',
        handwritten: true,
        mode: GameMode.family,
        players: ready.players,
      ).startFamily(Random(4)).family!;
      final bySlip = {for (final s in ready.slips) s.ink: s.writerId};
      expect(game.slips.map((s) => s.ink).toSet(), bySlip.keys.toSet());
      for (final s in game.slips) {
        expect(s.writerId, bySlip[s.ink], reason: 'the drawing stays with its writer after the shuffle');
      }
    });
  });

  test('passing the phone checks drawings the same way', () {
    var bowl = PassBowl.start(
      category: const GameCategory.preset(PresetCategory.movies),
      namesPerPlayer: 1,
      allowDuplicates: false,
      mode: GameMode.classic,
      teamSetup: const TeamSetup(),
      handwritten: true,
    );
    expect(bowl.validate(name: 'Omar', inks: [null]), PassError.missingSecret);
    bowl = bowl.submit(name: 'Omar', inks: [testInk()]);
    expect(
      bowl.validate(name: 'Sara', inks: [testInk()]),
      isNull,
      reason: 'same drawing, still not a duplicate',
    );
    expect(bowl.slips.single.ink, testInk());
  });
}
