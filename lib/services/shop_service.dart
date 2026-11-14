// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:marpech/models/level_reward.dart';
import 'package:shared_preferences/shared_preferences.dart';

// اضافه به importها
import '../models/level_cosmetics.dart';

enum ShopItemType {
  theme,
  snakeSkin,
  ghostSkin,
  foodSkin,
  trail,
  pattern,
  intro
}

class ShopItem {
  final String id;
  final ShopItemType type;
  final int price;
  final IconData icon;

  const ShopItem({
    required this.id,
    required this.type,
    required this.price,
    required this.icon,
  });

  String get name {
    switch (type) {
      case ShopItemType.theme:
        return 'theme_${id}_name';
      case ShopItemType.snakeSkin:
        return 'skin_snake_${id}_name';
      case ShopItemType.ghostSkin:
        return 'skin_ghost_${id}_name';
      case ShopItemType.foodSkin:
        return 'skin_food_${id}_name';
      case ShopItemType.trail:
        return 'skin_trail_${id}_name';
      case ShopItemType.pattern:
        return 'pattern_${id}_name';
      case ShopItemType.intro:
        return 'intro_${id}_name';
    }
  }
}

final List<ShopItem> allShopItems = [
  // 🎨 Themes
  const ShopItem(
      id: 'fire',
      type: ShopItemType.theme,
      price: 150,
      icon: Icons.local_fire_department_rounded),
  const ShopItem(
      id: 'forest',
      type: ShopItemType.theme,
      price: 150,
      icon: Icons.forest_rounded),
  const ShopItem(
      id: 'ice',
      type: ShopItemType.theme,
      price: 150,
      icon: Icons.ac_unit_rounded),
  const ShopItem(
      id: 'ocean',
      type: ShopItemType.theme,
      price: 180,
      icon: Icons.waves_rounded),
  const ShopItem(
      id: 'toxic',
      type: ShopItemType.theme,
      price: 180,
      icon: Icons.science_rounded),
  const ShopItem(
      id: 'cherry',
      type: ShopItemType.theme,
      price: 200,
      icon: Icons.local_florist_rounded),
  const ShopItem(
      id: 'midnight',
      type: ShopItemType.theme,
      price: 200,
      icon: Icons.nights_stay_rounded),
  const ShopItem(
      id: 'gold',
      type: ShopItemType.theme,
      price: 250,
      icon: Icons.workspace_premium_rounded),
  const ShopItem(
      id: 'portals',
      type: ShopItemType.theme,
      price: 220,
      icon: Icons.all_inclusive_rounded),
  const ShopItem(
      id: 'time',
      type: ShopItemType.theme,
      price: 250,
      icon: Icons.hourglass_top_rounded),

  // 🐍 Snake skins
  const ShopItem(
      id: 'fire',
      type: ShopItemType.snakeSkin,
      price: 200,
      icon: Icons.local_fire_department_rounded),
  const ShopItem(
      id: 'pixel',
      type: ShopItemType.snakeSkin,
      price: 200,
      icon: Icons.grid_view_rounded),
  const ShopItem(
      id: 'galaxy',
      type: ShopItemType.snakeSkin,
      price: 250,
      icon: Icons.auto_awesome_rounded),
  const ShopItem(
      id: 'rainbow',
      type: ShopItemType.snakeSkin,
      price: 280,
      icon: Icons.auto_awesome_rounded),
  const ShopItem(
      id: 'ice',
      type: ShopItemType.snakeSkin,
      price: 220,
      icon: Icons.ac_unit_rounded),
  const ShopItem(
      id: 'gold',
      type: ShopItemType.snakeSkin,
      price: 300,
      icon: Icons.workspace_premium_rounded),
  const ShopItem(
      id: 'neon',
      type: ShopItemType.snakeSkin,
      price: 240,
      icon: Icons.bolt_rounded),
  const ShopItem(
      id: 'shadow',
      type: ShopItemType.snakeSkin,
      price: 260,
      icon: Icons.dark_mode_rounded),

  // 👻 Ghost skins
  const ShopItem(
      id: 'golden',
      type: ShopItemType.ghostSkin,
      price: 300,
      icon: Icons.star_rounded),
  const ShopItem(
      id: 'dragon',
      type: ShopItemType.ghostSkin,
      price: 400,
      icon: Icons.whatshot_rounded),
  const ShopItem(
      id: 'spirit',
      type: ShopItemType.ghostSkin,
      price: 350,
      icon: Icons.water_drop_rounded),
  const ShopItem(
      id: 'rainbow',
      type: ShopItemType.ghostSkin,
      price: 350,
      icon: Icons.palette_rounded),
  const ShopItem(
      id: 'ice',
      type: ShopItemType.ghostSkin,
      price: 320,
      icon: Icons.ac_unit_rounded),
  const ShopItem(
      id: 'electric',
      type: ShopItemType.ghostSkin,
      price: 380,
      icon: Icons.bolt_rounded),
  const ShopItem(
      id: 'phantom',
      type: ShopItemType.ghostSkin,
      price: 400,
      icon: Icons.visibility_rounded),
  const ShopItem(
      id: 'blossom',
      type: ShopItemType.ghostSkin,
      price: 340,
      icon: Icons.local_florist_rounded),

  const ShopItem(
    id: 'ice',
    type: ShopItemType.trail,
    price: 220,
    icon: Icons.ac_unit_rounded,
  ),
  const ShopItem(
    id: 'electric',
    type: ShopItemType.trail,
    price: 230,
    icon: Icons.flash_on_rounded,
  ),
  const ShopItem(
    id: 'blossom',
    type: ShopItemType.trail,
    price: 210,
    icon: Icons.local_florist_rounded,
  ),
  const ShopItem(
    id: 'phantom',
    type: ShopItemType.trail,
    price: 240,
    icon: Icons.nightlight_round,
  ),
  const ShopItem(
    id: 'water',
    type: ShopItemType.trail,
    price: 200,
    icon: Icons.water_rounded,
  ),

  // 🍎 Food skins
  const ShopItem(
      id: 'pizza',
      type: ShopItemType.foodSkin,
      price: 100,
      icon: Icons.local_pizza_rounded),
  const ShopItem(
      id: 'burger',
      type: ShopItemType.foodSkin,
      price: 100,
      icon: Icons.lunch_dining_rounded),
  const ShopItem(
      id: 'donut',
      type: ShopItemType.foodSkin,
      price: 120,
      icon: Icons.donut_large_rounded),
  const ShopItem(
      id: 'grape',
      type: ShopItemType.foodSkin,
      price: 120,
      icon: Icons.bubble_chart_rounded),
  const ShopItem(
      id: 'star',
      type: ShopItemType.foodSkin,
      price: 150,
      icon: Icons.star_rounded),
  const ShopItem(
      id: 'cherry',
      type: ShopItemType.foodSkin,
      price: 150,
      icon: Icons.local_florist_rounded),
  const ShopItem(
      id: 'watermelon',
      type: ShopItemType.foodSkin,
      price: 180,
      icon: Icons.water_drop_rounded),

  // ✨ Trail effects
  const ShopItem(
      id: 'neon',
      type: ShopItemType.trail,
      price: 180,
      icon: Icons.blur_on_rounded),
  const ShopItem(
      id: 'fire',
      type: ShopItemType.trail,
      price: 200,
      icon: Icons.local_fire_department_rounded),
  const ShopItem(
      id: 'stars',
      type: ShopItemType.trail,
      price: 220,
      icon: Icons.auto_awesome_rounded),
  const ShopItem(
      id: 'smoke',
      type: ShopItemType.trail,
      price: 160,
      icon: Icons.cloud_rounded),

  const ShopItem(
      id: 'rainbow',
      type: ShopItemType.trail,
      price: 250,
      icon: Icons.gradient_rounded),

  // 🎨 Board patterns
  const ShopItem(
      id: 'checkerboard',
      type: ShopItemType.pattern,
      price: 100,
      icon: Icons.grid_4x4_rounded),
  const ShopItem(
      id: 'grid_plus',
      type: ShopItemType.pattern,
      price: 100,
      icon: Icons.grid_on_rounded),
  const ShopItem(
      id: 'stars',
      type: ShopItemType.pattern,
      price: 120,
      icon: Icons.star_rounded),
  const ShopItem(
      id: 'petals',
      type: ShopItemType.pattern,
      price: 130,
      icon: Icons.local_florist_rounded),
  const ShopItem(
      id: 'spiral',
      type: ShopItemType.pattern,
      price: 140,
      icon: Icons.rotate_right_rounded),
  const ShopItem(
      id: 'waves',
      type: ShopItemType.pattern,
      price: 150,
      icon: Icons.waves_rounded),
  const ShopItem(
      id: 'crystal',
      type: ShopItemType.pattern,
      price: 160,
      icon: Icons.diamond_rounded),
  const ShopItem(
      id: 'galaxy',
      type: ShopItemType.pattern,
      price: 170,
      icon: Icons.nights_stay_rounded),

  // 🎬 Intro animations
  const ShopItem(
    id: 'rocket',
    type: ShopItemType.intro,
    price: 100,
    icon: Icons.rocket_launch_rounded,
  ),
  const ShopItem(
    id: 'portal',
    type: ShopItemType.intro,
    price: 120,
    icon: Icons.blur_circular_rounded,
  ),
  const ShopItem(
    id: 'lightning',
    type: ShopItemType.intro,
    price: 140,
    icon: Icons.flash_on_rounded,
  ),
  const ShopItem(
    id: 'sparkle',
    type: ShopItemType.intro,
    price: 150,
    icon: Icons.auto_awesome_rounded,
  ),
  const ShopItem(
    id: 'comet',
    type: ShopItemType.intro,
    price: 130,
    icon: Icons.nightlight_round,
  ),
  const ShopItem(
    id: 'tornado',
    type: ShopItemType.intro,
    price: 140,
    icon: Icons.cyclone_rounded,
  ),
  const ShopItem(
    id: 'explosion',
    type: ShopItemType.intro,
    price: 150,
    icon: Icons.brightness_7_rounded,
  ),
  const ShopItem(
    id: 'crystal',
    type: ShopItemType.intro,
    price: 160,
    icon: Icons.diamond_rounded,
  ),
];

class ShopService {
  static const _unlockedThemesKey = 'shop_themes';
  static const _unlockedSnakeSkinsKey = 'shop_snake_skins';
  static const _unlockedGhostSkinsKey = 'shop_ghost_skins';
  static const _unlockedFoodSkinsKey = 'shop_food_skins';
  static const _unlockedTrailsKey = 'shop_trails';
  static const _selectedSnakeSkinKey = 'selected_snake_skin';
  static const _selectedGhostSkinKey = 'selected_ghost_skin';
  static const _selectedFoodSkinKey = 'selected_food_skin';
  static const _selectedTrailKey = 'selected_trail';
  static const _coinsKey = 'total_coins';
  static const _unlockedPatternsKey = 'shop_patterns';
  static const _selectedPatternKey = 'selected_pattern';
  static const _patternIntensityKey = 'pattern_intensity';
  static const _unlockedIntrosKey = 'shop_intros';
  static const _selectedIntroKey = 'selected_intro';

  static const _freeThemes = {'neon', 'sunset', 'cyber'};

  // ---------- Coins ----------

  static Future<int> getCoins() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_coinsKey) ?? 0;
  }

  static Future<void> _setCoins(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_coinsKey, v);
  }

  /// 🧪 فقط برای تست — اضافه کردن سکه
  static Future<void> addCoins(int amount) async {
    final coins = await getCoins();
    await _setCoins(coins + amount);
  }

  /// 🪙 خرج کردن سکه — true اگه موفق
  static Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_coinsKey) ?? 0;
    if (current < amount) return false;
    await p.setInt(_coinsKey, current - amount);
    return true;
  }

  // ---------- Themes ----------

  static Future<Set<String>> getUnlockedThemes() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedThemesKey) ?? [];
    return {..._freeThemes, ...list};
  }

  static Future<bool> isThemeUnlocked(String id) async {
    if (_freeThemes.contains(id)) return true;
    return (await getUnlockedThemes()).contains(id);
  }

  // ---------- Snake skins ----------

  static Future<Set<String>> getUnlockedSnakeSkins() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedSnakeSkinsKey) ?? [];
    return {'basic', ...list};
  }

  static Future<bool> isSnakeSkinUnlocked(String id) async {
    if (id == 'basic') return true;
    return (await getUnlockedSnakeSkins()).contains(id);
  }

  static Future<String> getSelectedSnakeSkin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_selectedSnakeSkinKey) ?? 'basic';
  }

  static Future<void> setSelectedSnakeSkin(String id) async {
    // Stage 3: فقط آیتم‌های مالکیت‌شده قابل انتخاب‌اند
    if (!await isSnakeSkinUnlocked(id)) {
      final lc = levelCosmeticById(id);
      if (lc == null || lc.category != CosmeticCategory.snakeSkin) return;
      if (!await isLevelCosmeticOwned(id)) return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_selectedSnakeSkinKey, id);
  }

  // ---------- Ghost skins ----------

  static Future<Set<String>> getUnlockedGhostSkins() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedGhostSkinsKey) ?? [];
    return {'basic', ...list};
  }

  static Future<bool> isGhostSkinUnlocked(String id) async {
    if (id == 'basic') return true;
    return (await getUnlockedGhostSkins()).contains(id);
  }

  static Future<String> getSelectedGhostSkin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_selectedGhostSkinKey) ?? 'basic';
  }

  static Future<void> setSelectedGhostSkin(String id) async {
    if (!await isGhostSkinUnlocked(id)) {
      final lc = levelCosmeticById(id);
      if (lc == null || lc.category != CosmeticCategory.ghostSkin) return;
      if (!await isLevelCosmeticOwned(id)) return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_selectedGhostSkinKey, id);
  }

  // ---------- Food skins ----------

  static Future<Set<String>> getUnlockedFoodSkins() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedFoodSkinsKey) ?? [];
    return {'basic', ...list};
  }

  static Future<bool> isFoodSkinUnlocked(String id) async {
    if (id == 'basic') return true;
    return (await getUnlockedFoodSkins()).contains(id);
  }

  static Future<String> getSelectedFoodSkin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_selectedFoodSkinKey) ?? 'basic';
  }

  static Future<void> setSelectedFoodSkin(String id) async {
    if (!await isFoodSkinUnlocked(id)) {
      final lc = levelCosmeticById(id);
      if (lc == null || lc.category != CosmeticCategory.foodSkin) return;
      if (!await isLevelCosmeticOwned(id)) return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_selectedFoodSkinKey, id);
  }

  // ---------- Trail effects ----------

  static Future<Set<String>> getUnlockedTrails() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedTrailsKey) ?? [];
    return {'none', ...list};
  }

  static Future<bool> isTrailUnlocked(String id) async {
    if (id == 'none') return true;
    return (await getUnlockedTrails()).contains(id);
  }

  static Future<String> getSelectedTrail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_selectedTrailKey) ?? 'none';
  }

  static Future<void> setSelectedTrail(String id) async {
    if (!await isTrailUnlocked(id)) {
      final lc = levelCosmeticById(id);
      if (lc == null || lc.category != CosmeticCategory.trail) return;
      if (!await isLevelCosmeticOwned(id)) return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_selectedTrailKey, id);
  }

  // ---------- Purchase ----------

  static Future<bool> isOwned(ShopItem item) async {
    // Stage 3: Level-Exclusive ابتدا
    if (await isLevelCosmeticOwned(item.id)) return true;

    switch (item.type) {
      case ShopItemType.theme:
        return isThemeUnlocked(item.id);
      case ShopItemType.snakeSkin:
        return isSnakeSkinUnlocked(item.id);
      case ShopItemType.ghostSkin:
        return isGhostSkinUnlocked(item.id);
      case ShopItemType.foodSkin:
        return isFoodSkinUnlocked(item.id);
      case ShopItemType.trail:
        return isTrailUnlocked(item.id);
      case ShopItemType.pattern:
        return isPatternUnlocked(item.id);
      case ShopItemType.intro:
        return isIntroUnlocked(item.id);
    }
  }

  // ---------- Board Patterns ----------

  static Future<Set<String>> getUnlockedPatterns() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedPatternsKey) ?? [];
    return {'none', ...list};
  }

  static Future<bool> isPatternUnlocked(String id) async {
    if (id == 'none') return true;
    return (await getUnlockedPatterns()).contains(id);
  }

  static Future<String> getSelectedPattern() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_selectedPatternKey) ?? 'none';
  }

  static Future<void> setSelectedPattern(String id) async {
    if (!await isPatternUnlocked(id)) {
      final lc = levelCosmeticById(id);
      if (lc == null || lc.category != CosmeticCategory.pattern) return;
      if (!await isLevelCosmeticOwned(id)) return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_selectedPatternKey, id);
  }

  static Future<String> getPatternIntensity() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_patternIntensityKey) ?? 'subtle';
  }

  static Future<void> setPatternIntensity(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_patternIntensityKey, id);
  }

  // ---------- Intro Animations ----------

  static Future<Set<String>> getUnlockedIntros() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_unlockedIntrosKey) ?? [];
    return {'none', ...list};
  }

  static Future<bool> isIntroUnlocked(String id) async {
    if (id == 'none') return true;
    return (await getUnlockedIntros()).contains(id);
  }

  static Future<String> getSelectedIntro() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_selectedIntroKey) ?? 'none';
  }

  static Future<void> setSelectedIntro(String id) async {
    if (!await isIntroUnlocked(id)) {
      final lc = levelCosmeticById(id);
      if (lc == null || lc.category != CosmeticCategory.intro) return;
      if (!await isLevelCosmeticOwned(id)) return;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_selectedIntroKey, id);
  }

  static Future<bool> purchase(ShopItem item) async {
    // ── Stage 3: آیتم‌های Level-Exclusive هرگز با سکه خریداری نمی‌شوند ──
    if (isLevelCosmeticId(item.id)) return false;

    if (await isOwned(item)) return false;
    final coins = await getCoins();
    if (coins < item.price) return false;
    // ... (بقیه دقیقاً مثل قبل — بدون تغییر)

    await _setCoins(coins - item.price);

    final p = await SharedPreferences.getInstance();
    switch (item.type) {
      case ShopItemType.theme:
        final list = p.getStringList(_unlockedThemesKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedThemesKey, list);
        break;
      case ShopItemType.snakeSkin:
        final list = p.getStringList(_unlockedSnakeSkinsKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedSnakeSkinsKey, list);
        break;
      case ShopItemType.ghostSkin:
        final list = p.getStringList(_unlockedGhostSkinsKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedGhostSkinsKey, list);
        break;
      case ShopItemType.foodSkin:
        final list = p.getStringList(_unlockedFoodSkinsKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedFoodSkinsKey, list);
        break;
      case ShopItemType.trail:
        final list = p.getStringList(_unlockedTrailsKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedTrailsKey, list);
        break;
      case ShopItemType.pattern:
        final list = p.getStringList(_unlockedPatternsKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedPatternsKey, list);
        break;

      case ShopItemType.intro:
        final list = p.getStringList(_unlockedIntrosKey) ?? [];
        if (!list.contains(item.id)) list.add(item.id);
        await p.setStringList(_unlockedIntrosKey, list);
        break;
    }
    return true;
  }

  // ---------- Level-Exclusive Cosmetics (Stage 3) ----------

  /// بررسی یکپارچه مالکیت با ID رشتهای
  /// ابتدا Level Cosmetic، سپس آیتمهای رایگان، سپس آیتمهای خریداریشده
  static Future<bool> isAnyOwned(String id) async {
    // Level-Exclusive
    if (await isLevelCosmeticOwned(id)) return true;

    // آیتمهای رایگان
    if (_freeThemes.contains(id)) return true;
    if (id == 'basic' || id == 'none') return true;

    // آیتمهای خریداریشده
    final p = await SharedPreferences.getInstance();
    if ((p.getStringList(_unlockedThemesKey) ?? []).contains(id)) return true;
    if ((p.getStringList(_unlockedSnakeSkinsKey) ?? []).contains(id))
      return true;
    if ((p.getStringList(_unlockedGhostSkinsKey) ?? []).contains(id))
      return true;
    if ((p.getStringList(_unlockedFoodSkinsKey) ?? []).contains(id))
      return true;
    if ((p.getStringList(_unlockedTrailsKey) ?? []).contains(id)) return true;
    if ((p.getStringList(_unlockedPatternsKey) ?? []).contains(id)) return true;
    if ((p.getStringList(_unlockedIntrosKey) ?? []).contains(id)) return true;
    return false;
  }

  // ---------- Level-Exclusive Cosmetics (Stage 3) ----------

  static Future<bool> isLevelCosmeticOwned(String id) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('level_owned_cosmetics') ?? []).contains(id);
  }
}
