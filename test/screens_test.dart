import 'package:family_game/core/router/app_router.dart';
import 'package:family_game/core/theme/app_theme.dart';
import 'package:family_game/features/room/domain/network_access.dart';
import 'package:family_game/features/room/domain/room_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Every screen at phone portrait and landscape, in both text directions.
/// Layout overflow fails a widget test, so these also guard against clipping.
void main() {
  const sizes = {'portrait': Size(360, 800), 'landscape': Size(800, 360)};
  const directions = [TextDirection.ltr, TextDirection.rtl];

  late FakeNetwork network;
  late FakeRoomHost host;

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    required TextDirection direction,
    bool dark = false,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NetworkAccess>.value(value: network),
          RepositoryProvider<RoomHostFactory>.value(value: () => host = FakeRoomHost()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          // Reduced motion also stops the looping animations, so pumpAndSettle can settle.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Directionality(textDirection: direction, child: child!),
          ),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() => network = FakeNetwork(address: '192.168.1.23'));
  tearDown(() => network.dispose());

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final direction in directions) {
      testWidgets('whole game flow fits: $sizeName, ${direction.name}', (tester) async {
        await pumpApp(tester, size: size, direction: direction);

        // Home
        expect(find.text('Who wrote\nwhat?'), findsOneWidget);
        await tapVisible(tester, find.text('Host a room'));

        // New room
        expect(find.text('New room'), findsOneWidget);
        await tapVisible(tester, find.text('Movies'));
        await tapVisible(tester, find.byTooltip('More names'));
        expect(find.text('Connected'), findsOneWidget);
        await tapVisible(tester, find.text('Open room'));

        // Lobby
        expect(find.textContaining('Room open'), findsOneWidget);
        expect(find.text('http://192.168.1.23:8182'.replaceFirst('http://', '')), findsOneWidget);
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Start reading')).onPressed, isNull);
        host
          ..join('a', 'Omar', ['Lionel Messi', 'Adele'])
          ..join('b', 'Nour', ['Fairuz', 'Mr. Bean']);
        await tester.pumpAndSettle();
        expect(find.text('4 in the bowl'), findsOneWidget);
        expect(find.text('Omar'), findsOneWidget);
        expect(find.text('Lionel Messi'), findsNothing, reason: 'the host never sees what friends wrote');

        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Umm Kulthum');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Salah');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('6 in the bowl'), findsOneWidget);
        await tapVisible(tester, find.text('Start reading'));

        // Read aloud, twice through
        expect(find.text('Read aloud'), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          await tapVisible(tester, find.text('Next name'));
        }
        expect(find.text('6 / 6'), findsOneWidget);
        await tapVisible(tester, find.text('Read again'));
        expect(find.text('1 / 6'), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          await tapVisible(tester, find.text('Next name'));
        }
        await tapVisible(tester, find.text('Done reading'));

        // Names on the table
        expect(find.text('Names on the table'), findsOneWidget);
        expect(find.text('Lionel Messi'), findsOneWidget);
        await tapVisible(tester, find.text('Who wrote what?'));

        // Who wrote what
        expect(find.text('Nour'), findsNothing);
        await tapVisible(tester, find.text('Reveal all'));
        await tapVisible(tester, find.text('New round, same room'));

        // Back in the lobby with an empty bowl and the same players
        expect(find.text('0 in the bowl'), findsOneWidget);
        expect(find.text('Omar'), findsOneWidget);
        expect(host.room.round, 2);
      });

      testWidgets('no Wi-Fi: create hotspot, then two codes ($sizeName, ${direction.name})', (tester) async {
        network = FakeNetwork();
        await pumpApp(tester, size: size, direction: direction, dark: true);
        await tapVisible(tester, find.text('Host a room'));
        expect(find.text('No Wi-Fi here'), findsOneWidget);
        await tapVisible(tester, find.text('Open room'));

        expect(find.text('No Wi-Fi around'), findsOneWidget);
        await tapVisible(tester, find.text('Create hotspot'));
        expect(find.text('Join the Wi-Fi'), findsOneWidget);
        expect(find.text('AndroidShare_1234'), findsOneWidget);
        await tapVisible(tester, find.text('Next'));
        expect(find.text('THEN SCAN THIS'), findsOneWidget);
      });
    }
  }

  testWidgets('hotspot failure explains itself and offers Settings', (tester) async {
    network = FakeNetwork(hotspotResult: const HotspotFailed(HotspotFailure.permissionBlocked));
    await pumpApp(tester, size: sizes['portrait']!, direction: TextDirection.ltr);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Open room'));
    await tapVisible(tester, find.text('Create hotspot'));
    expect(find.textContaining('Allow it in Settings'), findsOneWidget);
    await tapVisible(tester, find.text('Open settings'));
    expect(network.settingsCalls, 1);
  });

  testWidgets('closing a room with players asks first', (tester) async {
    await pumpApp(tester, size: sizes['portrait']!, direction: TextDirection.ltr);
    await tapVisible(tester, find.text('Host a room'));
    await tapVisible(tester, find.text('Open room'));
    host.join('a', 'Omar', ['Messi']);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Close room'));
    expect(find.text('Close the room?'), findsOneWidget);
    await tapVisible(tester, find.text('Close room'));
    // The pop callback resumes outside the test's fake clock; let it finish.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('New room'), findsOneWidget);
    expect(host.closed, isTrue);
  });

  testWidgets('animations run without errors when motion is on', (tester) async {
    tester.view
      ..physicalSize = sizes['portrait']!
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NetworkAccess>.value(value: network),
          RepositoryProvider<RoomHostFactory>.value(value: () => host = FakeRoomHost()),
        ],
        child: MaterialApp(theme: AppTheme.light(), onGenerateRoute: AppRoutes.onGenerateRoute),
      ),
    );
    // Looping animations never settle, so step frames instead of pumpAndSettle.
    Future<void> frames([int count = 40]) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> tapAndRun(String text) async {
      await tester.tap(find.text(text));
      await frames();
    }

    await frames();
    await tapAndRun('Host a room');
    await tapAndRun('Open room');
    host
      ..join('a', 'Omar', ['Messi'])
      ..join('b', 'Nour', ['Fairuz'])
      ..join('c', 'Yara', ['Adele']);
    await frames();
    expect(find.text('3 in the bowl'), findsOneWidget);
    await tapAndRun('Start reading');
    await tapAndRun('Next name');
    await tapAndRun('Next name');
    await tapAndRun('Done reading');
    await tapAndRun('Who wrote what?');
    await tapAndRun('Reveal all');
    expect(find.text('New round, same room'), findsOneWidget);
    await tapAndRun('New round, same room');
    expect(find.text('0 in the bowl'), findsOneWidget);
  });
}
