import 'package:material_ui/material_ui.dart';
import 'level_reward.dart';

/// مدل یک آیتم Cosmetic مخصوص سطح — فقط با رسیدن به سطح باز می‌شود
class LevelCosmetic {
  final String id;
  final int requiredLevel;
  final CosmeticCategory category;
  final IconData icon;
  final Color color;
  final String nameKey;
  final String descKey;

  const LevelCosmetic({
    required this.id,
    required this.requiredLevel,
    required this.category,
    required this.icon,
    required this.color,
    required this.nameKey,
    required this.descKey,
  });
}

/// ۹ آیتم Level-Exclusive — دقیقاً منطبق با cosmeticIdها در allLevelRewards
const List<LevelCosmetic> allLevelCosmetics = [
  LevelCosmetic(
    id: 'bronze_trail',
    requiredLevel: 20,
    category: CosmeticCategory.trail,
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFFCD7F32),
    nameKey: 'skin_trail_bronze_trail_name',
    descKey: 'skin_trail_bronze_trail_desc',
  ),
  LevelCosmetic(
    id: 'champion_theme',
    requiredLevel: 30,
    category: CosmeticCategory.theme,
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFFB300),
    nameKey: 'palette_champion_theme_name',
    descKey: 'palette_champion_theme_desc',
  ),
  LevelCosmetic(
    id: 'veteran_snake_skin',
    requiredLevel: 40,
    category: CosmeticCategory.snakeSkin,
    icon: Icons.military_tech_rounded,
    color: Color(0xFF6B8E23),
    nameKey: 'skin_snake_veteran_snake_skin_name',
    descKey: 'skin_snake_veteran_snake_skin_desc',
  ),
  LevelCosmetic(
    id: 'elite_ghost_skin',
    requiredLevel: 50,
    category: CosmeticCategory.ghostSkin,
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF7C4DFF),
    nameKey: 'skin_ghost_elite_ghost_skin_name',
    descKey: 'skin_ghost_elite_ghost_skin_desc',
  ),
  LevelCosmetic(
    id: 'golden_trophy_food',
    requiredLevel: 60,
    category: CosmeticCategory.foodSkin,
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFFFFD700),
    nameKey: 'skin_food_golden_trophy_food_name',
    descKey: 'skin_food_golden_trophy_food_desc',
  ),
  LevelCosmetic(
    id: 'legend_pattern',
    requiredLevel: 70,
    category: CosmeticCategory.pattern,
    icon: Icons.auto_awesome_mosaic_rounded,
    color: Color(0xFFFF6B35),
    nameKey: 'pattern_legend_pattern_name',
    descKey: 'pattern_legend_pattern_desc',
  ),
  LevelCosmetic(
    id: 'champion_intro',
    requiredLevel: 80,
    category: CosmeticCategory.intro,
    icon: Icons.stars_rounded,
    color: Color(0xFFFFB300),
    nameKey: 'intro_champion_intro_name',
    descKey: 'intro_champion_intro_desc',
  ),
  LevelCosmetic(
    id: 'mythic_trail',
    requiredLevel: 90,
    category: CosmeticCategory.trail,
    icon: Icons.flare_rounded,
    color: Color(0xFFFF00E5),
    nameKey: 'skin_trail_mythic_trail_name',
    descKey: 'skin_trail_mythic_trail_desc',
  ),
  LevelCosmetic(
    id: 'marpech_legend_theme',
    requiredLevel: 100,
    category: CosmeticCategory.theme,
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFF00E5),
    nameKey: 'palette_marpech_legend_theme_name',
    descKey: 'palette_marpech_legend_theme_desc',
  ),
];

LevelCosmetic? levelCosmeticById(String id) {
  for (final c in allLevelCosmetics) {
    if (c.id == id) return c;
  }
  return null;
}

bool isLevelCosmeticId(String id) => levelCosmeticById(id) != null;

Set<String> get allLevelCosmeticIds =>
    allLevelCosmetics.map((c) => c.id).toSet();