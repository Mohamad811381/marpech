// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/localization_service.dart';

enum AchievementCategory { start, skill, explore, master }

extension AchievementCategoryExt on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.start:
        return L10n.t('ach_cat_start');
      case AchievementCategory.skill:
        return L10n.t('ach_cat_skill');
      case AchievementCategory.explore:
        return L10n.t('ach_cat_explore');
      case AchievementCategory.master:
        return L10n.t('ach_cat_master');
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementCategory.start:
        return Icons.rocket_launch_rounded;
      case AchievementCategory.skill:
        return Icons.bolt_rounded;
      case AchievementCategory.explore:
        return Icons.explore_rounded;
      case AchievementCategory.master:
        return Icons.workspace_premium_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AchievementCategory.start:
        return const Color(0xFF4CE0B3);
      case AchievementCategory.skill:
        return const Color(0xFFFFD700);
      case AchievementCategory.explore:
        return const Color(0xFFFF8A5B);
      case AchievementCategory.master:
        return const Color(0xFFFF5CAB);
    }
  }
}

class AchievementStats {
  final int gamesPlayed;
  final int totalScore;
  final int longestSnake;
  final int bestEasy;      // ← جدید
  final int bestNormal;    // ← جدید
  final int bestAny;
  final int bestHard;
  final int levelsCompleted;
  final int chaptersCompleted;
  final bool finalLevelDone;
  final int goldenApples;
  final int comboActivations;
  final int noShieldGames;
  final int portalsPassed;
  final int shieldSavedCount;
  final int shopItemsOwned;
  final int missionsCompleted;
  final int bestStreak;
  final int timeAttackBest;

  const AchievementStats({
    required this.gamesPlayed,
    required this.totalScore,
    required this.longestSnake,
    required this.bestEasy,     // ← جدید
    required this.bestNormal,   // ← جدید
    required this.bestAny,
    required this.bestHard,
    required this.levelsCompleted,
    required this.chaptersCompleted,
    required this.finalLevelDone,
    required this.goldenApples,
    required this.comboActivations,
    required this.noShieldGames,
    required this.portalsPassed,
    required this.shieldSavedCount,
    required this.shopItemsOwned,
    required this.missionsCompleted,
    required this.bestStreak,
    required this.timeAttackBest,
  });
}
class Achievement {
  final String id;
  final AchievementCategory category;
  final IconData icon;
  final Color color;
  final int target;
  final int Function(AchievementStats) progress;

  const Achievement({
    required this.id,
    required this.category,
    required this.icon,
    required this.color,
    required this.target,
    required this.progress,
  });

  String get title => L10n.t('ach_${id}_title');
  String get description => L10n.t('ach_${id}_desc');

  bool isUnlocked(AchievementStats s) => progress(s) >= target;
}

final List<Achievement> allAchievements = [
  // ============================================
  // 🟢 شروع (۶ دستاورد)
  // ============================================
  Achievement(
    id: 'first_game',
    category: AchievementCategory.start,
    icon: Icons.rocket_launch_rounded,
    color: const Color(0xFF4CE0B3),
    target: 1,
    progress: (s) => s.gamesPlayed,
  ),
  Achievement(
    id: 'first_win',
    category: AchievementCategory.start,
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFF4CE0B3),
    target: 1,
    progress: (s) => s.levelsCompleted,
  ),
  Achievement(
    id: 'first_star',
    category: AchievementCategory.start,
    icon: Icons.star_rounded,
    color: const Color(0xFFFFD700),
    target: 1,
    progress: (s) => s.goldenApples,
  ),
  Achievement(
    id: 'first_save',
    category: AchievementCategory.start,
    icon: Icons.shield_rounded,
    color: const Color(0xFF00F0FF),
    target: 1,
    progress: (s) => s.shieldSavedCount,
  ),
  Achievement(
    id: 'first_portal',
    category: AchievementCategory.start,
    icon: Icons.all_inclusive_rounded,
    color: const Color(0xFF7C4DFF),
    target: 1,
    progress: (s) => s.portalsPassed,
  ),
  Achievement(
    id: 'first_purchase',
    category: AchievementCategory.start,
    icon: Icons.shopping_bag_rounded,
    color: const Color(0xFFFF8A5B),
    target: 1,
    progress: (s) => s.shopItemsOwned,
  ),

  // ============================================
  // 🟡 مهارت (۶ دستاورد)
  // ============================================
  Achievement(
    id: 'score_500',
    category: AchievementCategory.skill,
    icon: Icons.trending_up_rounded,
    color: const Color(0xFF4CE0B3),
    target: 500,
    progress: (s) => s.bestAny,
  ),
  Achievement(
    id: 'score_1500',
    category: AchievementCategory.skill,
    icon: Icons.military_tech_rounded,
    color: const Color(0xFFFFD700),
    target: 1500,
    progress: (s) => s.bestAny,
  ),
  Achievement(
    id: 'score_3000',
    category: AchievementCategory.skill,
    icon: Icons.workspace_premium_rounded,
    color: const Color(0xFFFF6B8A),
    target: 3000,
    progress: (s) => s.bestAny,
  ),
  Achievement(
    id: 'snake_40',
    category: AchievementCategory.skill,
    icon: Icons.straighten_rounded,
    color: const Color(0xFF8A7BFF),
    target: 40,
    progress: (s) => s.longestSnake,
  ),
  Achievement(
    id: 'combo_30',
    category: AchievementCategory.skill,
    icon: Icons.bolt_rounded,
    color: const Color(0xFFFF5CAB),
    target: 30,
    progress: (s) => s.comboActivations,
  ),
  Achievement(
    id: 'no_shield_15',
    category: AchievementCategory.skill,
    icon: Icons.shield_outlined,
    color: const Color(0xFF7BFFD0),
    target: 15,
    progress: (s) => s.noShieldGames,
  ),

  // ============================================
  // 🟠 اکتشاف (۵ دستاورد)
  // ============================================
  Achievement(
    id: 'levels_10',
    category: AchievementCategory.explore,
    icon: Icons.map_rounded,
    color: const Color(0xFFFF8A5B),
    target: 10,
    progress: (s) => s.levelsCompleted,
  ),
  Achievement(
    id: 'chapter_1_done',
    category: AchievementCategory.explore,
    icon: Icons.looks_one_rounded,
    color: const Color(0xFF4CE0B3),
    target: 1,
    progress: (s) => s.chaptersCompleted,
  ),
  Achievement(
    id: 'chapter_2_done',
    category: AchievementCategory.explore,
    icon: Icons.looks_two_rounded,
    color: const Color(0xFFFFD700),
    target: 2,
    progress: (s) => s.chaptersCompleted,
  ),
  Achievement(
    id: 'chapter_3_done',
    category: AchievementCategory.explore,
    icon: Icons.looks_3_rounded,
    color: const Color(0xFF7C4DFF),
    target: 3,
    progress: (s) => s.chaptersCompleted,
  ),

Achievement(
  id: 'chapter_4_done',
  category: AchievementCategory.explore,
  icon: Icons.looks_4_rounded,
  color: const Color(0xFFFF3D3D),
  target: 4,
  progress: (s) => s.chaptersCompleted,
),

  Achievement(
    id: 'final_master',
    category: AchievementCategory.explore,
    icon: Icons.workspace_premium_rounded,
    color: const Color(0xFFFF5CAB),
    target: 1,
    progress: (s) => s.finalLevelDone ? 1 : 0,
  ),

  // ============================================
  // 🔴 استاد (۵ دستاورد)
  // ============================================
  Achievement(
    id: 'shop_10',
    category: AchievementCategory.master,
    icon: Icons.collections_bookmark_rounded,
    color: const Color(0xFFFFD700),
    target: 10,
    progress: (s) => s.shopItemsOwned,
  ),
  Achievement(
    id: 'all_levels',
    category: AchievementCategory.master,
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFFFF5CAB),
    target: 40,
    progress: (s) => s.levelsCompleted,
  ),
  Achievement(
    id: 'missions_10',
    category: AchievementCategory.master,
    icon: Icons.military_tech_rounded,
    color: const Color(0xFF8A7BFF),
    target: 10,
    progress: (s) => s.missionsCompleted,
  ),
  Achievement(
    id: 'streak_7',
    category: AchievementCategory.master,
    icon: Icons.local_fire_department_rounded,
    color: const Color(0xFFFF8A5B),
    target: 7,
    progress: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'time_1000',
    category: AchievementCategory.master,
    icon: Icons.timer_rounded,
    color: const Color(0xFF00F0FF),
    target: 1000,
    progress: (s) => s.timeAttackBest,
  ),
];