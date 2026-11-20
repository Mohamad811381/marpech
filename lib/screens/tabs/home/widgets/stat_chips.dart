// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/services/localization_service.dart';
import 'package:marpech/services/player_progression_service.dart';
import '../home_helpers.dart';
import 'progress_tile.dart';

class StatChips extends StatelessWidget {
  final GamePalette palette;
  final int playerXp;
  final double missionsRatio;
  final int claimableMissions;
  final int unlockedAchievements;
  final bool animationsEnabled;
  final VoidCallback onOpenMissions;
  final VoidCallback onOpenAchievements;

  const StatChips({
    super.key,
    required this.palette,
    required this.playerXp,
    required this.missionsRatio,
    required this.claimableMissions,
    required this.unlockedAchievements,
    required this.animationsEnabled,
    required this.onOpenMissions,
    required this.onOpenAchievements,
  });

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    final level = PlayerProgressionService.levelFromXp(playerXp);
    final isMax = level >= PlayerProgressionService.maxLevel;

    final inLevel = isMax ? 0 : PlayerProgressionService.xpCurrent(playerXp);
    final req = isMax ? 1 : math.max(1, PlayerProgressionService.reqXP(level));
    final xpLeft = isMax ? 0 : req - inLevel;
    final progress = isMax ? 1.0 : (inLevel / req).clamp(0.0, 1.0);

    // 📱 ریسپانسیو: عرض هر کاشی ≈ (عرض صفحه - پدینگ - فاصله‌ها) / 3
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 64) / 3; // 44 پدینگ + 20 فاصله
    final iconSize = (tileWidth * 0.45).roundToDouble().clamp(40.0, 56.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ProgressTile(
              palette: p,
              iconSize: iconSize,
              letterSpacing: homeLs(1.2),
              animationsEnabled: animationsEnabled,
              icon: Icons.flag_outlined,
              lottieAsset: 'assets/lottie/mission.json',
              value: '${(missionsRatio * 100).round()}%',
              label: homeUpper(claimableMissions > 0
                  ? L10n.t('home_stat_ready')
                  : L10n.t('home_stat_missions')),
              onTap: onOpenMissions,
              progress: missionsRatio,
              highlight: claimableMissions > 0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProgressTile(
              palette: p,
              iconSize: iconSize,
              letterSpacing: homeLs(1.2),
              animationsEnabled: animationsEnabled,
              icon: Icons.stars_rounded,
              lottieAsset: 'assets/lottie/achievement.json',
              value: '$unlockedAchievements',
              label: homeUpper(L10n.t('home_stat_achievements')),
              onTap: onOpenAchievements,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProgressTile(
              palette: p,
              iconSize: iconSize,
              letterSpacing: homeLs(1.2),
              animationsEnabled: animationsEnabled,
              icon: Icons.trending_up_rounded,
              lottieAsset: 'assets/lottie/trending.json', // اگه داری
              value: isMax ? 'MAX' : '$xpLeft',
              label: homeUpper(L10n.t('home_stat_xp_next')),
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }
}
