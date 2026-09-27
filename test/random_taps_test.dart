import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

/// Random taps, backs, friends joining and typing, with fixed seeds, failing on
/// any framework error. This is how the blank screens between screens were found.
void main() {
  late FakeNetwork network;
  FakeRoomHost? host;
  setUp(() => network = FakeNetwork(address: '192.168.1.23'));
  tearDown(() => network.dispose());

  for (final motion in [true, false]) {
    for (var seed = 0; seed < 4; seed++) {
      testWidgets('random taps and backs, seed $seed, motion ${motion ? 'on' : 'off'}', (tester) async {
        final rnd = Random(seed);
        tester.view
          ..physicalSize = const Size(360, 800)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          testApp(network: network, createHost: () => host = FakeRoomHost(), reducedMotion: !motion),
        );
        final log = <String>[];
        Future<void> frames(int n) async {
          for (var i = 0; i < n; i++) {
            await tester.pump(const Duration(milliseconds: 30));
            final e = tester.takeException();
            if (e != null) fail('exception: $e\nafter: ${log.skip(max(0, log.length - 12)).join(' | ')}');
          }
        }

        await frames(10);
        var friends = 0;
        for (var step = 0; step < 200; step++) {
          final r = rnd.nextDouble();
          if (r < 0.08) {
            log.add('back');
            await tester.binding.handlePopRoute();
            await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          } else if (r < 0.16 && host != null && !host!.closed) {
            friends++;
            try {
              host!.join('f$friends', 'Friend$friends', ['Name $friends']);
              log.add('join');
            } catch (_) {}
          } else {
            final candidates = find
                .byWidgetPredicate(
                  (w) =>
                      (w is InkWell && w.onTap != null) ||
                      (w is ButtonStyleButton && w.onPressed != null) ||
                      (w is IconButton && w.onPressed != null),
                )
                .hitTestable()
                .evaluate()
                .toList();
            if (candidates.isEmpty) {
              await frames(3);
              continue;
            }
            // Sharing needs the platform plugin, which tests do not have.
            candidates.removeWhere(
              (e) => find
                  .descendant(of: find.byElementPredicate((x) => x == e), matching: find.byIcon(Icons.share_rounded))
                  .evaluate()
                  .isNotEmpty ||
                  find
                  .descendant(of: find.byElementPredicate((x) => x == e), matching: find.byIcon(Icons.ios_share_rounded))
                  .evaluate()
                  .isNotEmpty ||
                  find
                  .descendant(of: find.byElementPredicate((x) => x == e), matching: find.text('Share'))
                  .evaluate()
                  .isNotEmpty,
            );
            if (candidates.isEmpty) {
              await frames(3);
              continue;
            }
            final el = candidates[rnd.nextInt(candidates.length)];
            final label = el.widget is ButtonStyleButton
                ? ((el.widget as ButtonStyleButton).child is Text
                      ? ((el.widget as ButtonStyleButton).child as Text).data
                      : el.widget.runtimeType.toString())
                : (el.widget is IconButton ? (el.widget as IconButton).tooltip : 'inkwell');
            log.add('tap $label');
            final box = el.renderObject! as RenderBox;
            await tester.tapAt(box.localToGlobal(box.size.center(Offset.zero)));
          }
          // Random short or long pauses: sometimes mid-transition.
          await frames(rnd.nextInt(3) == 0 ? 1 : 1 + rnd.nextInt(15));
          // Occasionally type into a visible field.
          final fields = find.byType(EditableText).hitTestable();
          if (fields.evaluate().isNotEmpty && rnd.nextDouble() < 0.3) {
            await tester.enterText(fields.first, 'Text ${rnd.nextInt(99)}');
            log.add('type');
            if (rnd.nextBool()) await tester.testTextInput.receiveAction(TextInputAction.done);
            await frames(2);
          }
        }
      });
    }
  }
}
