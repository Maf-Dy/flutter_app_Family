import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/game_colors.dart';
import '../domain/family_game.dart';

/// Why a move was refused, in the host's language.
String familyErrorText(AppLocalizations l10n, FamilyActionError error) => switch (error) {
  FamilyActionError.gameOver => l10n.familyErrorGameOver,
  FamilyActionError.notYourTurn => l10n.familyErrorNotYourTurn,
  FamilyActionError.notHead => l10n.familyErrorNotHead,
  FamilyActionError.invalidTarget => l10n.familyErrorInvalidTarget,
  FamilyActionError.invalidSlip => l10n.familyErrorInvalidSlip,
  FamilyActionError.chatOff => l10n.familyErrorChatOff,
  FamilyActionError.emptyMessage => l10n.familyErrorEmptyMessage,
  FamilyActionError.waiting => l10n.familyErrorWaiting,
  FamilyActionError.notAllowed => l10n.familyErrorNotAllowed,
};

/// Where each player sits in the room's join order, so they keep their lobby colour.
final class FamilyColors {
  const FamilyColors(this.joinOrder, this.game);

  final List<String> joinOrder;
  final FamilyGame game;

  int indexOf(String playerId) {
    final index = joinOrder.indexOf(playerId);
    return index >= 0 ? index : game.players.indexWhere((p) => p.id == playerId);
  }

  Color of(BuildContext context, String playerId) => context.gameColors.player(indexOf(playerId).clamp(0, 999));
}
