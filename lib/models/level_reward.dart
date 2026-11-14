enum CosmeticCategory { theme, snakeSkin, ghostSkin, foodSkin, trail, pattern, intro }

class LevelReward {
  final int level;
  final int coins;
  final String? cosmeticId;
  final CosmeticCategory? cosmeticCategory;

  const LevelReward({
    required this.level,
    required this.coins,
    this.cosmeticId,
    this.cosmeticCategory,
  });

  bool get hasCosmetic => cosmeticId != null;

  Map<String, dynamic> toJson() => {
        'level': level,
        'coins': coins,
        'cosmeticId': cosmeticId,
        'cosmeticCategory': cosmeticCategory?.name,
      };
}

/// ۱۶ milestone سطح — بدون تغییر از طرح تأییدشده
const List<LevelReward> allLevelRewards = [
  LevelReward(level: 5, coins: 30),
  LevelReward(level: 10, coins: 50),
  LevelReward(level: 15, coins: 75),
  LevelReward(level: 20, coins: 75,
      cosmeticId: 'bronze_trail', cosmeticCategory: CosmeticCategory.trail),
  LevelReward(level: 25, coins: 100),
  LevelReward(level: 30, coins: 100,
      cosmeticId: 'champion_theme', cosmeticCategory: CosmeticCategory.theme),
  LevelReward(level: 35, coins: 125),
  LevelReward(level: 40, coins: 150,
      cosmeticId: 'veteran_snake_skin',
      cosmeticCategory: CosmeticCategory.snakeSkin),
  LevelReward(level: 45, coins: 175),
  LevelReward(level: 50, coins: 200,
      cosmeticId: 'elite_ghost_skin',
      cosmeticCategory: CosmeticCategory.ghostSkin),
  LevelReward(level: 60, coins: 250,
      cosmeticId: 'golden_trophy_food',
      cosmeticCategory: CosmeticCategory.foodSkin),
  LevelReward(level: 70, coins: 300,
      cosmeticId: 'legend_pattern',
      cosmeticCategory: CosmeticCategory.pattern),
  LevelReward(level: 80, coins: 400,
      cosmeticId: 'champion_intro',
      cosmeticCategory: CosmeticCategory.intro),
  LevelReward(level: 90, coins: 500,
      cosmeticId: 'mythic_trail',
      cosmeticCategory: CosmeticCategory.trail),
  LevelReward(level: 95, coins: 600),
  LevelReward(level: 100, coins: 1500,
      cosmeticId: 'marpech_legend_theme',
      cosmeticCategory: CosmeticCategory.theme),
];

LevelReward? rewardForLevel(int level) {
  for (final r in allLevelRewards) {
    if (r.level == level) return r;
  }
  return null;
}