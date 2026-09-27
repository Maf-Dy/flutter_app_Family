import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/game_colors.dart';
import '../../../round/round_route.dart';
import '../../domain/room.dart';
import '../state/room_cubit.dart';
import '../widgets/arrival_banner.dart';
import '../widgets/bowl_count.dart';
import '../widgets/host_secret_field.dart';
import '../widgets/join_codes.dart';
import '../widgets/link_help_sheet.dart';
import '../widgets/no_network_card.dart';
import '../widgets/players_list.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoomCubit>().state;
    final cubit = context.read<RoomCubit>();
    final room = state.room;
    if (room == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return BlocListener<RoomCubit, RoomState>(
      listenWhen: (previous, current) => (current.room?.slipCount ?? 0) > (previous.room?.slipCount ?? 0),
      listener: (_, _) => Haptics.nameIn(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close room',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(room.category),
        ),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final connection = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _LiveChip(connection: state.connection, playersIn: room.playersIn.length),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: Motion.of(context, Motion.standard),
                        child: KeyedSubtree(
                          key: ValueKey(state.connection.runtimeType),
                          child: _connectionSection(context, state, room),
                        ),
                      ),
                    ],
                  );
                  final bowl = _BowlSection(room: room, onHostSecret: cubit.addHostSecret);
                  const padding = EdgeInsets.fromLTRB(16, 0, 16, 24);
                  // Landscape and tablets: codes beside the bowl, each side scrolls on its own.
                  if (constraints.maxWidth >= 640) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(padding: padding, child: connection),
                        ),
                        Expanded(
                          child: SingleChildScrollView(padding: padding, child: bowl),
                        ),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [connection, const SizedBox(height: 16), bowl],
                    ),
                  );
                },
              ),
            ),
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 0), child: ArrivalBanners()),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _StartButton(onPressed: room.canStart ? () => _startReading(context) : null),
          ),
        ),
      ),
    );
  }

  Widget _connectionSection(BuildContext context, RoomState state, Room room) {
    final cubit = context.read<RoomCubit>();
    final url = state.joinUrl;
    final theme = Theme.of(context);
    Widget note(String text, {bool error = false}) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: error ? theme.colorScheme.errorContainer.withValues(alpha: 0.6) : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: error ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final brokenLink = state.linkCheck == LinkCheck.broken
        ? note(
            'This phone couldn\'t open its own link, so friends won\'t either. Tap Check again, or use a hotspot.',
            error: true,
          )
        : null;

    return switch (state.connection) {
      ConnectionChecking() => const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      ConnectionStartingHotspot() => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(children: [CircularProgressIndicator(), SizedBox(height: 14), Text('Starting hotspot…')]),
        ),
      ),
      ConnectionReady(:final hotspotFailure) when url != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JoinCard(url: url, code: room.code),
          ?brokenLink,
          if (hotspotFailure != null) note(hotspotFailureText(hotspotFailure), error: true),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              if (brokenLink != null) TextButton(onPressed: cubit.refreshConnection, child: const Text('Check again')),
              TextButton(
                onPressed: () => showLinkHelp(context, url: url, onUseHotspot: cubit.createHotspot),
                child: const Text('Link not opening?'),
              ),
            ],
          ),
        ],
      ),
      ConnectionAppHotspot(:final credentials, :final wifiAvailable) when url != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wifiAvailable) ...[
            note('You\'re on Wi-Fi now. Friends on the hotspot stay connected until you switch.'),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: cubit.switchToWifi, child: const Text('Switch to Wi-Fi')),
            ),
          ],
          HotspotCodes(credentials: credentials, url: url, code: room.code),
          ?brokenLink,
        ],
      ),
      final ConnectionMissing missing => NoNetworkCard(
        connection: missing,
        onCreateHotspot: cubit.createHotspot,
        onCheckAgain: cubit.refreshConnection,
        onOpenSettings: cubit.openPermissionSettings,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _startReading(BuildContext context) async {
    final cubit = context.read<RoomCubit>();
    final room = cubit.state.room;
    final slips = cubit.startReading();
    if (room == null || slips == null) return;
    unawaited(Haptics.start());
    final exit = await Navigator.of(context).pushNamed<RoundExit>(
      AppRoutes.round,
      arguments: RoundArgs(category: room.category, slips: slips, players: [for (final p in room.players) p.id]),
    );
    if (!context.mounted) return;
    switch (exit) {
      case RoundExit.newRound:
        cubit.nextRound();
      case RoundExit.endGame:
        Navigator.of(context).pop();
      case null:
        cubit.reopen();
    }
  }
}

/// "Start reading", which pulses twice the moment the room becomes ready.
class _StartButton extends StatefulWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didUpdateWidget(_StartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameReady = oldWidget.onPressed == null && widget.onPressed != null;
    if (becameReady && !Motion.isReduced(context)) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) =>
          Transform.scale(scale: 1 + 0.05 * math.sin(_pulse.value * math.pi * 2).abs(), child: child),
      child: FilledButton(onPressed: widget.onPressed, child: const Text('Start reading')),
    );
  }
}

class _BowlSection extends StatelessWidget {
  const _BowlSection({required this.room, required this.onHostSecret});

  final Room room;
  final ValueChanged<String> onHostSecret;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BowlCount(count: room.slipCount, ready: room.canStart),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.standard),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(parent: animation, curve: Motion.spring),
                      child: child,
                    ),
                    child: Text(
                      '${room.slipCount} in the bowl',
                      key: ValueKey(room.slipCount),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    room.canStart
                        ? 'Ready when you are'
                        : '${room.playersNeeded} more ${room.playersNeeded == 1 ? 'player' : 'players'} to start',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PlayersList(room: room),
        if (room.hostSecretsLeft > 0 && room.isCollecting) ...[
          const SizedBox(height: 14),
          HostSecretField(
            label: room.namesPerPlayer == 1
                ? 'Your secret name'
                : 'Your secret name (${room.namesPerPlayer - room.hostSecretsLeft + 1} of ${room.namesPerPlayer})',
            onSubmit: onHostSecret,
          ),
        ],
      ],
    );
  }
}

class _LiveChip extends StatefulWidget {
  const _LiveChip({required this.connection, required this.playersIn});

  final Connection connection;
  final int playersIn;

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _live => widget.connection is ConnectionReady || widget.connection is ConnectionAppHotspot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_LiveChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (_live && !Motion.isReduced(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = context.gameColors;
    final fg = _live ? game.live : theme.colorScheme.onSurfaceVariant;
    final label = switch (widget.connection) {
      ConnectionReady() => 'Room open',
      ConnectionAppHotspot() => 'Hotspot on',
      ConnectionStartingHotspot() => 'Starting hotspot',
      _ => 'Waiting for a network',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _live ? game.liveContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.3).animate(_pulse),
            child: CircleAvatar(radius: 3.5, backgroundColor: fg),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label · ${widget.playersIn} in',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
