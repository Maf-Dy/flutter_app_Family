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
import '../../../../core/l10n/l10n.dart';
import '../category_label.dart';
import '../../../../core/router/game_exit.dart';
import '../../../celebrity/celebrity_route.dart';
import '../../../family/family_route.dart';

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
            tooltip: context.l10n.closeRoom,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(categoryLabel(context.l10n, room.category)),
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
                        transitionBuilder: Motion.fadeSwitch,
                        child: KeyedSubtree(
                          key: ValueKey(state.connection.runtimeType),
                          child: _connectionSection(context, state, room),
                        ),
                      ),
                    ],
                  );
                  final bowl = _BowlSection(
                    room: room,
                    onHostSecret: (secret) {
                      final error = cubit.addHostSecret(secret);
                      if (error == SubmissionError.duplicate) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.duplicateHostSecret),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                      }
                      return error == null;
                    },
                  );
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
            child: _StartButton(
              label: room.mode == GameMode.classic ? context.l10n.startReading : context.l10n.letsPlay,
              onPressed: room.canStart ? () => _startReading(context) : null,
            ),
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
    final brokenLink = state.linkCheck == LinkCheck.broken ? note(context.l10n.linkBroken, error: true) : null;

    return switch (state.connection) {
      ConnectionChecking() => const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      ConnectionStartingHotspot() => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(context.l10n.startingHotspot),
            ],
          ),
        ),
      ),
      ConnectionReady(:final hotspotFailure) when url != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JoinCard(url: url, code: room.code),
          ?brokenLink,
          if (hotspotFailure != null) note(hotspotFailureText(context.l10n, hotspotFailure), error: true),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              if (brokenLink != null)
                TextButton(onPressed: cubit.refreshConnection, child: Text(context.l10n.checkAgain)),
              TextButton(
                onPressed: () => showLinkHelp(context, url: url, onUseHotspot: cubit.createHotspot),
                child: Text(context.l10n.linkNotOpening),
              ),
            ],
          ),
        ],
      ),
      ConnectionAppHotspot(:final credentials, :final wifiAvailable) when url != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wifiAvailable) ...[
            note(context.l10n.onWifiNow),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: cubit.switchToWifi, child: Text(context.l10n.switchToWifi)),
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
    if (room == null) return;
    final (String route, Object args)? start = switch (room.mode) {
      GameMode.family => switch (cubit.startFamily()) {
        final table? => (
          AppRoutes.family,
          FamilyArgs(
            category: room.category,
            table: table,
            // The host plays only if their own name went in.
            me: (room.host?.hasSubmitted ?? false) ? Player.hostId : null,
            joinOrder: [for (final p in room.players) p.id],
            joinCodes: (context) => BlocProvider.value(
              value: cubit,
              child: BlocBuilder<RoomCubit, RoomState>(
                builder: (context, state) => switch (state.room) {
                  final room? => _connectionSection(context, state, room),
                  null => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ),
        null => null,
      },
      GameMode.classic => switch (cubit.startReading()) {
        final slips? => (
          AppRoutes.round,
          RoundArgs(category: room.category, slips: slips, players: [for (final p in room.players) p.id]),
        ),
        null => null,
      },
      GameMode.celebrity => switch (cubit.startReading()) {
        final slips? => (
          AppRoutes.celebrity,
          CelebrityArgs(
            category: room.category,
            slips: slips,
            players: [for (final p in room.playersIn) (id: p.id, name: p.name, team: p.team)],
            setup: room.teamSetup,
          ),
        ),
        null => null,
      },
    };
    if (start == null) return;
    unawaited(Haptics.start());
    // A leftover lobby message would cover the game screen's buttons.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final exit = await Navigator.of(context).pushNamed<GameExit>(start.$1, arguments: start.$2);
    if (!context.mounted) return;
    switch (exit) {
      case GameExit.newRound:
        cubit.nextRound();
      case GameExit.endGame:
        Navigator.of(context).pop();
      case null:
        cubit.reopen();
    }
  }
}

/// "Start reading", which pulses twice the moment the room becomes ready.
class _StartButton extends StatefulWidget {
  const _StartButton({required this.label, required this.onPressed});

  final String label;
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
      child: FilledButton(onPressed: widget.onPressed, child: Text(widget.label)),
    );
  }
}

class _BowlSection extends StatelessWidget {
  const _BowlSection({required this.room, required this.onHostSecret});

  final Room room;

  /// Returns whether the name went in.
  final bool Function(String secret) onHostSecret;

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
                      context.l10n.inTheBowl(room.slipCount),
                      key: ValueKey(room.slipCount),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    room.canStart
                        ? context.l10n.readyWhenYouAre
                        : room.playersNeeded > 0
                        ? context.l10n.morePlayersToStart(room.playersNeeded)
                        : context.l10n.teamRaceMoreNames(room.slipsNeeded),
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
        PlayersList(room: room, onRemove: context.read<RoomCubit>().removePlayer),
        if (room.hostSecretsLeft > 0 && room.isCollecting) ...[
          const SizedBox(height: 14),
          HostSecretField(
            label: room.namesPerPlayer == 1
                ? context.l10n.yourSecretName
                : context.l10n.yourSecretNameOf(room.namesPerPlayer - room.hostSecretsLeft + 1, room.namesPerPlayer),
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
      ConnectionReady() => context.l10n.roomOpen,
      ConnectionAppHotspot() => context.l10n.hotspotOn,
      ConnectionStartingHotspot() => context.l10n.startingHotspot,
      _ => context.l10n.waitingForNetwork,
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
              context.l10n.playersInChip(label, widget.playersIn),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
