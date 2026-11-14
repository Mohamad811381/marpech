import 'dart:convert';
import 'dart:math';
import 'package:marpech/services/player_progression_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge.dart';
import 'storage_service.dart';

class DailyChallengesService {
  static const _dateKey = 'daily_date';
  static const _dataKey = 'daily_data';
  static const _coinsKey = 'total_coins';

  static String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> ensureToday() async {
    final p = await SharedPreferences.getInstance();
    final today = todayString();
    final stored = p.getString(_dateKey);
    if (stored != today) {
      await _generateForToday(today);
    }
  }

  static Future<void> _generateForToday(String date) async {
    final p = await SharedPreferences.getInstance();
    final seed = int.parse(date.replaceAll('-', ''));
    final rng = Random(seed);

    final pool = <_Template>[
      _Template(ChallengeType.gamesPlayed, 3, 10),
      _Template(ChallengeType.totalFood, 20, 10),
      _Template(ChallengeType.totalScore, 100, 15),
      _Template(ChallengeType.totalScore, 250, 20),
      _Template(ChallengeType.goldenApples, 3, 20),
      _Template(ChallengeType.noShieldGames, 2, 20),
      _Template(ChallengeType.noSlowGames, 2, 20),
      _Template(ChallengeType.longestSnake, 20, 20),
      _Template(ChallengeType.levelsCompleted, 2, 25),
      _Template(ChallengeType.totalScore, 500, 30),
      _Template(ChallengeType.goldenApples, 5, 30),
      _Template(ChallengeType.timeAttackBestScore, 150, 35),
    ];

    final shuffled = List<_Template>.from(pool)..shuffle(rng);

    final chosen = <_Template>[];
    final usedTypes = <ChallengeType>{};
    for (final t in shuffled) {
      if (chosen.length >= 3) break;
      if (usedTypes.contains(t.type)) continue;
      usedTypes.add(t.type);
      chosen.add(t);
    }

    final challenges = chosen
        .map((t) => DailyChallenge(
              id: '${date}_${t.type.name}',
              type: t.type,
              target: t.target,
              progress: 0,
              reward: t.reward,
              claimed: false,
            ))
        .toList();

    await p.setString(_dateKey, date);
    await p.setString(
      _dataKey,
      jsonEncode(challenges.map((c) => c.toJson()).toList()),
    );
  }

  static Future<List<DailyChallenge>> getChallenges() async {
    await ensureToday();
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_dataKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((j) => DailyChallenge.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _save(List<DailyChallenge> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _dataKey,
      jsonEncode(list.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> recordGameEnd({
    required int score,
    required int foodsEaten,
    required int goldenApples,
    required bool usedShield,
    required bool usedSlow,
    required int snakeLength,
    required bool isTimeAttack,
  }) async {
    final challenges = await getChallenges();
    if (challenges.isEmpty) return;

    final updated = <DailyChallenge>[];
    for (final c in challenges) {
      var progress = c.progress;
      switch (c.type) {
        case ChallengeType.totalScore:
          progress += score;
          break;
        case ChallengeType.totalFood:
          progress += foodsEaten;
          break;
        case ChallengeType.goldenApples:
          progress += goldenApples;
          break;
        case ChallengeType.gamesPlayed:
          progress += 1;
          break;
        case ChallengeType.noShieldGames:
          if (!usedShield) progress += 1;
          break;
        case ChallengeType.noSlowGames:
          if (!usedSlow) progress += 1;
          break;
        case ChallengeType.longestSnake:
          if (snakeLength > progress) progress = snakeLength;
          break;
        case ChallengeType.timeAttackBestScore:
          if (isTimeAttack && score > progress) progress = score;
          break;
        case ChallengeType.levelsCompleted:
          break;
      }
      updated.add(c.copyWith(progress: progress));
    }

    await _save(updated);
  }

  static Future<void> recordLevelCompleted() async {
    final challenges = await getChallenges();
    if (challenges.isEmpty) return;

    final updated = <DailyChallenge>[];
    for (final c in challenges) {
      if (c.type == ChallengeType.levelsCompleted) {
        updated.add(c.copyWith(progress: c.progress + 1));
      } else {
        updated.add(c);
      }
    }
    await _save(updated);
  }

  static Future<int> claimReward(String challengeId) async {
    final challenges = await getChallenges();
    var totalReward = 0;
    final updated = <DailyChallenge>[];
    for (final c in challenges) {
      if (c.id == challengeId && c.canClaim) {
        totalReward = c.reward;
        updated.add(c.copyWith(claimed: true));
      } else {
        updated.add(c);
      }
    }
    if (totalReward > 0) {
      await _save(updated);
      final p = await SharedPreferences.getInstance();
      final coins = (p.getInt(_coinsKey) ?? 0) + totalReward;
      await p.setInt(_coinsKey, coins);
      // 🎯 Stage 2: XP برای چالش روزانه
      await PlayerProgressionService.addXP(
        eventId: 'challenge:$challengeId',
        amount: 30,
        source: 'challenge',
      );
      // 📊 ماموریت‌ها
      await StorageService.incrementCompletedChallenges();
    }

    return totalReward;
  }

  static Future<int> getCoins() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_coinsKey) ?? 0;
  }

  static Future<int> claimableCount() async {
    final list = await getChallenges();
    return list.where((c) => c.canClaim).length;
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_dateKey);
    await p.remove(_dataKey);
  }
}

class _Template {
  final ChallengeType type;
  final int target;
  final int reward;
  _Template(this.type, this.target, this.reward);
}
