import 'package:marpech/services/player_progression_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyRewardStatus {
  final bool canClaimToday;
  final bool claimedToday;
  final int streak;
  final int cycleDay;
  final int rewardAmount;
  final List<bool> claimedInCycle;

  const DailyRewardStatus({
    required this.canClaimToday,
    required this.claimedToday,
    required this.streak,
    required this.cycleDay,
    required this.rewardAmount,
    required this.claimedInCycle,
  });
}

class DailyRewardService {
  static const _lastClaimKey = 'daily_reward_last_claim';
  static const _streakKey = 'daily_reward_streak';
  static const _bestStreakKey = 'daily_reward_best_streak'; // ← این
  static const _autoShownKey = 'daily_reward_auto_shown';
  static const _coinsKey = 'total_coins';

  static const List<int> rewards = [5, 10, 15, 20, 25, 35, 50];

  static String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static Future<DailyRewardStatus> getStatus() async {
    final p = await SharedPreferences.getInstance();
    final lastClaim = p.getString(_lastClaimKey);
    final storedStreak = p.getInt(_streakKey) ?? 0;
    final today = _todayString();

    if (lastClaim == null) {
      return const DailyRewardStatus(
        canClaimToday: true,
        claimedToday: false,
        streak: 0,
        cycleDay: 1,
        rewardAmount: 5,
        claimedInCycle: [false, false, false, false, false, false, false],
      );
    }

    if (lastClaim == today) {
      final cd = ((storedStreak - 1) % 7) + 1;
      return DailyRewardStatus(
        canClaimToday: false,
        claimedToday: true,
        streak: storedStreak,
        cycleDay: cd,
        rewardAmount: rewards[cd - 1],
        claimedInCycle: List.generate(7, (i) => i < cd),
      );
    }

    final lastDate = _dateOnly(DateTime.parse(lastClaim));
    final todayDate = _dateOnly(DateTime.now());
    final diff = todayDate.difference(lastDate).inDays;

    final newStreak = diff == 1 ? storedStreak + 1 : 1;
    final cd = ((newStreak - 1) % 7) + 1;

    return DailyRewardStatus(
      canClaimToday: true,
      claimedToday: false,
      streak: newStreak,
      cycleDay: cd,
      rewardAmount: rewards[cd - 1],
      claimedInCycle: List.generate(7, (i) => i < cd - 1),
    );
  }

  static Future<int> claim() async {
    final status = await getStatus();
    if (!status.canClaimToday) return 0;

    final p = await SharedPreferences.getInstance();
    await p.setString(_lastClaimKey, _todayString());
    await p.setInt(_streakKey, status.streak);

    // 🏆 به‌روزرسانی بهترین استریک
    final best = p.getInt(_bestStreakKey) ?? 0;
    if (status.streak > best) {
      await p.setInt(_bestStreakKey, status.streak);
    }

    final coins = (p.getInt(_coinsKey) ?? 0) + status.rewardAmount;
    await p.setInt(_coinsKey, coins);
    // 🎯 Stage 2: XP برای پاداش روزانه
await PlayerProgressionService.addXP(
  eventId: 'daily:${_todayString()}',
  amount: 15,
  source: 'daily_reward',
);

    return status.rewardAmount;
  }

  /// 🏆 بهترین استریک ثبت‌شده
  static Future<int> getBestStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_bestStreakKey) ?? 0;
  }

  static Future<bool> shouldAutoShow() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_autoShownKey) == _todayString()) return false;
    final s = await getStatus();
    return s.canClaimToday;
  }

  static Future<void> markAutoShown() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_autoShownKey, _todayString());
  }

  static Future<int> getCoins() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_coinsKey) ?? 0;
  }
}
