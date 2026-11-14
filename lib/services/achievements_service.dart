import '../models/achievement.dart';
import 'daily_reward_service.dart';
import 'levels_service.dart';
import 'missions_service.dart';
import 'shop_service.dart';
import 'storage_service.dart';
import 'player_progression_service.dart';

class AchievementsService {
  static Future<AchievementStats> getStats() async {
    final games = await StorageService.getGamesPlayed();
    final total = await StorageService.getTotalScore();
    final longest = await StorageService.getLongestSnake();
    final bestEasy = await StorageService.getBestScoreByIndex(0);
    final bestNormal = await StorageService.getBestScoreByIndex(1);
    final bestHard = await StorageService.getBestScoreByIndex(2);
    final completed = await LevelsService.getCompleted();
    final goldenApples = await StorageService.getGoldenApples();
    final comboActivations = await StorageService.getComboActivations();
    final noShieldGames = await StorageService.getNoShieldGames();
    final portalsPassed = await StorageService.getPortalsPassed();
    final shieldSaved = await StorageService.getShieldSavedCount();
    final bestStreak = await DailyRewardService.getBestStreak();
    final timeAttackBest = await StorageService.getTimeAttackBest();

    // بهترین امتیاز از هر سه سختی
    final scores = [bestEasy, bestNormal, bestHard]..sort();
    final bestAny = scores.last;

    // شمارش فصل‌های کامل
    var chaptersCompleted = 0;
    for (final c in LevelsService.chapters) {
      if (!LevelsService.isChapterAvailable(c)) continue;
      var allDone = true;
      for (var i = c.startLevelId; i <= c.endLevelId; i++) {
        if (!completed.contains(i)) {
          allDone = false;
          break;
        }
      }
      if (allDone) chaptersCompleted++;
    }

    // مرحله ۳۰
    final finalLevelDone = completed.contains(40);
    // تعداد آیتم‌های فروشگاه خریداری‌شده
    final themes = await ShopService.getUnlockedThemes();
    final snakes = await ShopService.getUnlockedSnakeSkins();
    final ghosts = await ShopService.getUnlockedGhostSkins();
    final foods = await ShopService.getUnlockedFoodSkins();
    final trails = await ShopService.getUnlockedTrails();
    final patterns = await ShopService.getUnlockedPatterns();
    final intros = await ShopService.getUnlockedIntros();
    final levelCosmetics = await StorageService.getLevelOwnedCosmetics();

    final shopItemsOwned = (themes.length - 3) +
        (snakes.length - 1) +
        (ghosts.length - 1) +
        (foods.length - 1) +
        (trails.length - 1) +
        (patterns.length - 1) +
        (intros.length - 1) +
        levelCosmetics.length;

    // تعداد ماموریت‌های تموم‌شده
    final missions = await MissionsService.getAllProgress();
    final missionsCompleted = missions.where((p) => p.isFullyDone).length;

    return AchievementStats(
      gamesPlayed: games,
      totalScore: total,
      longestSnake: longest,
      bestEasy: bestEasy, // ← جدید
      bestNormal: bestNormal, // ← جدید
      bestAny: bestAny,
      bestHard: bestHard,
      levelsCompleted: completed.length,
      chaptersCompleted: chaptersCompleted,
      finalLevelDone: finalLevelDone,
      goldenApples: goldenApples,
      comboActivations: comboActivations,
      noShieldGames: noShieldGames,
      portalsPassed: portalsPassed,
      shieldSavedCount: shieldSaved,
      shopItemsOwned: shopItemsOwned,
      missionsCompleted: missionsCompleted,
      bestStreak: bestStreak,
      timeAttackBest: timeAttackBest,
    );
  }

  /// ثبت بازی و چک آنلاک دستاوردهای جدید
  static Future<List<Achievement>> recordGame({
    required int score,
    required int snakeLength,
  }) async {
    final prevGames = await StorageService.getGamesPlayed();
    final prevTotal = await StorageService.getTotalScore();
    final prevLongest = await StorageService.getLongestSnake();

    await StorageService.setGamesPlayed(prevGames + 1);
    await StorageService.setTotalScore(prevTotal + score);
    if (snakeLength > prevLongest) {
      await StorageService.setLongestSnake(snakeLength);
    }

    final stats = await getStats();
    final unlocked = await StorageService.getUnlockedAchievements();
    final newlyUnlocked = <Achievement>[];

    for (final a in allAchievements) {
      if (!unlocked.contains(a.id) && a.isUnlocked(stats)) {
        unlocked.add(a.id);
        newlyUnlocked.add(a);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await StorageService.setUnlockedAchievements(unlocked);
    }
    // 🎯 Stage 2: XP برای دستاوردهای جدید
    for (final a in newlyUnlocked) {
      await PlayerProgressionService.addXP(
        eventId: 'ach:${a.id}',
        amount: 40,
        source: 'achievement',
      );
    }

    return newlyUnlocked;
  }

  /// چک دستاوردها بعد از یه رویداد خاص (خرید، ماموریت، ...)
  static Future<List<Achievement>> checkUnlocks() async {
    final stats = await getStats();
    final unlocked = await StorageService.getUnlockedAchievements();
    final newlyUnlocked = <Achievement>[];

    for (final a in allAchievements) {
      if (!unlocked.contains(a.id) && a.isUnlocked(stats)) {
        unlocked.add(a.id);
        newlyUnlocked.add(a);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await StorageService.setUnlockedAchievements(unlocked);
    }
    for (final a in newlyUnlocked) {
      await PlayerProgressionService.addXP(
        eventId: 'ach:${a.id}',
        amount: 40,
        source: 'achievement',
      );
    }

    return newlyUnlocked;
  }

  static Future<int> unlockedCount() async {
    return (await StorageService.getUnlockedAchievements()).length;
  }
}
