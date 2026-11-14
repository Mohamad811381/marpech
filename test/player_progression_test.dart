// ignore_for_file: await_only_futures

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/player_title.dart';
import 'package:marpech/models/level_reward.dart';
import 'package:marpech/services/player_progression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  group('XP formula', () {
    test('reqXP(1) == 20',   () => expect(PlayerProgressionService.reqXP(1), 20));
    test('reqXP(10) == 125', () => expect(PlayerProgressionService.reqXP(10), 125));
    test('reqXP(25) == 354', () => expect(PlayerProgressionService.reqXP(25), 354));
    test('reqXP(50) == 885', () => expect(PlayerProgressionService.reqXP(50), 885));
    test('reqXP(100)== 2510',() => expect(PlayerProgressionService.reqXP(100), 2510));
  });

  group('Cumulative XP', () {
    test('cumulativeXP(1) == 0',    () => expect(PlayerProgressionService.cumulativeXP(1), 0));
    test('cumulativeXP(10) == 582', () => expect(PlayerProgressionService.cumulativeXP(10), 582));
    test('cumulativeXP(25) == 3973',() => expect(PlayerProgressionService.cumulativeXP(25), 3973));
    test('cumulativeXP(50) == 18800',()=> expect(PlayerProgressionService.cumulativeXP(50), 18800));
    test('cumulativeXP(100)== 99735',()=> expect(PlayerProgressionService.cumulativeXP(100), 99735));
  });

  group('Level from XP', () {
    test('0 → 1',       () => expect(PlayerProgressionService.levelFromXp(0), 1));
    test('582 → 10',    () => expect(PlayerProgressionService.levelFromXp(582), 10));
    test('4697 → 26',   () => expect(PlayerProgressionService.levelFromXp(4697), 26));
    test('4698 → 27',   () => expect(PlayerProgressionService.levelFromXp(4698), 27));
    test('5000 → 27',   () => expect(PlayerProgressionService.levelFromXp(5000), 27));
    test('5087 → 28',   () => expect(PlayerProgressionService.levelFromXp(5087), 28));
    test('99735 → 100', () => expect(PlayerProgressionService.levelFromXp(99735), 100));
    test('999999 → 100',() => expect(PlayerProgressionService.levelFromXp(999999), 100));
  });

  group('Progress percentage', () {
    test('progress(582) == 0.0', () {
      expect(PlayerProgressionService.progress(582), 0.0);
    });
    test('progress(644) ≈ 0.496', () {
      expect(PlayerProgressionService.progress(644), closeTo(0.496, 0.001));
    });
    test('progress(99735) == 1.0', () {
      expect(PlayerProgressionService.progress(99735), 1.0);
    });
  });

  group('Titles', () {
    test('L1 → beginner',        () => expect(PlayerTitle.forLevel(1).id, 'beginner'));
    test('L10 → skilled',        () => expect(PlayerTitle.forLevel(10).id, 'skilled'));
    test('L30 → snake_master',   () => expect(PlayerTitle.forLevel(30).id, 'snake_master'));
    test('L50 → champion',       () => expect(PlayerTitle.forLevel(50).id, 'champion'));
    test('L100 → marpech_master',() => expect(PlayerTitle.forLevel(100).id, 'marpech_master'));
  });

  group('Milestone rewards', () {
    test('sum == 4630', () {
      final sum = allLevelRewards.fold<int>(0, (a, r) => a + r.coins);
      expect(sum, 4630);
    });
    test('L20 → bronze_trail', () {
      expect(rewardForLevel(20)?.cosmeticId, 'bronze_trail');
    });
  });

  group('addXP + anti-duplication', () {
    test('first time applies', () async {
      final r = await PlayerProgressionService.addXP(
        eventId: 'test:1', amount: 100, source: 'test',
      );
      expect(r.wasDuplicate, false);
      expect(r.xpGained, 100);
      final profile = await PlayerProgressionService.loadProfile();
      expect(profile.xpTotal, 100);
    });

    test('same eventId → duplicate, no XP', () async {
      await PlayerProgressionService.addXP(
        eventId: 'test:x', amount: 100, source: 'test',
      );
      final r = await PlayerProgressionService.addXP(
        eventId: 'test:x', amount: 100, source: 'test',
      );
      expect(r.wasDuplicate, true);
      final profile = await PlayerProgressionService.loadProfile();
      expect(profile.xpTotal, 100); // ← بدون افزایش
    });

    test('different eventId → applied', () async {
      await PlayerProgressionService.addXP(
        eventId: 'test:a', amount: 100, source: 'test',
      );
      await PlayerProgressionService.addXP(
        eventId: 'test:b', amount: 50, source: 'test',
      );
      final profile = await PlayerProgressionService.loadProfile();
      expect(profile.xpTotal, 150);
    });
  });

  group('Multi-level-up', () {
    test('5000 XP from 0 → level 27', () async {
      final r = await PlayerProgressionService.addXP(
        eventId: 'big:1', amount: 5000, source: 'test',
      );
      expect(r.newLevel, 27);
      expect(r.oldLevel, 1);
    });
  });

  group('Milestone auto-grant', () {
    test('XP 600 → Level 10 → rewards 5,10 granted', () async {
      await PlayerProgressionService.addXP(
        eventId: 'mil:1', amount: 600, source: 'test',
      );
      final profile = await PlayerProgressionService.loadProfile();
      expect(profile.levelRewardsGranted.contains(5), true);
      expect(profile.levelRewardsGranted.contains(10), true);
      final coins = (await SharedPreferences.getInstance()).getInt('total_coins') ?? 0;
      expect(coins, 30 + 50); // = 80
    });

    test('XP 5000 → rewards 5..25 granted', () async {
      await PlayerProgressionService.addXP(
        eventId: 'mil:2', amount: 5000, source: 'test',
      );
      final profile = await PlayerProgressionService.loadProfile();
      expect(profile.levelRewardsGranted.containsAll([5,10,15,20,25]), true);
    });
  });

  group('Transaction recovery', () {
    test('pending with XP written → recovers milestone', () async {
      final p = await SharedPreferences.getInstance();
      // شبیه‌سازی: XP نوشته شد ولی milestone اعمال نشد
      await p.setInt('player_xp_total', 600);
      await p.setString('pending_xp_transaction',
          'eventId=crash:1|xpBefore=0|xpAfter=600');
      await PlayerProgressionService.recoverPending();
      final profile = await PlayerProgressionService.loadProfile();
      expect(profile.levelRewardsGranted.contains(10), true);
      expect(profile.processedEvents.contains('crash:1'), true);
      expect(await p.getString('pending_xp_transaction'), null);
    });

    test('pending with XP not written → writes XP', () async {
      final p = await SharedPreferences.getInstance();
      await p.setInt('player_xp_total', 0);
      await p.setString('pending_xp_transaction',
          'eventId=crash:2|xpBefore=0|xpAfter=600');
      await PlayerProgressionService.recoverPending();
      expect(await p.getInt('player_xp_total'), 600);
    });

    test('unknown state → fail-safe, no double', () async {
      final p = await SharedPreferences.getInstance();
      await p.setInt('player_xp_total', 9999);
      await p.setString('pending_xp_transaction',
          'eventId=crash:3|xpBefore=0|xpAfter=600');
      await PlayerProgressionService.recoverPending();
      expect(await p.getInt('player_xp_total'), 9999); // بدون تغییر
    });
  });
}