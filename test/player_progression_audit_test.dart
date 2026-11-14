// ignore_for_file: await_only_futures

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/services/player_progression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  // ── ۱. idempotency ──
  test('same eventId called twice → XP granted once', () async {
    final r1 = await PlayerProgressionService.addXP(
      eventId: 'test:a',
      amount: 100,
      source: 'test',
    );
    final r2 = await PlayerProgressionService.addXP(
      eventId: 'test:a',
      amount: 100,
      source: 'test',
    );
    expect(r1.xpGained, 100);
    expect(r1.wasDuplicate, false);
    expect(r2.xpGained, 0);
    expect(r2.wasDuplicate, true);

    final profile = await PlayerProgressionService.loadProfile();
    expect(profile.xpTotal, 100);
  });

  // ── ۲. eventIds independent ──
  test('two eventIds → independent', () async {
    await PlayerProgressionService.addXP(
      eventId: 'test:a',
      amount: 50,
      source: 'test',
    );
    await PlayerProgressionService.addXP(
      eventId: 'test:b',
      amount: 70,
      source: 'test',
    );
    final p = await PlayerProgressionService.loadProfile();
    expect(p.xpTotal, 120);
    expect(p.processedEvents, containsAll(['test:a', 'test:b']));
  });

  // ── ۵. serialized transactions ──
  test('concurrent addXP → serialized correctly', () async {
    final futures = List.generate(
      10,
      (i) => PlayerProgressionService.addXP(
        eventId: 'concurrent:$i',
        amount: 10,
        source: 'test',
      ),
    );
    await Future.wait(futures);
    final p = await PlayerProgressionService.loadProfile();
    expect(p.xpTotal, 100);
    expect(p.processedEvents.length, 10);
  });

  // ── ۶. multi-level-up + milestones ──
  test('5000 XP → level 27, all milestones 5..25', () async {
    await PlayerProgressionService.addXP(
      eventId: 'big:1',
      amount: 5000,
      source: 'test',
    );
    final p = await PlayerProgressionService.loadProfile();
    expect(PlayerProgressionService.levelFromXp(p.xpTotal), 27);
    expect(p.levelRewardsGranted.containsAll([5, 10, 15, 20, 25]), true);
  });

  // ── ۸. pending recovery ──
  test('recovery: XP written, milestone not → recovers', () async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('player_xp_total', 600);
    await p.setString('pending_xp_transaction',
        'eventId=crash:1|xpBefore=0|xpAfter=600|source=test');
    await PlayerProgressionService.recoverPending();

    final profile = await PlayerProgressionService.loadProfile();
    expect(profile.xpTotal, 600);
    expect(profile.levelRewardsGranted.contains(5), true);
    expect(profile.levelRewardsGranted.contains(10), true);
    expect(profile.processedEvents.contains('crash:1'), true);
    expect(await p.getString('pending_xp_transaction'), null);
  });

  // ── ۹. milestone duplicate recovery ──
  test('recovery twice → no double coins', () async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('player_xp_total', 600);
    await p.setString('pending_xp_transaction',
        'eventId=crash:2|xpBefore=0|xpAfter=600|source=test');
    await PlayerProgressionService.recoverPending();
    final coins1 = p.getInt('total_coins') ?? 0;

    await PlayerProgressionService.recoverPending();
    final coins2 = p.getInt('total_coins') ?? 0;

    expect(coins1, coins2); // بدون تغییر
    expect(coins1, 80); // 30 + 50
  });

  // ── ۱۰. L100 cap + overflow ──
  test('XP beyond L100 stored, level capped', () async {
    await PlayerProgressionService.addXP(
      eventId: 'cap:1',
      amount: 100000,
      source: 'test',
    );
    final p = await PlayerProgressionService.loadProfile();
    expect(p.xpTotal, 100000);
    expect(PlayerProgressionService.levelFromXp(p.xpTotal), 100);
    expect(PlayerProgressionService.progress(p.xpTotal), 1.0);
  });

  test('exactly at L100 threshold', () async {
    await PlayerProgressionService.addXP(
      eventId: 'cap:2',
      amount: 99735,
      source: 'test',
    );
    final p = await PlayerProgressionService.loadProfile();
    expect(PlayerProgressionService.levelFromXp(p.xpTotal), 100);
    expect(PlayerProgressionService.progress(p.xpTotal), 1.0);
  });

  // ── ۲. milestone sum ──
  test('total milestone coins = 4630', () async {
    final p = await SharedPreferences.getInstance();
    // XP کافی برای L100
    await PlayerProgressionService.addXP(
      eventId: 'all:1',
      amount: 99735,
      source: 'test',
    );
    final coins = p.getInt('total_coins') ?? 0;
    expect(coins, 4630);
  });
}
