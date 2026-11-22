import 'package:shared_preferences/shared_preferences.dart';
import '../models/difficulty.dart';

class StorageService {
  static const _shieldSavedKey = 'stats_shield_saved';
  static const _paletteKey = 'palette_index';
  static const _difficultyKey = 'difficulty_index';
  static const _mutedKey = 'muted';
  static const _gamesPlayedKey = 'stats_games_played';
  static const _totalScoreKey = 'stats_total_score';
  static const _longestSnakeKey = 'stats_longest_snake';
  static const _unlockedKey = 'stats_unlocked_achievements';
  static const _timeAttackBestKey = 'best_time_attack';
  static const _goldenApplesKey = 'stats_golden_apples';
  static const _noShieldGamesKey = 'stats_no_shield_games';
  static const _comboActivationsKey = 'stats_combo_activations';
  static const _playerXpTotalKey = 'player_xp_total';
  static const _xpBySourceKey = 'xp_by_source';
  static const _levelRewardsGrantedKey = 'level_rewards_granted';
  static const _xpProcessedEventsKey = 'xp_processed_events';
  static const _pendingXpTransactionKey = 'pending_xp_transaction';
  static const _xpSchemaVersionKey = 'xp_schema_version';
// static const _xpSchemaVersionKey = 'xp_schema_version';
  static const _levelOwnedCosmeticsKey = 'level_owned_cosmetics';

  static String _bestKey(Difficulty d) => 'best_${d.name}';

  // ---------- تم ----------
  static Future<int> getPaletteIndex() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_paletteKey) ?? 0;
  }

  static Future<void> setPaletteIndex(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_paletteKey, v);
  }

  // ---------- سختی ----------
  static Future<int> getDifficultyIndex() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_difficultyKey) ?? 1;
  }

  static Future<void> setDifficultyIndex(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_difficultyKey, v);
  }

  // ---------- صدا ----------
  static Future<bool> getMuted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_mutedKey) ?? false;
  }

  static Future<void> setMuted(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_mutedKey, v);
  }

  // ---------- رکورد ----------
  static Future<int> getBestScore(Difficulty d, {bool bot = false}) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(bot ? 'bot_${_bestKey(d)}' : _bestKey(d)) ?? 0;
  }

  static Future<void> setBestScore(Difficulty d, int v,
      {bool bot = false}) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(bot ? 'bot_${_bestKey(d)}' : _bestKey(d), v);
  }

  static Future<int> getBestScoreByIndex(int index) async {
    if (index < 0 || index >= Difficulty.values.length) return 0;
    return getBestScore(Difficulty.values[index]);
  }

  static String _timeBestKeyFor(Difficulty? d, bool bot) {
    final base = (d == null || d == Difficulty.normal)
        ? _timeAttackBestKey
        : '${_timeAttackBestKey}_${d.name}';
    return bot ? 'bot_$base' : base;
  }

  static Future<int> getTimeAttackBest({
    bool bot = false,
    Difficulty? difficulty,
  }) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_timeBestKeyFor(difficulty, bot)) ?? 0;
  }

  static Future<void> setTimeAttackBest(
    int v, {
    bool bot = false,
    Difficulty? difficulty,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_timeBestKeyFor(difficulty, bot), v);
  }

  // ---------- آمار ----------
  static Future<int> getGamesPlayed() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_gamesPlayedKey) ?? 0;
  }

  static Future<void> setGamesPlayed(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_gamesPlayedKey, v);
  }

  static Future<int> getTotalScore() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_totalScoreKey) ?? 0;
  }

  static Future<void> setTotalScore(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_totalScoreKey, v);
  }

  static Future<int> getLongestSnake() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_longestSnakeKey) ?? 0;
  }

  static Future<void> setLongestSnake(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_longestSnakeKey, v);
  }

  // ---------- شمارنده‌های ماموریت ----------
  static Future<int> getGoldenApples() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_goldenApplesKey) ?? 0;
  }

  static Future<void> setGoldenApples(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_goldenApplesKey, v);
  }

  static Future<int> getNoShieldGames() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_noShieldGamesKey) ?? 0;
  }

  static Future<void> setNoShieldGames(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_noShieldGamesKey, v);
  }

  static Future<int> getComboActivations() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_comboActivationsKey) ?? 0;
  }

  static Future<void> setComboActivations(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_comboActivationsKey, v);
  }

  // ---------- دستاوردها ----------
  static Future<Set<String>> getUnlockedAchievements() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_unlockedKey) ?? []).toSet();
  }

  static Future<void> setUnlockedAchievements(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_unlockedKey, ids.toList());
  }

  static Future<int> getPlayerXpTotal() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_playerXpTotalKey) ?? 0;
  }

  static Future<void> setPlayerXpTotal(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_playerXpTotalKey, v);
  }

  static Future<String> getXpBySourceRaw() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_xpBySourceKey) ?? '';
  }

  static Future<void> setXpBySourceRaw(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_xpBySourceKey, v);
  }

  static Future<Set<int>> getLevelRewardsGranted() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_levelRewardsGrantedKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Future<Set<String>> getXpProcessedEvents() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_xpProcessedEventsKey) ?? []).toSet();
  }

  static Future<String?> getPendingXpTransaction() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_pendingXpTransactionKey);
  }

  static Future<void> setPendingXpTransaction(String? v) async {
    final p = await SharedPreferences.getInstance();
    if (v == null) {
      await p.remove(_pendingXpTransactionKey);
    } else {
      await p.setString(_pendingXpTransactionKey, v);
    }
  }

  static Future<int> getXpSchemaVersion() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_xpSchemaVersionKey) ?? 0;
  }

  // ---------- Level-Owned Cosmetics (Stage 3) ----------

  static Future<Set<String>> getLevelOwnedCosmetics() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_levelOwnedCosmeticsKey) ?? []).toSet();
  }

  static Future<void> setLevelOwnedCosmetics(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_levelOwnedCosmeticsKey, ids.toList());
  }

  static Future<bool> isLevelCosmeticOwned(String id) async {
    return (await getLevelOwnedCosmetics()).contains(id);
  }

  /// افزودن idempotent — false اگر از قبل وجود داشت
  static Future<bool> addLevelOwnedCosmetic(String id) async {
    final current = await getLevelOwnedCosmetics();
    if (current.contains(id)) return false;
    current.add(id);
    await setLevelOwnedCosmetics(current);
    return true;
  }

  // ---------- ریست ----------
  static Future<void> resetAllStats() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_gamesPlayedKey);
    await p.remove(_totalScoreKey);
    await p.remove(_longestSnakeKey);
    await p.remove(_unlockedKey);
    await p.remove(_timeAttackBestKey);
    await p.remove(_goldenApplesKey);
    await p.remove(_noShieldGamesKey);
    await p.remove(_comboActivationsKey);
    await p.remove(_portalsPassedKey);
    await p.remove(_perfectLevelsKey);
    await p.remove(_completedChallengesKey);
    await p.remove(_shieldSavedKey);
    for (final d in Difficulty.values) {
      await p.remove(_bestKey(d));
    }
  }

  // ---------- Pity System ----------
  static String _pityKey(int levelId) => 'pity_$levelId';

  static Future<int> getPityCount(int levelId) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_pityKey(levelId)) ?? 0;
  }

  static Future<int> incrementPity(int levelId) async {
    final p = await SharedPreferences.getInstance();
    final cur = p.getInt(_pityKey(levelId)) ?? 0;
    final next = cur + 1;
    await p.setInt(_pityKey(levelId), next);
    return next;
  }

  static Future<void> resetPity(int levelId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pityKey(levelId));
  }

  /// بر اساس تعداد باخت پشت‌سرهم، تعداد سپر کمکی
  static int pityShieldsForCount(int count) {
    if (count >= 4) return 3;
    if (count == 3) return 2;
    if (count == 2) return 1;
    return 0;
  }

  /// ریست همه‌ی pityها (برای تنظیمات)
  static Future<void> resetAllPity() async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getKeys().where((k) => k.startsWith('pity_')).toList();
    for (final k in keys) {
      await p.remove(k);
    }
  }

  // ---------- ماموریت‌های جدید ----------
  static const _portalsPassedKey = 'stats_portals_passed';
  static const _perfectLevelsKey = 'stats_perfect_levels';
  static const _completedChallengesKey = 'stats_completed_challenges';

  static Future<int> getPortalsPassed() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_portalsPassedKey) ?? 0;
  }

  static Future<void> incrementPortalsPassed() async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_portalsPassedKey) ?? 0) + 1;
    await p.setInt(_portalsPassedKey, v);
  }

  static Future<int> getPerfectLevels() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_perfectLevelsKey) ?? 0;
  }

  static Future<void> incrementPerfectLevels() async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_perfectLevelsKey) ?? 0) + 1;
    await p.setInt(_perfectLevelsKey, v);
  }

  static Future<int> getCompletedChallenges() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_completedChallengesKey) ?? 0;
  }

  static Future<void> incrementCompletedChallenges() async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_completedChallengesKey) ?? 0) + 1;
    await p.setInt(_completedChallengesKey, v);
  }

  static Future<int> getShieldSavedCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_shieldSavedKey) ?? 0;
  }

  static Future<void> incrementShieldSavedCount() async {
    final p = await SharedPreferences.getInstance();
    final v = (p.getInt(_shieldSavedKey) ?? 0) + 1;
    await p.setInt(_shieldSavedKey, v);
  }

  // ---------- برنده ----------
  static const _winnerSeenKey = 'winner_seen';

  static Future<bool> hasSeenWinner() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_winnerSeenKey) ?? false;
  }

  static Future<void> markWinnerSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_winnerSeenKey, true);
  }
}
