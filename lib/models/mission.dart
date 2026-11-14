// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../services/localization_service.dart';

enum MissionMetric {
  longestSnake,
  gamesPlayed,
  goldenApples,
  bestScore,
  levelsCompleted,
  timeAttackBest,
  noShieldGames,
  comboActivations,
  portalsPassed,
  chaptersCompleted,
  finalLevelCompleted,
  perfectLevels,
  currentCoins,
  bestStreak,
  achievementsUnlocked,
  completedChallenges,
  bossLevelsCompleted,
  totalScore,
}

enum MissionTab { base, advanced, collection }

extension MissionTabExt on MissionTab {
  String get label {
    switch (this) {
      case MissionTab.base:
        return L10n.t('mission_tab_base');
      case MissionTab.advanced:
        return L10n.t('mission_tab_advanced');
      case MissionTab.collection:
        return L10n.t('mission_tab_collection');
    }
  }

  IconData get icon {
    switch (this) {
      case MissionTab.base:
        return Icons.sports_esports_rounded;
      case MissionTab.advanced:
        return Icons.local_fire_department_rounded;
      case MissionTab.collection:
        return Icons.collections_bookmark_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MissionTab.base:
        return const Color(0xFF4CE0B3);
      case MissionTab.advanced:
        return const Color(0xFFFF8A5B);
      case MissionTab.collection:
        return const Color(0xFFFFD700);
    }
  }
}

class MissionStage {
  final int target;
  final int reward;
  const MissionStage({required this.target, required this.reward});
}

class Mission {
  final String id;
  final MissionTab tab;
  final MissionMetric metric;
  final IconData icon;
  final Color color;
  final List<MissionStage> stages;

  const Mission({
    required this.id,
    required this.tab,
    required this.metric,
    required this.icon,
    required this.color,
    required this.stages,
  });

  String get title => L10n.t('mission_${id}_title');
  String get description => L10n.t('mission_${id}_desc');
}

final List<Mission> allMissions = [
  // ============================================
  // 🎯 پایه (۸ ماموریت)
  // ============================================
  Mission(
    id: 'long_snake',
    tab: MissionTab.base,
    metric: MissionMetric.longestSnake,
    icon: Icons.straighten_rounded,
    color: const Color(0xFF8A7BFF),
    stages: const [
      MissionStage(target: 25, reward: 5),
      MissionStage(target: 40, reward: 10),
      MissionStage(target: 60, reward: 20),
      MissionStage(target: 85, reward: 30),
    ],
  ),
  Mission(
    id: 'traveler',
    tab: MissionTab.base,
    metric: MissionMetric.gamesPlayed,
    icon: Icons.sports_esports_rounded,
    color: const Color(0xFF4CE0B3),
    stages: const [
      MissionStage(target: 10, reward: 5),
      MissionStage(target: 50, reward: 10),
      MissionStage(target: 100, reward: 20),
      MissionStage(target: 200, reward: 30),
      MissionStage(target: 350, reward: 50),
    ],
  ),
  Mission(
    id: 'collector',
    tab: MissionTab.base,
    metric: MissionMetric.goldenApples,
    icon: Icons.star_rounded,
    color: const Color(0xFFFFD700),
    stages: const [
      MissionStage(target: 15, reward: 5),
      MissionStage(target: 50, reward: 10),
      MissionStage(target: 100, reward: 20),
      MissionStage(target: 200, reward: 30),
    ],
  ),
  Mission(
    id: 'champion',
    tab: MissionTab.base,
    metric: MissionMetric.bestScore,
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFFFF6B8A),
    stages: const [
      MissionStage(target: 500, reward: 5),
      MissionStage(target: 1000, reward: 15),
      MissionStage(target: 2000, reward: 30),
      MissionStage(target: 3500, reward: 50),
      MissionStage(target: 5000, reward: 75),
    ],
  ),
  Mission(
    id: 'explorer',
    tab: MissionTab.base,
    metric: MissionMetric.levelsCompleted,
    icon: Icons.map_rounded,
    color: const Color(0xFF00F0FF),
    stages: const [
      MissionStage(target: 5, reward: 5),
      MissionStage(target: 10, reward: 15),
      MissionStage(target: 20, reward: 30),
      MissionStage(target: 30, reward: 50),
      MissionStage(target: 40, reward: 70),
    ],
  ),
  Mission(
    id: 'time_master',
    tab: MissionTab.base,
    metric: MissionMetric.timeAttackBest,
    icon: Icons.timer_rounded,
    color: const Color(0xFFFF8A5B),
    stages: const [
      MissionStage(target: 350, reward: 5),
      MissionStage(target: 650, reward: 15),
      MissionStage(target: 1000, reward: 30),
      MissionStage(target: 1500, reward: 50),
    ],
  ),
  Mission(
    id: 'fearless',
    tab: MissionTab.base,
    metric: MissionMetric.noShieldGames,
    icon: Icons.shield_outlined,
    color: const Color(0xFF7BFFD0),
    stages: const [
      MissionStage(target: 5, reward: 5),
      MissionStage(target: 15, reward: 10),
      MissionStage(target: 30, reward: 20),
      MissionStage(target: 60, reward: 30),
    ],
  ),
  Mission(
    id: 'combo_master',
    tab: MissionTab.base,
    metric: MissionMetric.comboActivations,
    icon: Icons.bolt_rounded,
    color: const Color(0xFFFF5CAB),
    stages: const [
      MissionStage(target: 10, reward: 5),
      MissionStage(target: 30, reward: 15),
      MissionStage(target: 75, reward: 30),
      MissionStage(target: 150, reward: 50),
    ],
  ),

  // ============================================
  // 🌀 پیشرفته (۴ ماموریت)
  // ============================================
  Mission(
    id: 'portal_master',
    tab: MissionTab.advanced,
    metric: MissionMetric.portalsPassed,
    icon: Icons.all_inclusive_rounded,
    color: const Color(0xFF7C4DFF),
    stages: const [
      MissionStage(target: 10, reward: 10),
      MissionStage(target: 50, reward: 20),
      MissionStage(target: 150, reward: 40),
      MissionStage(target: 400, reward: 60),
    ],
  ),
  Mission(
    id: 'chapter_conqueror',
    tab: MissionTab.advanced,
    metric: MissionMetric.chaptersCompleted,
    icon: Icons.auto_stories_rounded,
    color: const Color(0xFF00E5FF),
    stages: const [
      MissionStage(target: 1, reward: 20),
      MissionStage(target: 2, reward: 50),
      MissionStage(target: 3, reward: 100),
      MissionStage(target: 4, reward: 150),
    ],
  ),
  Mission(
    id: 'final_master',
    tab: MissionTab.advanced,
    metric: MissionMetric.finalLevelCompleted,
    icon: Icons.workspace_premium_rounded,
    color: const Color(0xFFFFD700),
    stages: const [
      MissionStage(target: 1, reward: 100),
    ],
  ),
  Mission(
    id: 'perfectionist',
    tab: MissionTab.advanced,
    metric: MissionMetric.perfectLevels,
    icon: Icons.verified_rounded,
    color: const Color(0xFF4CE0B3),
    stages: const [
      MissionStage(target: 1, reward: 10),
      MissionStage(target: 5, reward: 20),
      MissionStage(target: 10, reward: 40),
      MissionStage(target: 20, reward: 60),
    ],
  ),

  // ============================================
  // 🛒 کلکسیون (۶ ماموریت)
  // ============================================
  Mission(
    id: 'wealthy',
    tab: MissionTab.collection,
    metric: MissionMetric.currentCoins,
    icon: Icons.savings_rounded,
    color: const Color(0xFFFFD700),
    stages: const [
      MissionStage(target: 200, reward: 5),
      MissionStage(target: 500, reward: 10),
      MissionStage(target: 1000, reward: 20),
      MissionStage(target: 2000, reward: 40),
    ],
  ),
  Mission(
    id: 'streak_master',
    tab: MissionTab.collection,
    metric: MissionMetric.bestStreak,
    icon: Icons.local_fire_department_rounded,
    color: const Color(0xFFFF6B8A),
    stages: const [
      MissionStage(target: 3, reward: 5),
      MissionStage(target: 7, reward: 10),
      MissionStage(target: 14, reward: 20),
      MissionStage(target: 30, reward: 40),
    ],
  ),
  Mission(
    id: 'achievement_hunter',
    tab: MissionTab.collection,
    metric: MissionMetric.achievementsUnlocked,
    icon: Icons.military_tech_rounded,
    color: const Color(0xFF8A7BFF),
    stages: const [
      MissionStage(target: 2, reward: 5),
      MissionStage(target: 4, reward: 10),
      MissionStage(target: 6, reward: 20),
      MissionStage(target: 8, reward: 40),
    ],
  ),
  Mission(
    id: 'challenge_doer',
    tab: MissionTab.collection,
    metric: MissionMetric.completedChallenges,
    icon: Icons.event_available_rounded,
    color: const Color(0xFFFF8A5B),
    stages: const [
      MissionStage(target: 3, reward: 5),
      MissionStage(target: 10, reward: 10),
      MissionStage(target: 25, reward: 20),
      MissionStage(target: 50, reward: 40),
    ],
  ),
  Mission(
    id: 'boss_slayer',
    tab: MissionTab.collection,
    metric: MissionMetric.bossLevelsCompleted,
    icon: Icons.local_police_rounded,
    color: const Color(0xFFFF5CAB),
    stages: const [
      MissionStage(target: 1, reward: 10),
      MissionStage(target: 2, reward: 20),
      MissionStage(target: 3, reward: 40),
      MissionStage(target: 4, reward: 60),
    ],
  ),
  Mission(
    id: 'marathon',
    tab: MissionTab.collection,
    metric: MissionMetric.totalScore,
    icon: Icons.trending_up_rounded,
    color: const Color(0xFF00F0FF),
    stages: const [
      MissionStage(target: 5000, reward: 5),
      MissionStage(target: 15000, reward: 10),
      MissionStage(target: 30000, reward: 20),
    ],
  ),
];
