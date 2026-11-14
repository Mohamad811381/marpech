import 'package:marpech/services/player_progression_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';
import 'daily_reward_service.dart';
import 'levels_service.dart';
import 'shop_service.dart';
import 'storage_service.dart';

class MissionProgress {
  final Mission mission;
  final int currentValue;
  final int claimedStages;

  const MissionProgress({
    required this.mission,
    required this.currentValue,
    required this.claimedStages,
  });

  int get totalStages => mission.stages.length;
  bool get isFullyDone => claimedStages >= totalStages;

  MissionStage? get currentStage =>
      isFullyDone ? null : mission.stages[claimedStages];

  bool get canClaimCurrent =>
      !isFullyDone && currentValue >= currentStage!.target;

  int get displayValue => isFullyDone
      ? mission.stages.last.target
      : currentValue.clamp(0, currentStage!.target);

  int get displayTarget =>
      isFullyDone ? mission.stages.last.target : currentStage!.target;

  double get ratio {
    if (isFullyDone) return 1.0;
    return (currentValue / currentStage!.target).clamp(0.0, 1.0);
  }
}

class MissionsService {
  static const _claimedKey = 'missions_claimed';
  static const _coinsKey = 'total_coins';

  static Future<Map<String, Set<int>>> _loadClaimed() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_claimedKey) ?? [];
    final map = <String, Set<int>>{};
    for (final s in raw) {
      final parts = s.split(':');
      if (parts.length == 2) {
        final idx = int.tryParse(parts[1]);
        if (idx != null) {
          map.putIfAbsent(parts[0], () => {}).add(idx);
        }
      }
    }
    return map;
  }

  static Future<void> _saveClaimed(Map<String, Set<int>> map) async {
    final p = await SharedPreferences.getInstance();
    final list = <String>[];
    map.forEach((missionId, stages) {
      for (final s in stages) {
        list.add('$missionId:$s');
      }
    });
    await p.setStringList(_claimedKey, list);
  }

  static Future<int> _valueFor(MissionMetric metric) async {
    switch (metric) {
      case MissionMetric.longestSnake:
        return StorageService.getLongestSnake();
      case MissionMetric.gamesPlayed:
        return StorageService.getGamesPlayed();
      case MissionMetric.goldenApples:
        return StorageService.getGoldenApples();
      case MissionMetric.bestScore:
        final easy = await StorageService.getBestScoreByIndex(0);
        final normal = await StorageService.getBestScoreByIndex(1);
        final hard = await StorageService.getBestScoreByIndex(2);
        final m = [easy, normal, hard]..sort();
        return m.last;
      case MissionMetric.levelsCompleted:
        final completed = await LevelsService.getCompleted();
        return completed.length;
      case MissionMetric.timeAttackBest:
        return StorageService.getTimeAttackBest();
      case MissionMetric.noShieldGames:
        return StorageService.getNoShieldGames();
      case MissionMetric.comboActivations:
        return StorageService.getComboActivations();
      case MissionMetric.portalsPassed:
        return StorageService.getPortalsPassed();
      case MissionMetric.chaptersCompleted:
        final completed = await LevelsService.getCompleted();
        var count = 0;
        for (final c in LevelsService.chapters) {
          if (!LevelsService.isChapterAvailable(c)) continue;
          var allDone = true;
          for (var i = c.startLevelId; i <= c.endLevelId; i++) {
            if (!completed.contains(i)) {
              allDone = false;
              break;
            }
          }
          if (allDone) count++;
        }
        return count;
      case MissionMetric.finalLevelCompleted:
        final completed = await LevelsService.getCompleted();
        return completed.contains(40) ? 1 : 0;
      case MissionMetric.perfectLevels:
        return StorageService.getPerfectLevels();
      case MissionMetric.currentCoins:
        return ShopService.getCoins();
      case MissionMetric.bestStreak:
        return DailyRewardService.getBestStreak();
      case MissionMetric.achievementsUnlocked:
        final unlocked = await StorageService.getUnlockedAchievements();
        return unlocked.length;
      case MissionMetric.completedChallenges:
        return StorageService.getCompletedChallenges();
      case MissionMetric.bossLevelsCompleted:
        final completed = await LevelsService.getCompleted();
        var count = 0;
        if (completed.contains(10)) count++;
        if (completed.contains(20)) count++;
        if (completed.contains(30)) count++;
        if (completed.contains(40)) count++;
        return count;
      case MissionMetric.totalScore:
        return StorageService.getTotalScore();
    }
  }

  /// همه‌ی ماموریت‌ها (شامل تموم‌شده‌ها)
  static Future<List<MissionProgress>> getAllProgress() async {
    final claimed = await _loadClaimed();
    final list = <MissionProgress>[];
    for (final m in allMissions) {
      final claimedSet = claimed[m.id] ?? {};
      final value = await _valueFor(m.metric);
      list.add(MissionProgress(
        mission: m,
        currentValue: value,
        claimedStages: claimedSet.length,
      ));
    }
    return list;
  }

  /// فقط ماموریت‌های تموم‌نشده (برای نمایش)
  static Future<List<MissionProgress>> getVisibleProgress({
    MissionTab? tab,
  }) async {
    final all = await getAllProgress();
    return all
        .where((p) => !p.isFullyDone)
        .where((p) => tab == null || p.mission.tab == tab)
        .toList();
  }

  static Future<int> claimableCount() async {
    final progress = await getAllProgress();
    return progress.where((p) => p.canClaimCurrent).length;
  }

  static Future<int> claimNextStage(String missionId) async {
    final all = await getAllProgress();
    MissionProgress? target;
    for (final p in all) {
      if (p.mission.id == missionId) {
        target = p;
        break;
      }
    }
    if (target == null || !target.canClaimCurrent) return 0;

    final stageIdx = target.claimedStages;
    final reward = target.currentStage!.reward;

    final claimed = await _loadClaimed();
    claimed.putIfAbsent(missionId, () => {}).add(stageIdx);
    await _saveClaimed(claimed);

    final p = await SharedPreferences.getInstance();
    final coins = (p.getInt(_coinsKey) ?? 0) + reward;
    await p.setInt(_coinsKey, coins);
    // 🎯 Stage 2: XP برای ماموریت
    await PlayerProgressionService.addXP(
      eventId: 'mission:$missionId:$stageIdx',
      amount: 30,
      source: 'mission',
    );

    return reward;
  }

  static Future<void> recordGame({
    required bool usedShield,
    required int goldenApplesThisGame,
    required int combosThisGame,
  }) async {
    if (goldenApplesThisGame > 0) {
      final prev = await StorageService.getGoldenApples();
      await StorageService.setGoldenApples(prev + goldenApplesThisGame);
    }

    if (!usedShield) {
      final prev = await StorageService.getNoShieldGames();
      await StorageService.setNoShieldGames(prev + 1);
    }

    if (combosThisGame > 0) {
      final prev = await StorageService.getComboActivations();
      await StorageService.setComboActivations(prev + combosThisGame);
    }
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_claimedKey);
  }
}
