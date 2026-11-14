// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/localization_service.dart';
import '../services/player_progression_service.dart';

/// نوار XP قابل استفادهٔ مجدد — منبع حقیقت: PlayerProgressionService
class XpProgressBar extends StatelessWidget {
  final int xpTotal;
  final GamePalette palette;
  final bool showLabels;
  final double height;
  final bool animated;

  const XpProgressBar({
    super.key,
    required this.xpTotal,
    required this.palette,
    this.showLabels = true,
    this.height = 10,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = PlayerProgressionService.levelFromXp(xpTotal);
    final atMax = level >= PlayerProgressionService.maxLevel;
    final xpCurrent = PlayerProgressionService.xpCurrent(xpTotal);
    final xpRequired = PlayerProgressionService.reqXP(level);
    final progress = PlayerProgressionService.progress(xpTotal);
    final safeReq = xpRequired <= 0 ? 1 : xpRequired;

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: animated
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: height,
                backgroundColor: palette.border,
                valueColor: AlwaysStoppedAnimation(palette.accent),
              ),
            )
          : LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: height,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
    );

    if (!showLabels) return bar;

    final labelRow = Row(
      children: [
        Expanded(
          child: Text(
            atMax
                ? L10n.t('level_badge_max')
                : '$xpCurrent / $safeReq XP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ),
        if (!atMax)
          Text(
            L10n.tf('player_progress_xp_to_next', {'n': safeReq - xpCurrent}),
            style: TextStyle(
              fontSize: 11,
              color: palette.textMuted,
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        const SizedBox(height: 6),
        labelRow,
      ],
    );
  }
}