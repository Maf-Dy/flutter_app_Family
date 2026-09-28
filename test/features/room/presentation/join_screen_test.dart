import 'package:family_game/features/room/domain/room.dart';
import 'package:family_game/features/room/domain/room_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/harness.dart';

void main() {
  late FakeNetwork network;
  late FakeRoomFinder finder;

  setUp(() {
    network = FakeNetwork(address: '192.168.1.23', onWifi: true);
    finder = FakeRoomFinder();
  });

  tearDown(() async {
    await network.dispose();
    await finder.dispose();
  });

  const room = NearbyRoom(
    '192.168.1.40',
    RoomAnnouncement(
      code: 'K7QX',
      hostName: 'Nour',
      port: 8182,
      mode: GameMode.family,
      category: GameCategory.preset(PresetCategory.movies),
      players: 3,
      open: true,
    ),
  );

  Future<void> openJoin(
    WidgetTester tester, {
    OpenRoomLinkFake? opener,
    Locale locale = const Locale('en'),
    String? scanned,
    Future<void> Function()? openWifiSettings,
    bool reducedMotion = true,
  }) async {
    await tester.pumpWidget(
      testApp(
        network: network,
        createHost: FakeRoomHost.new,
        finder: finder,
        openRoomLink: opener?.call,
        scan: (_) async => scanned,
        openWifiSettings: openWifiSettings,
        locale: locale,
        reducedMotion: reducedMotion,
      ),
    );
    // With motion on, the home bowl bobs forever, so there is nothing to settle.
    reducedMotion ? await tester.pumpAndSettle() : await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(locale.languageCode == 'ar' ? 'ادخل لعبة' : 'Join a game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('finds a room on the Wi-Fi and opens it in the browser', (tester) async {
    final opener = OpenRoomLinkFake(true);
    await openJoin(tester, opener: opener);
    expect(find.text('Looking for games on this Wi-Fi…'), findsOneWidget);

    finder.controller.add([room]);
    await tester.pump();
    expect(find.text("Nour's room"), findsOneWidget);
    expect(find.textContaining('3 players in'), findsOneWidget);
    expect(find.textContaining('Family online'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    await tester.pump();
    expect(opener.opened, [Uri.parse('http://192.168.1.40:8182/')]);
  });

  testWidgets('a room already playing says so, and a room that goes away leaves the list', (tester) async {
    await openJoin(tester);
    finder.controller.add([
      const NearbyRoom(
        '192.168.1.41',
        RoomAnnouncement(
          code: 'AB23',
          hostName: 'Omar',
          port: 8182,
          mode: GameMode.classic,
          category: GameCategory.custom('Teachers'),
          players: 5,
          open: false,
        ),
      ),
    ]);
    await tester.pump();
    expect(find.textContaining('Already playing'), findsOneWidget);

    finder.controller.add([]);
    await tester.pumpAndSettle();
    expect(find.text("Omar's room"), findsNothing);
    expect(find.text('Looking for games on this Wi-Fi…'), findsOneWidget);
  });

  testWidgets('a browser that will not open shows the link to type', (tester) async {
    await openJoin(tester, opener: OpenRoomLinkFake(false));
    finder.controller.add([room]);
    await tester.pump();
    await tester.tap(find.text("Nour's room"));
    await tester.pump();
    expect(find.textContaining('http://192.168.1.40:8182/'), findsOneWidget);
  });

  testWidgets('a phone that cannot listen explains the QR code instead', (tester) async {
    await openJoin(tester);
    finder.controller.addError(Exception('port in use'));
    await tester.pump();
    expect(find.textContaining("Scan the host's QR code"), findsOneWidget);
  });

  testWidgets('speaks Egyptian Arabic', (tester) async {
    await openJoin(tester, locale: const Locale('ar'));
    finder.controller.add([room]);
    await tester.pump();
    expect(find.text('قعدة Nour'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('scanning the host\'s code', () {
    testWidgets('the game code opens the room', (tester) async {
      final opener = OpenRoomLinkFake(true);
      await openJoin(tester, opener: opener, scanned: 'http://192.168.49.1:8182');
      await tester.tap(find.text("Scan the host's code"));
      await tester.pumpAndSettle();
      expect(opener.opened, [Uri.parse('http://192.168.49.1:8182')]);
    });

    testWidgets('the Wi-Fi code explains what to do and opens Wi-Fi settings', (tester) async {
      var settings = 0;
      await openJoin(
        tester,
        scanned: 'WIFI:T:WPA;S:AndroidShare_1234;P:secret12;;',
        openWifiSettings: () async => settings++,
      );
      await tester.tap(find.text("Scan the host's code"));
      await tester.pumpAndSettle();
      expect(find.text("That's the host's Wi-Fi"), findsOneWidget);
      expect(find.textContaining('AndroidShare_1234'), findsOneWidget);
      expect(find.text('secret12'), findsOneWidget);

      await tester.tap(find.text('Open Wi-Fi settings'));
      await tester.pumpAndSettle();
      expect(settings, 1);
      expect(find.text("That's the host's Wi-Fi"), findsNothing);
    });

    testWidgets('any other code says it is not a game code', (tester) async {
      final opener = OpenRoomLinkFake(true);
      await openJoin(tester, opener: opener, scanned: 'https://example.com');
      await tester.tap(find.text("Scan the host's code"));
      await tester.pumpAndSettle();
      expect(find.textContaining("That's not a game code"), findsOneWidget);
      expect(opener.opened, isEmpty);
    });

    testWidgets('backing out of the camera does nothing', (tester) async {
      final opener = OpenRoomLinkFake(true);
      await openJoin(tester, opener: opener);
      await tester.tap(find.text("Scan the host's code"));
      await tester.pumpAndSettle();
      expect(opener.opened, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  testWidgets('while it looks, the bowl shakes and the jokes change', (tester) async {
    await openJoin(tester, reducedMotion: false);
    expect(find.text('Looking for games on this Wi-Fi…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Looking for games on this Wi-Fi…'), findsNothing);
    expect(find.text('Shaking the bowl to see who falls out…'), findsOneWidget);

    // A room turns up: the jokes stop, and nothing is left ticking.
    finder.controller.add([room]);
    await tester.pump();
    await tester.pump();
    expect(find.text("Nour's room"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class OpenRoomLinkFake {
  OpenRoomLinkFake(this.result);

  final bool result;
  final opened = <Uri>[];

  Future<bool> call(Uri url) async {
    opened.add(url);
    return result;
  }
}
