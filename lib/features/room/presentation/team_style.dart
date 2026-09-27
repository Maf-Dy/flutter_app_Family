import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/game_colors.dart';

/// Teams wear the first player colours: purple, orange, green, pink.
Color teamColor(BuildContext context, int team) => context.gameColors.player(team);

String teamName(AppLocalizations l10n, int team) =>
    [l10n.teamName0, l10n.teamName1, l10n.teamName2, l10n.teamName3][team % 4];
