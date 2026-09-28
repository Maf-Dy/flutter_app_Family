import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/bowl.dart';
import '../../domain/join_code.dart';
import '../../domain/network_access.dart';
import '../../domain/room.dart';
import '../../domain/room_beacon.dart';
import '../category_label.dart';
import '../state/nearby_rooms_cubit.dart';
import '../widgets/section_label.dart';
import 'scan_screen.dart';

/// "Join a game": scan the host's code with the camera, or pick a room heard
/// on this Wi-Fi. Either way the room opens in the browser, the same page the
/// host's QR code opens.
class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NearbyRoomsCubit(context.read<RoomFinder>()),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.joinGame)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BlocBuilder<NearbyRoomsCubit, NearbyRoomsState>(
                builder: (context, state) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    const _ScanCard(),
                    const SizedBox(height: 24),
                    SectionLabel(context.l10n.gamesOnThisWifi),
                    const SizedBox(height: 8),
                    ...switch (state) {
                      NearbyRoomsState(failed: true) => [_Message(text: context.l10n.cannotLookForGames)],
                      NearbyRoomsState(rooms: []) => [const _Searching()],
                      NearbyRoomsState(:final rooms) => [
                        for (final room in rooms) ...[_RoomTile(room: room), const SizedBox(height: 10)],
                        const SizedBox(height: 6),
                        _Help(text: context.l10n.lookingForGamesHelp),
                      ],
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _scan(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.qr_code_scanner_rounded, color: scheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.scanHostCode,
                      style: theme.textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.scanHostCodeDetail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final openLink = context.read<OpenRoomLink>();
    final raw = await context.read<ScanJoinCode>()(context);
    if (raw == null || !context.mounted) return;
    switch (JoinCode.parse(raw)) {
      case GameLink(:final url):
        if (!await openLink(url)) messenger.showSnackBar(SnackBar(content: Text(l10n.cannotOpenRoom(url.toString()))));
      case WifiCode(:final credentials):
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _WifiSheet(credentials: credentials),
        );
      case NotAGameCode():
        messenger.showSnackBar(SnackBar(content: Text(l10n.notAGameCode)));
    }
  }
}

/// The host is on their own hotspot: join it first, then scan the game code.
class _WifiSheet extends StatelessWidget {
  const _WifiSheet({required this.credentials});

  final HotspotCredentials credentials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.wifiCodeTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(l10n.wifiCodeDetail(credentials.ssid), style: theme.textTheme.bodyMedium),
            if (credentials.password.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      credentials.password,
                      style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: credentials.password));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordCopied)));
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.copyPassword),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await context.read<OpenWifiSettings>()();
              },
              child: Text(l10n.openWifiSettings),
            ),
          ],
        ),
      ),
    );
  }
}

/// While no room has turned up: the bowl gets a good shake, and the app says
/// silly things about where it is looking.
class _Searching extends StatefulWidget {
  const _Searching();

  @override
  State<_Searching> createState() => _SearchingState();
}

class _SearchingState extends State<_Searching> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: Motion.shuffle);
  Timer? _jokes;
  int _joke = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.isReduced(context)) {
      _shake.stop();
      _jokes?.cancel();
      _jokes = null;
    } else {
      if (!_shake.isAnimating) _shake.repeat();
      _jokes ??= Timer.periodic(const Duration(milliseconds: 2600), (_) => setState(() => _joke++));
    }
  }

  @override
  void dispose() {
    _jokes?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jokes = searchingJokes(context.l10n);
    final joke = jokes[_joke % jokes.length];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shake,
            // A shake, a pause, a shake: like someone stirring the names.
            builder: (context, child) {
              final t = _shake.value;
              final wiggle = t < 0.45 ? math.sin(t / 0.45 * math.pi * 4) * (1 - t / 0.45) : 0.0;
              return Transform.rotate(angle: wiggle * 0.14, child: child);
            },
            child: const Bowl(width: 150),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.standard),
              transitionBuilder: Motion.fadeSwitch,
              child: Text(joke, key: ValueKey(joke), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 8),
          _Help(text: context.l10n.lookingForGamesHelp),
        ],
      ),
    );
  }
}

/// What the app says while it waits, first line first.
List<String> searchingJokes(AppLocalizations l10n) => [
  l10n.lookingForGames,
  l10n.searchingJoke1,
  l10n.searchingJoke2,
  l10n.searchingJoke3,
  l10n.searchingJoke4,
];

class _Help extends StatelessWidget {
  const _Help({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.tertiary),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final NearbyRoom room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final a = room.announcement;
    final mode = switch (a.mode) {
      GameMode.classic => l10n.modeClassic,
      GameMode.celebrity => l10n.modeCelebrity,
      GameMode.family => l10n.modeFamily,
    };
    final status = a.open ? l10n.nearbyRoomPlayers(a.players) : l10n.nearbyRoomPlaying;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nearbyRoomTitle(a.hostName), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${categoryLabel(l10n, a.category)} · $mode',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${l10n.roomCodeLabel(a.code)} · $status',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _open(context), child: Text(l10n.joinRoomButton)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.cannotOpenRoom(room.joinUrl.toString());
    final opened = await context.read<OpenRoomLink>()(room.joinUrl);
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
