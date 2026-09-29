import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/audio/game_sounds.dart';
import '../../../../core/platform/haptics.dart';
import '../../../../core/router/game_exit.dart';
import '../../../../core/widgets/keep_screen_on.dart';
import '../../../../core/widgets/share_card.dart';
import '../../../room/presentation/category_label.dart';
import '../../../round/presentation/widgets/confetti.dart';
import '../../../../core/theme/game_colors.dart';
import '../../domain/family_game.dart';
import '../../domain/night_awards.dart';
import '../../family_route.dart';
import '../family_style.dart';
import '../state/family_cubit.dart';
import '../widgets/ask_card.dart';
import '../widgets/family_board.dart';
import '../widgets/family_chat.dart';
import '../widgets/ideas_card.dart';
import '../widgets/night_awards_card.dart';
import '../widgets/table_notices.dart';
import '../widgets/turn_banner.dart';
import '../widgets/twist_cards.dart';

/// The host's seat in a family game that friends play in their browsers.
/// Pops with a [GameExit] once there's a winner, or null to go back to the lobby.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.args});

  final FamilyArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FamilyCubit(table: args.table, game: args.table.game!, me: args.me),
      child: KeepScreenOn(child: _FamilyView(args: args)),
    );
  }
}

class _FamilyView extends StatefulWidget {
  const _FamilyView({required this.args});

  final FamilyArgs args;

  @override
  State<_FamilyView> createState() => _FamilyViewState();
}

class _FamilyViewState extends State<_FamilyView> {
  String? _target;
  int? _slip;
  final _name = TextEditingController();
  String? _pickError;

  /// The host's side and the board: both jump back to the top when someone wins.
  final _seat = ScrollController();
  final _board = ScrollController();

  /// The host leaving the app counts as stepping away: their family asks for them meanwhile.
  late final _lifecycle = AppLifecycleListener(
    onHide: () => context.read<FamilyCubit>().setAway(true),
    onShow: () => context.read<FamilyCubit>().setAway(false),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _name.dispose();
    _seat.dispose();
    _board.dispose();
    super.dispose();
  }

  void _showWinner() {
    final duration = Motion.of(context, Motion.standard);
    for (final controller in [_seat, _board]) {
      if (!controller.hasClients) continue;
      if (duration == Duration.zero) {
        controller.jumpTo(0);
      } else {
        unawaited(controller.animateTo(0, duration: duration, curve: Curves.easeOut));
      }
    }
  }

  void _showError(FamilyActionError error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(familyErrorText(context.l10n, error)), duration: const Duration(seconds: 3)),
      );
  }

  void _submit({required bool ask}) {
    final cubit = context.read<FamilyCubit>();
    final game = cubit.state;
    final head = cubit.myHead ?? '';
    final target = _target;
    // The picker drops people a friend's move took off the table, so check what it still shows.
    if (target == null || !game.askableFor(head).any((p) => p.id == target)) {
      setState(() => _pickError = context.l10n.familyPickBoth);
      return;
    }
    final slip = game.handwritten ? _slip : game.slipNamed(_name.text, head: head, targetId: target);
    if (slip == null) {
      setState(
        () => _pickError = game.handwritten || _name.text.trim().isEmpty
            ? context.l10n.familyPickBoth
            : context.l10n.familyErrorUnknownName,
      );
      return;
    }
    final error = ask ? cubit.guess(target, slip) : cubit.suggest(target, slip);
    if (error != null) return _showError(error);
    _name.clear();
    setState(() {
      _target = null;
      _slip = null;
      _pickError = null;
    });
  }

  void _report(FamilyActionError? error) {
    if (error != null) _showError(error);
  }

  Future<void> _spreadRumor(FamilyGame game, String me) async {
    final picked = await showDialog<(String, int)>(
      context: context,
      builder: (_) => RumorDialog(game: game, me: me),
    );
    if (picked == null || !mounted) return;
    _report(context.read<FamilyCubit>().spreadRumor(picked.$1, picked.$2));
  }

  void _share(FamilyGame game) {
    final l10n = context.l10n;
    final colors = FamilyColors(widget.args.joinOrder, game);
    const shown = 8;
    final ink = context.gameColors.slipInk;
    // The awards and the family tree are the fun part to post; the names follow if there's room.
    final awards = nightAwards(game);
    final names = (shown - awards.length).clamp(0, shown);
    showShareCard(
      context,
      ShareCard(
        title: _headline(l10n, game),
        subtitle: categoryLabel(l10n, widget.args.category),
        rows: [
          for (final award in awards)
            (
              label: awardTitle(l10n, award.kind),
              value: game.nameOf(award.playerId),
              color: colors.of(context, award.playerId),
            ),
          for (final slip in game.slips.take(names))
            (label: slip.text, value: game.nameOf(slip.writerId), color: colors.of(context, slip.writerId)),
        ],
        more: game.slips.length - names,
        extra: Container(
          margin: const EdgeInsets.only(top: 6, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.gameColors.slipPaper, borderRadius: BorderRadius.circular(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.familyTreeTitle,
                style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              FamilyTreeView(game: game, colorOf: (id) => colors.of(context, id), ink: ink),
            ],
          ),
        ),
      ),
    );
  }

  String _headline(AppLocalizations l10n, FamilyGame game) {
    final winner = game.winner;
    if (winner == null) return '';
    final myHead = context.read<FamilyCubit>().myHead;
    return winner == myHead ? l10n.familyYouWon : l10n.familyWon(game.nameOf(winner));
  }

  void _showJoinCodes() {
    final builder = widget.args.joinCodes;
    if (builder == null) return;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.familyShowCode, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(context.l10n.familyShowCodeHelp),
                const SizedBox(height: 12),
                builder(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveGameTitle),
        content: Text(l10n.familyLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.stay)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.leave)),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FamilyCubit>();
    final game = context.watch<FamilyCubit>().state;
    final l10n = context.l10n;
    final me = cubit.isPlaying ? cubit.me : null;
    final myHead = cubit.myHead;
    final over = game.isOver;
    final canAsk = me != null && game.canAsk(me);
    final colors = FamilyColors(widget.args.joinOrder, game);

    final play = <Widget>[
      if (!over)
        for (final claim in game.pendingClaims) ...[
          ClaimCard(
            game: game,
            claim: claim,
            onResolve: ({required approve}) => cubit.resolveClaim(claim.clientId, approve: approve),
          ),
          const SizedBox(height: 10),
        ],
      TurnBanner(game: game, me: me),
      if (over) ...[const SizedBox(height: 10), NightAwardsCard(game: game, colorOf: (id) => colors.of(context, id))],
      if (!over && game.turnStalled) AwayTurnCard(onSkip: cubit.skipTurn),
      if (!over && game.pending != null) ...[
        const SizedBox(height: 10),
        PendingCard(
          game: game,
          me: me,
          onLetMeGo: ({required use}) => _report(cubit.answerLetMeGo(use: use)),
        ),
      ],
      if (me == null) ...[
        const SizedBox(height: 10),
        Text(
          l10n.familyWatching,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
      if (me != null && myHead != null) ...[
        const SizedBox(height: 14),
        Text(
          me == myHead ? l10n.yourFamily : l10n.familyOf(game.nameOf(myHead)),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FamilyMembers(game: game, head: myHead, colors: colors, me: me),
        if (!over && game.twists.letMeGo) ...[const SizedBox(height: 6), LetMeGoChip(game: game, me: me)],
        if (!over) ...[
          const SizedBox(height: 14),
          AskCard(
            game: game,
            myHead: myHead,
            me: me,
            canAsk: canAsk,
            target: _target,
            slip: _slip,
            name: _name,
            error: _pickError,
            onTarget: (id) => setState(() {
              _target = id;
              _pickError = null;
            }),
            onSlip: (id) => setState(() {
              _slip = id;
              _pickError = null;
            }),
            onSubmit: () => _submit(ask: canAsk),
          ),
          const SizedBox(height: 10),
          IdeasCard(
            game: game,
            me: me,
            myHead: myHead,
            canAsk: canAsk,
            onBack: (idea) {
              final error = cubit.suggest(idea.targetId, idea.slipId);
              if (error != null) _showError(error);
            },
            onUnback: cubit.unvote,
            onUse: (idea) => setState(() {
              _target = idea.targetId;
              _slip = idea.slipId;
              _name.text = game.slip(idea.slipId)?.text ?? '';
              _pickError = null;
            }),
          ),
        ],
        if (!over && game.twists.rumors) ...[
          const SizedBox(height: 10),
          RumorsCard(game: game, me: me, onSpread: () => _spreadRumor(game, me)),
        ],
        if (game.chatEnabled) ...[
          const SizedBox(height: 10),
          FamilyChat(
            game: game,
            me: me,
            myHead: myHead,
            onSend: (text) {
              final error = cubit.say(text);
              if (error != null) _showError(error);
              return error == null;
            },
          ),
        ],
      ],
    ];
    final board = FamilyBoard(game: game, colors: colors, me: me);

    return MultiBlocListener(
      listeners: [
        BlocListener<FamilyCubit, FamilyGame>(
          listenWhen: (previous, current) =>
              myHead != null &&
              !current.isOver &&
              (current.secret ? current.turnPlayer == me : current.turn == current.headOf(me!)) &&
              (previous.turn != current.turn || previous.turnPlayer != current.turnPlayer),
          listener: (_, _) => unawaited(Haptics.yourTurn()),
        ),
        // The table hears the host's phone: a drumroll while someone decides, a zaghrouta when a family
        // grows, a sad trombone for a miss. With secret catches it only sounds for what the host may see.
        BlocListener<FamilyCubit, FamilyGame>(
          listenWhen: (previous, current) =>
              current.pending != null &&
              previous.pending == null &&
              (!current.secret || me == null || current.headOf(current.pending!.askerId) == current.headOf(me)),
          listener: (context, _) => unawaited(context.read<GameSounds>().drumroll()),
        ),
        BlocListener<FamilyCubit, FamilyGame>(
          listenWhen: (previous, current) =>
              current.events.length > previous.events.length &&
              !current.events.last.blocked &&
              (!current.secret || (me != null && current.seesEvent(me, current.events.last))),
          listener: (context, game) {
            final sounds = context.read<GameSounds>();
            unawaited(game.events.last.correct ? sounds.joy() : sounds.wrong());
          },
        ),
        BlocListener<FamilyCubit, FamilyGame>(
          listenWhen: (previous, current) => current.isOver && !previous.isOver,
          listener: (_, _) => _showWinner(),
        ),
        BlocListener<FamilyCubit, FamilyGame>(
          listenWhen: (previous, current) => current.rumors.length > previous.rumors.length,
          listener: (context, game) {
            final rumor = game.rumors.last;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.rumorLine(game.nameOf(rumor.targetId), game.slip(rumor.slipId)?.text ?? ''),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
          },
        ),
      ],
      child: PopScope<Object?>(
        canPop: over,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !over,
            title: Text(categoryLabel(l10n, widget.args.category)),
            actions: [
              if (!over && widget.args.joinCodes != null)
                IconButton(
                  tooltip: l10n.familyShowCode,
                  onPressed: _showJoinCodes,
                  icon: const Icon(Icons.qr_code_2_rounded),
                ),
              if (over)
                IconButton(
                  tooltip: l10n.shareThisNight,
                  onPressed: () => _share(game),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // A plain column, not a lazy list, so a half-typed chat message survives scrolling.
                    Widget column(ScrollController controller, List<Widget> children) => SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                    );
                    // Landscape and tablets: the host's seat beside the board, each scrolling on its own.
                    if (constraints.maxWidth >= 640) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: column(_seat, play)),
                          Expanded(child: column(_board, [board])),
                        ],
                      );
                    }
                    return column(_seat, [...play, const SizedBox(height: 10), board]);
                  },
                ),
              ),
              Positioned.fill(child: ConfettiBurst(fire: over)),
            ],
          ),
          bottomNavigationBar: over
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(GameExit.newRound),
                          child: Text(l10n.newRoundSameRoom),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(GameExit.endGame),
                          child: Text(l10n.endGame),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
