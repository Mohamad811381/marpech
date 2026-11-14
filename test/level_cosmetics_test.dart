// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/level_cosmetics.dart';
import 'package:marpech/models/level_reward.dart';
import 'package:marpech/services/shop_service.dart';
import 'package:marpech/services/storage_service.dart';
import 'package:marpech/services/player_progression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  // ─── 1. Registry ───
  group('Registry', () {
    test('exactly 9 cosmetics', () {
      expect(allLevelCosmetics.length, 9);
    });
    test('all IDs unique', () {
      final ids = allLevelCosmetics.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
    test('IDs match level_reward exactly', () {
      final rewardIds = allLevelRewards
          .where((r) => r.hasCosmetic)
          .map((r) => r.cosmeticId!)
          .toSet();
      expect(allLevelCosmeticIds, rewardIds);
    });
  });

  // ─── 2. Required levels ───
  group('Required levels', () {
    const expected = {
      'bronze_trail': 20,
      'champion_theme': 30,
      'veteran_snake_skin': 40,
      'elite_ghost_skin': 50,
      'golden_trophy_food': 60,
      'legend_pattern': 70,
      'champion_intro': 80,
      'mythic_trail': 90,
      'marpech_legend_theme': 100,
    };
    for (final e in expected.entries) {
      test('${e.key} → L${e.value}', () {
        expect(levelCosmeticById(e.key)?.requiredLevel, e.value);
      });
    }
  });

  // ─── 3. Shop isolation ───
  group('Shop isolation', () {
    test('no level cosmetic in allShopItems', () {
      for (final c in allLevelCosmetics) {
        expect(allShopItems.any((s) => s.id == c.id), false,
            reason: '${c.id} نباید در فروشگاه باشد');
      }
    });
  });

  // ─── 4. Locked not owned ───
  group('Locked not owned', () {
    test('fresh state → all not owned', () async {
      for (final c in allLevelCosmetics) {
        expect(await ShopService.isAnyOwned(c.id), false,
            reason: '${c.id} نباید در حالت اولیه owned باشد');
      }
    });
  });

  // ─── 5. Unlock at exact level ───
  group('Unlock at exact level', () {
    for (final c in allLevelCosmetics) {
      test('${c.id} unlocks at L${c.requiredLevel}', () async {
        final xp = PlayerProgressionService.cumulativeXP(c.requiredLevel);
        await PlayerProgressionService.addXP(
          eventId: 'test:unlock_${c.id}',
          amount: xp,
          source: 'test',
        );
        expect(await ShopService.isAnyOwned(c.id), true,
            reason: '${c.id} باید در L${c.requiredLevel} آزاد شود');
      });
    }
  });

  // ─── 6. Purchased shop items remain owned ───
  group('Purchased items still owned', () {
    test('buy fire snake skin', () async {
      await ShopService.addCoins(10000);
      final item = allShopItems.firstWhere(
          (s) => s.id == 'fire' && s.type == ShopItemType.snakeSkin);
      expect(await ShopService.purchase(item), true);
      expect(await ShopService.isAnyOwned('fire'), true);
    });
  });

  // ─── 7. Persistence across restart ───
  group('Persistence across restart', () {
    test('level unlock persists in prefs', () async {
      final xp = PlayerProgressionService.cumulativeXP(20);
      await PlayerProgressionService.addXP(
          eventId: 'test:persist', amount: xp, source: 'test');
      final stored = await StorageService.getLevelOwnedCosmetics();
      expect(stored.contains('bronze_trail'), true);
    });
    test('purchased shop item persists', () async {
      await ShopService.addCoins(10000);
      final item = allShopItems.firstWhere(
          (s) => s.id == 'galaxy' && s.type == ShopItemType.snakeSkin);
      await ShopService.purchase(item);
      expect(await ShopService.isSnakeSkinUnlocked('galaxy'), true);
    });
  });

  // ─── 8. Purchase protection ───
  group('Purchase protection', () {
    test('level cosmetic id rejected even if manually passed', () async {
      await ShopService.addCoins(10000);
      final before = await ShopService.getCoins();
      final fake = ShopItem(
        id: 'bronze_trail',
        type: ShopItemType.trail,
        price: 100,
        icon: Icons.lock_rounded,
      );
      final result = await ShopService.purchase(fake);
      expect(result, false);
      expect(await ShopService.getCoins(), before);
      expect(await ShopService.isLevelCosmeticOwned('bronze_trail'), false);
    });
  });

  // ─── 9. Locked selection prevented (REAL selection logic) ───
  group('Locked selection prevented', () {
    test('setSelectedSnakeSkin locked → no change', () async {
      await ShopService.setSelectedSnakeSkin('basic');
      await ShopService.setSelectedSnakeSkin('veteran_snake_skin');
      expect(await ShopService.getSelectedSnakeSkin(), 'basic');
    });
    test('setSelectedGhostSkin locked → no change', () async {
      await ShopService.setSelectedGhostSkin('basic');
      await ShopService.setSelectedGhostSkin('elite_ghost_skin');
      expect(await ShopService.getSelectedGhostSkin(), 'basic');
    });
    test('setSelectedTrail locked → no change', () async {
      await ShopService.setSelectedTrail('none');
      await ShopService.setSelectedTrail('bronze_trail');
      expect(await ShopService.getSelectedTrail(), 'none');
    });
    test('setSelectedPattern locked → no change', () async {
      await ShopService.setSelectedPattern('none');
      await ShopService.setSelectedPattern('legend_pattern');
      expect(await ShopService.getSelectedPattern(), 'none');
    });
    test('setSelectedIntro locked → no change', () async {
      await ShopService.setSelectedIntro('none');
      await ShopService.setSelectedIntro('champion_intro');
      expect(await ShopService.getSelectedIntro(), 'none');
    });
    test('setSelectedFoodSkin locked → no change', () async {
      await ShopService.setSelectedFoodSkin('basic');
      await ShopService.setSelectedFoodSkin('golden_trophy_food');
      expect(await ShopService.getSelectedFoodSkin(), 'basic');
    });
  });

  // ─── 10. Owned selection works ───
  group('Owned selection works', () {
    test('after L40 unlock, veteran skin selectable', () async {
      final xp = PlayerProgressionService.cumulativeXP(40);
      await PlayerProgressionService.addXP(
          eventId: 'test:sel40', amount: xp, source: 'test');
      await ShopService.setSelectedSnakeSkin('veteran_snake_skin');
      expect(await ShopService.getSelectedSnakeSkin(), 'veteran_snake_skin');
    });
    test('selected persists across restart', () async {
      final xp = PlayerProgressionService.cumulativeXP(20);
      await PlayerProgressionService.addXP(
          eventId: 'test:selP', amount: xp, source: 'test');
      await ShopService.setSelectedTrail('bronze_trail');
      expect(await ShopService.getSelectedTrail(), 'bronze_trail');
    });
  });

  // ─── 11. Existing shop behavior intact ───
  group('Existing shop behavior intact', () {
    test('buy and select existing skin', () async {
      await ShopService.addCoins(10000);
      final item = allShopItems.firstWhere(
          (s) => s.id == 'ice' && s.type == ShopItemType.snakeSkin);
      expect(await ShopService.purchase(item), true);
      await ShopService.setSelectedSnakeSkin('ice');
      expect(await ShopService.getSelectedSnakeSkin(), 'ice');
    });
    test('free basic skin selectable', () async {
      await ShopService.setSelectedSnakeSkin('basic');
      expect(await ShopService.getSelectedSnakeSkin(), 'basic');
    });
  });

  // ─── 12. Unified ownership ───
  group('Unified ownership', () {
    test('isAnyOwned false for locked level', () async {
      expect(await ShopService.isAnyOwned('champion_theme'), false);
    });
    test('isAnyOwned true for free item', () async {
      expect(await ShopService.isAnyOwned('neon'), true);
    });
    test('isAnyOwned false for unowned shop item', () async {
      expect(await ShopService.isAnyOwned('galaxy'), false);
    });
    test('isAnyOwned true for purchased item', () async {
      await ShopService.addCoins(10000);
      final item = allShopItems.firstWhere(
          (s) => s.id == 'galaxy' && s.type == ShopItemType.snakeSkin);
      await ShopService.purchase(item);
      expect(await ShopService.isAnyOwned('galaxy'), true);
    });
  });
}