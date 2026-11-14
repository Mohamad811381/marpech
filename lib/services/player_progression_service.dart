import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_reward.dart';
import '../models/player_profile.dart';
import '../models/player_title.dart';

/// [ValueNotifier] با getter عمومی برای listener leak detection.
class DebuggableValueNotifier<T> extends ValueNotifier<T> {
  DebuggableValueNotifier(super.value);

  @visibleForTesting
  bool get debugHasListeners => hasListeners;
}

class PlayerProgressionService {
  static const int maxLevel = 100;

  // ─── فرمول و کش ───
  static final List<int> _reqXP = List<int>.generate(maxLevel, (i) {
    final l = i + 1;
    return (10 + 10 * l + 0.15 * l * l).round();
  });

  static final List<int> _cumulativeXP = () {
    final c = List<int>.filled(maxLevel + 1, 0); // c[1] = 0
    for (var l = 2; l <= maxLevel; l++) {
      c[l] = c[l - 1] + _reqXP[l - 2];
    }
    return c;
  }();

  // ─── API عمومی (فقط محاسبات) ───
  static int reqXP(int level) => _reqXP[(level - 1).clamp(0, maxLevel - 1)];
  static int cumulativeXP(int level) => _cumulativeXP[level.clamp(1, maxLevel)];

  static int levelFromXp(int xp) {
    if (xp <= 0) return 1;
    for (var l = maxLevel; l >= 1; l--) {
      if (xp >= _cumulativeXP[l]) return l;
    }
    return 1;
  }

  static int xpCurrent(int xp) {
    final lvl = levelFromXp(xp);
    return xp - _cumulativeXP[lvl];
  }

  static double progress(int xp) {
    final lvl = levelFromXp(xp);
    if (lvl >= maxLevel) return 1.0;
    return xpCurrent(xp) / reqXP(lvl);
  }

  static PlayerTitle titleFor(int xp) => PlayerTitle.forLevel(levelFromXp(xp));

  // ─── Mutex برای سریال‌سازی ───
  static Future<void> _last = Future.value();
  static Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final prev = _last;
    _last = completer.future;
    return prev.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }

  // ─── خواندن پروفایل ───
  static Future<PlayerProfile> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    final xp = p.getInt('player_xp_total') ?? 0;
    final srcRaw = p.getString('xp_by_source');
    final src = <String, int>{};
    if (srcRaw != null && srcRaw.isNotEmpty) {
      // قالب: "game:100;ach:50"
      for (final part in srcRaw.split(';')) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final v = int.tryParse(kv[1]);
          if (v != null) src[kv[0]] = v;
        }
      }
    }
    final grantedRaw = p.getStringList('level_rewards_granted') ?? [];
    final granted = grantedRaw.map(int.tryParse).whereType<int>().toSet();
    final events = (p.getStringList('xp_processed_events') ?? []).toSet();
    return PlayerProfile(
      xpTotal: xp,
      xpBySource: src,
      levelRewardsGranted: granted,
      processedEvents: events,
    );
  }

  // ─── بازیابی در startup ───
  static Future<void> recoverPending() async {
    return _serialize(() async {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('pending_xp_transaction');
      if (raw == null || raw.isEmpty) return;

      // پارس ساده
      final parts = <String, String>{};
      for (final seg in raw.split('|')) {
        final i = seg.indexOf('=');
        if (i > 0) parts[seg.substring(0, i)] = seg.substring(i + 1);
      }
      final eventId = parts['eventId'];
      final xpBefore = int.tryParse(parts['xpBefore'] ?? '');
      final xpAfter = int.tryParse(parts['xpAfter'] ?? '');
      if (eventId == null || xpBefore == null || xpAfter == null) {
        await p.remove('pending_xp_transaction');
        return;
      }
      final source = parts['source'] ?? 'unknown';
// ...
      final srcRaw = p.getString('xp_by_source') ?? '';
      final src = <String, int>{};
      for (final part in srcRaw.split(';')) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final v = int.tryParse(kv[1]);
          if (v != null) src[kv[0]] = v;
        }
      }
      src[source] = (src[source] ?? 0) + (xpAfter - xpBefore);
      await p.setString(
        'xp_by_source',
        src.entries.map((e) => '${e.key}:${e.value}').join(';'),
      );

      final current = p.getInt('player_xp_total') ?? 0;
      if (current == xpAfter) {
        // XP نوشته شد — milestoneها و event
      } else if (current == xpBefore) {
        await p.setInt('player_xp_total', xpAfter);
      } else {
        debugPrint(
            'XP recover fail-safe: current=$current, tx=[$xpBefore→$xpAfter]');
        await p.remove('pending_xp_transaction');
        return;
      }

      await _grantMilestonesUpTo(levelFromXp(xpAfter));

      final events = (p.getStringList('xp_processed_events') ?? []).toSet();
      if (!events.contains(eventId)) {
        events.add(eventId);
        await p.setStringList('xp_processed_events', events.toList());
      }
      await p.remove('pending_xp_transaction');
    });
  }

  // ══════════════════════════════════════════════════════════════
  // Stage 4: Level-up dialog coordination
  // ══════════════════════════════════════════════════════════════

  /// صف level-upهای در انتظار نمایش.
  static final DebuggableValueNotifier<List<AddXpResult>> pendingLevelUps =
      DebuggableValueNotifier(const []);

  static final DebuggableValueNotifier<bool> dialogSafe =
      DebuggableValueNotifier(true);

  /// مجموعهٔ ownerهای فعال — Set semantics
  static final Set<Object> _dialogBlockers = {};

  static void blockDialogsFor(Object owner) {
    _dialogBlockers.add(owner);
    dialogSafe.value = false;
  }

  static void unblockDialogsFor(Object owner) {
    _dialogBlockers.remove(owner);
    dialogSafe.value = _dialogBlockers.isEmpty;
  }

  /// Enqueue فقط برای level-up واقعی (نه duplicate، نه no-op).
  /// internal — فقط از addXP و _completePendingTransaction صدا زده می‌شود.
  static void _enqueueLevelUp(AddXpResult r) {
    if (!r.didLevelUp || r.wasDuplicate) return;
    pendingLevelUps.value = [...pendingLevelUps.value, r];
  }

  /// اتمیک — همهٔ pendingها را برمی‌گرداند و صف را خالی می‌کند.
  static List<AddXpResult> consumePendingLevelUps() {
    final out = pendingLevelUps.value;
    if (out.isEmpty) return out;
    pendingLevelUps.value = const [];
    return out;
  }

  @visibleForTesting
  static void resetStateForTests() {
    _dialogBlockers.clear();
    pendingLevelUps.value = const [];
    dialogSafe.value = true;
    _last = Future.value();
  }

  // ─── افزودن XP (API اصلی) ───
  static Future<AddXpResult> addXP({
    required String eventId,
    required int amount,
    required String source,
  }) async {
    return _serialize(() async {
      final p = await SharedPreferences.getInstance();

      // ── ۰. بررسی pending برای همین event (resume) ──
      final pendingRaw = p.getString('pending_xp_transaction');
      if (pendingRaw != null && pendingRaw.isNotEmpty) {
        final parts = <String, String>{};
        for (final seg in pendingRaw.split('|')) {
          final i = seg.indexOf('=');
          if (i > 0) parts[seg.substring(0, i)] = seg.substring(i + 1);
        }
        if (parts['eventId'] == eventId) {
          // همان تراکنش نیمه‌کاره → از phase 2 ادامه بده
          if (kDebugMode) {
            debugPrint('[XP] Resuming pending transaction: $eventId');
          }
          return _completePendingTransaction(p, parts);
        }
      }

      // ── ۱. ضد‌تکرار ──
      final events = (p.getStringList('xp_processed_events') ?? []).toSet();
      if (events.contains(eventId)) {
        if (kDebugMode) {
          debugPrint('[XP] Event: $eventId');
          debugPrint('[XP] Source: $source');
          debugPrint('[XP] Amount: +$amount');
          debugPrint('[XP] Duplicate: true → no XP added');
        }
        return AddXpResult.alreadyProcessed();
      }

      if (amount <= 0) {
        if (kDebugMode) {
          debugPrint('[XP] Event: $eventId — amount <= 0, skipped');
        }
        return AddXpResult.noChange();
      }

      final xpBefore = p.getInt('player_xp_total') ?? 0;
      final xpAfter = xpBefore + amount;
      final oldLevel = levelFromXp(xpBefore);
      final newLevel = levelFromXp(xpAfter);

      // ── ۲. نوشتن pending ──
      await p.setString(
        'pending_xp_transaction',
        'eventId=$eventId|xpBefore=$xpBefore|xpAfter=$xpAfter|source=$source',
      );

      // ── ۳. فاز ۱: نوشتن XP ──
      await p.setInt('player_xp_total', xpAfter);

      // ── ۴. فاز ۲: source stats ──
      await _updateSourceStats(p, source, amount);

      // ── ۵. فاز ۳: milestoneها ──
      final grantedNew = await _grantMilestonesUpTo(newLevel);

      // ── ۶. فاز ۴: event committed ──
      events.add(eventId);
      await p.setStringList('xp_processed_events', events.toList());

      // ── ۷. فاز ۵: پاک کردن pending ──
      await p.remove('pending_xp_transaction');

      // ── ۸. Debug log ──
      if (kDebugMode) {
        debugPrint('[XP] Event: $eventId');
        debugPrint('[XP] Source: $source');
        debugPrint('[XP] Amount: +$amount');
        debugPrint('[XP] Duplicate: false');
        debugPrint('[XP] Total XP: $xpBefore -> $xpAfter');
        debugPrint('[XP] Level: $oldLevel -> $newLevel');
        final milestonesLog = grantedNew.isEmpty
            ? 'none'
            : grantedNew.map((r) => 'L${r.level}').join(', ');
        debugPrint('[XP] Milestone granted: $milestonesLog');
      }

      final result = AddXpResult(
        xpGained: amount,
        oldLevel: oldLevel,
        newLevel: newLevel,
        milestonesGranted: grantedNew,
        wasDuplicate: false,
      );
      // Stage 4: enqueue فقط بعد از commit کامل تراکنش (pending marker حذف شده)
      if (result.didLevelUp) _enqueueLevelUp(result);
      return result;
    });
  }

// ── Helper: تکمیل تراکنش نیمه‌کاره ──
  static Future<AddXpResult> _completePendingTransaction(
    SharedPreferences p,
    Map<String, String> parts,
  ) async {
    final eventId = parts['eventId']!;
    final xpBefore = int.tryParse(parts['xpBefore'] ?? '') ?? 0;
    final xpAfter = int.tryParse(parts['xpAfter'] ?? '') ?? 0;
    final pendingSource = parts['source'] ?? 'unknown';
    final amount = xpAfter - xpBefore;

    final current = p.getInt('player_xp_total') ?? 0;
    if (current == xpBefore) {
      // XP هنوز نوشته نشده → بنویس
      await p.setInt('player_xp_total', xpAfter);
    } else if (current != xpAfter) {
      // حالت نامعلوم → fail-safe
      if (kDebugMode) {
        debugPrint('[XP] Pending mismatch: current=$current, '
            'expected=[$xpBefore → $xpAfter], skipping');
      }
      await p.remove('pending_xp_transaction');
      return AddXpResult.noChange();
    }

    // source stats (idempotent — اگه قبلاً نوشته شده، دوباره جمع نمی‌شه)
    // نکته: ممکنه source قبلاً اضافه شده باشه → دوبار اضافه می‌شه
    // راه‌حل: از marker استفاده کن یا فقط اگه xpBySource با xpTotal هماهنگ نبود
    // ساده‌تر: در _updateSourceStats، total را از xp_total چک کن
    await _updateSourceStats(p, pendingSource, amount, idempotentCheck: true);

    // milestoneها
    final grantedNew = await _grantMilestonesUpTo(levelFromXp(xpAfter));

    // event
    final events = (p.getStringList('xp_processed_events') ?? []).toSet();
    events.add(eventId);
    await p.setStringList('xp_processed_events', events.toList());

    await p.remove('pending_xp_transaction');

    if (kDebugMode) {
      debugPrint('[XP] Recovered pending: $eventId, +$amount ($pendingSource)');
    }

    final result = AddXpResult(
      xpGained: amount,
      oldLevel: levelFromXp(xpBefore),
      newLevel: levelFromXp(xpAfter),
      milestonesGranted: grantedNew,
      wasDuplicate: false,
    );
    // Stage 4: enqueue بعد از commit (pending marker حذف شده)
    if (result.didLevelUp) _enqueueLevelUp(result);
    return result;
  }

// ── Helper: آپدیت source stats ──
  static Future<void> _updateSourceStats(
    SharedPreferences p,
    String source,
    int amount, {
    bool idempotentCheck = false,
  }) async {
    final srcRaw = p.getString('xp_by_source') ?? '';
    final src = <String, int>{};
    for (final part in srcRaw.split(';')) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final v = int.tryParse(kv[1]);
        if (v != null) src[kv[0]] = v;
      }
    }

    if (idempotentCheck) {
      // در حالت recovery، چک کن مجموع sourceها با xp_total هماهنگ باشه
      final total = p.getInt('player_xp_total') ?? 0;
      final sourceSum = src.values.fold<int>(0, (a, b) => a + b);
      if (sourceSum == total) {
        // stats از قبل درستن → skip
        return;
      }
    }

    src[source] = (src[source] ?? 0) + amount;
    await p.setString(
      'xp_by_source',
      src.entries.map((e) => '${e.key}:${e.value}').join(';'),
    );
  }

  // ─── اعطای خودکار milestoneها (idempotent) ───
  static Future<List<LevelReward>> _grantMilestonesUpTo(int newLevel) async {
    final p = await SharedPreferences.getInstance();
    final granted = (p.getStringList('level_rewards_granted') ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();

    final newlyGranted = <LevelReward>[];
    // در _grantMilestonesUpTo یا بعدش
    final srcRaw = p.getString('xp_by_source') ?? '';
    final src = <String, int>{};
    for (final part in srcRaw.split(';')) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final v = int.tryParse(kv[1]);
        if (v != null) src[kv[0]] = v;
      }
    }
// source رو از pending نمی‌دونیم — ولی XP کل از قبل ثبت شده
// اگر source != pending.source → می‌تونیم صفر بذاریم
// راه‌حل: marker در pending ذخیره کن

    for (final reward in allLevelRewards) {
      if (reward.level > newLevel) continue;
      if (granted.contains(reward.level)) continue;

      // ── سکه: با marker پایدار ──
      final markerKey = 'milestone_${reward.level}_coins';
      final marker =
          p.getString(markerKey); // null | "pending:{coinsBefore}" | "done"

      if (marker == null) {
        final coinsBefore = p.getInt('total_coins') ?? 0;
        await p.setString(markerKey, 'pending:$coinsBefore');
        await p.setInt('total_coins', coinsBefore + reward.coins);
        await p.setString(markerKey, 'done');
      } else if (marker.startsWith('pending:')) {
        final coinsBefore = int.tryParse(marker.substring(8)) ?? 0;
        final current = p.getInt('total_coins') ?? 0;
        final expected = coinsBefore + reward.coins;

        if (current == expected) {
          // سکه قبلاً نوشته شده، فقط done
        } else if (current == coinsBefore) {
          // سکه نوشته نشده، حالا بنویس
          await p.setInt('total_coins', expected);
        } else {
          // نامعلوم → fail-safe: بدون افزودن، فقط done
          debugPrint('[MILESTONE] coins unknown: level=${reward.level} '
              'before=$coinsBefore current=$current expected=$expected');
        }
        await p.setString(markerKey, 'done');
      } else if (marker == 'done') {
        // ok
      }

      // ── cosmetic: idempotent با set ──
      if (reward.hasCosmetic) {
        final cosmetics =
            (p.getStringList('level_owned_cosmetics') ?? []).toSet();
        if (!cosmetics.contains(reward.cosmeticId)) {
          cosmetics.add(reward.cosmeticId!);
          await p.setStringList('level_owned_cosmetics', cosmetics.toList());
        }
      }

      granted.add(reward.level);
      await p.setStringList(
        'level_rewards_granted',
        granted.map((e) => e.toString()).toList(),
      );

      newlyGranted.add(reward);
    }

    return newlyGranted;
  }

  // ─── Migration (اولین بار) ───
  static Future<void> ensureSchema() async {
    final p = await SharedPreferences.getInstance();
    if (p.getInt('xp_schema_version') == null) {
      await p.setInt('player_xp_total', 0);
      await p.setStringList('level_rewards_granted', []);
      await p.setStringList('xp_processed_events', []);
      await p.setStringList('level_owned_cosmetics', []);
      await p.setString('xp_by_source', '');
      await p.setInt('xp_schema_version', 1);
    }
  }
}

class AddXpResult {
  final int xpGained;
  final int oldLevel;
  final int newLevel;
  final List<LevelReward> milestonesGranted;
  final bool wasDuplicate;

  const AddXpResult({
    required this.xpGained,
    required this.oldLevel,
    required this.newLevel,
    required this.milestonesGranted,
    required this.wasDuplicate,
  });

  factory AddXpResult.alreadyProcessed() => const AddXpResult(
        xpGained: 0,
        oldLevel: 0,
        newLevel: 0,
        milestonesGranted: [],
        wasDuplicate: true,
      );
  factory AddXpResult.noChange() => const AddXpResult(
        xpGained: 0,
        oldLevel: 0,
        newLevel: 0,
        milestonesGranted: [],
        wasDuplicate: false,
      );

  bool get didLevelUp => newLevel > oldLevel;
}
