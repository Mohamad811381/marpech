// ignore_for_file: prefer_const_declarations, deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:marpech/models/board_pattern.dart';
import '../models/game_palette.dart';
import '../models/skins.dart';
import '../services/localization_service.dart';
import '../services/shop_service.dart';
import 'board_painter.dart';
import '../services/performance_service.dart';

/// رنگ پیش‌نمایش هر آیتم — برای استفاده در کارت و بنر
Color previewColorFor(ShopItem item, GamePalette palette) {
  switch (item.type) {
    case ShopItemType.theme:
      switch (item.id) {
        case 'fire':
          return const Color(0xFFFF6600);
        case 'forest':
          return const Color(0xFF2ECC71);
        case 'ice':
          return const Color(0xFF4FC3F7);
        case 'ocean':
          return const Color(0xFF00BCD4);
        case 'toxic':
          return const Color(0xFF76FF03);
        case 'cherry':
          return const Color(0xFFFF4081);
        case 'midnight':
          return const Color(0xFF7C4DFF);
        case 'gold':
          return const Color(0xFFFFD700);
        case 'portals':
          return const Color(0xFF7C4DFF);
        case 'time':
          return const Color(0xFFFF3D3D);
        default:
          return palette.accent;
      }
    case ShopItemType.snakeSkin:
      switch (item.id) {
        case 'fire':
          return const Color(0xFFFF8800);
        case 'pixel':
          return const Color(0xFF00F0FF);
        case 'galaxy':
          return const Color(0xFF6A2FFF);
        case 'rainbow':
          return const Color(0xFFFF4081);
        case 'ice':
          return const Color(0xFF4FC3F7);
        case 'gold':
          return const Color(0xFFFFD700);
        case 'neon':
          return const Color(0xFFFF1493);
        case 'shadow':
          return const Color(0xFF9C27B0);
        default:
          return palette.accent;
      }
    case ShopItemType.ghostSkin:
      switch (item.id) {
        case 'golden':
          return const Color(0xFFFFD700);
        case 'dragon':
          return const Color(0xFFFF4400);
        case 'spirit':
          return const Color(0xFF80E0FF);
        case 'rainbow':
          return const Color(0xFFFF4081);
        case 'ice':
          return const Color(0xFF4FC3F7);
        case 'electric':
          return const Color(0xFFFFEB3B);
        case 'phantom':
          return const Color(0xFF9C27B0);
        case 'blossom':
          return const Color(0xFFFFB6E0);
        default:
          return Colors.white;
      }
    case ShopItemType.foodSkin:
      switch (item.id) {
        case 'pizza':
          return const Color(0xFFFF9800);
        case 'burger':
          return const Color(0xFF8D6E63);
        case 'donut':
          return const Color(0xFFEC407A);
        case 'grape':
          return const Color(0xFF9C27B0);
        case 'star':
          return const Color(0xFFFFD700);
        case 'cherry':
          return const Color(0xFFD32F2F);
        case 'watermelon':
          return const Color(0xFF4CAF50);

        default:
          return palette.food;
      }
    case ShopItemType.trail:
      switch (item.id) {
        case 'neon':
          return const Color(0xFF00E5FF);
        case 'fire':
          return const Color(0xFFFF6600);
        case 'stars':
          return const Color(0xFFFFD700);
        case 'smoke':
          return const Color(0xFF9E9E9E);
        case 'rainbow':
          return const Color(0xFFFF4081);
        case 'ice':
          return const Color(0xFF4FC3F7);
        case 'electric':
          return const Color(0xFFFFEB3B);
        case 'blossom':
          return const Color(0xFFFF8FB3);
        case 'phantom':
          return const Color(0xFF9C27B0);
        case 'water':
          return const Color(0xFF00BCD4);
        default:
          return palette.accent;
      }

    case ShopItemType.pattern:
      switch (item.id) {
        case 'galaxy':
          return const Color(0xFF7C4DFF);
        case 'spiral':
          return const Color(0xFF00E5FF);
        case 'stars':
          return const Color(0xFFFFD700);
        case 'checkerboard':
          return const Color(0xFF9E9E9E);
        case 'grid_plus':
          return const Color(0xFF4CAF50);
        case 'waves':
          return const Color(0xFF00BCD4);
        case 'crystal':
          return const Color(0xFFE1F5FE);
        case 'petals':
          return const Color(0xFFFF8FB3);
        default:
          return palette.accent;
      }

    case ShopItemType.intro:
      switch (item.id) {
        case 'rocket':
          return const Color(0xFFFF6B35);
        case 'portal':
          return const Color(0xFF7C4DFF);
        case 'lightning':
          return const Color(0xFFFFEB3B);
        case 'sparkle':
          return const Color(0xFFFFD700);
        case 'comet':
          return const Color(0xFF00E5FF);
        case 'tornado':
          return const Color(0xFF9E9E9E);
        case 'explosion':
          return const Color(0xFFFF3D3D);
        case 'crystal':
          return const Color(0xFF81D4FA);
        default:
          return palette.accent;
      }
  }
}

class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final GamePalette palette;
  final bool owned;
  final bool selected;
  final bool canBuy;
  final bool justPurchased;
  final VoidCallback onTap;
  final VoidCallback onBuy;
  final VoidCallback onSelect;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.palette,
    required this.owned,
    required this.selected,
    required this.canBuy,
    required this.justPurchased,
    required this.onTap,
    required this.onBuy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final color = previewColorFor(item, palette);

    return RepaintBoundary(
      // ← این خط
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: owned
                  ? [color.withOpacity(0.10), palette.surface]
                  : [palette.surface, palette.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? palette.accent
                  : justPurchased
                      ? color.withOpacity(0.9)
                      : owned
                          ? color.withOpacity(0.4)
                          : palette.border,
              width: selected || justPurchased ? 2 : (owned ? 1.5 : 1),
            ),
            boxShadow: justPurchased
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.7),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : selected
                    ? [
                        BoxShadow(
                          color: palette.accent.withOpacity(0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : owned
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.12),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Column(
              children: [
                Expanded(flex: 6, child: _miniPreview(color)),
                Expanded(flex: 4, child: _infoSection(color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- پیش‌نمایش بورد کوچیک ----------
  Widget _miniPreview(Color color) {
    // 🍎 روی کیفیت پایین → فقط آیکون رنگی
    if (PerformanceService.effective == EffectiveQuality.low) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.55), color.withOpacity(0.15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 42,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.surface.withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Icon(Icons.visibility_rounded, size: 11, color: color),
              ),
            ),
          ],
        ),
      );
    }

    // نسخه‌ی کامل: BoardPainter
    final mockSnake = [
      const Point(1, 2),
      const Point(2, 2),
      const Point(3, 2),
      const Point(4, 2),
      const Point(4, 3),
      const Point(4, 4),
      const Point(3, 4),
      const Point(2, 4),
    ];
    final mockFood = const Point(1, 4);
    final mockGhost = <({int x, int y})>[
      (x: 4, y: 1),
      (x: 3, y: 1),
      (x: 2, y: 1),
    ];

    GamePalette previewPalette = palette;
    SnakeSkin snakeSkin = SnakeSkin.basic;
    GhostSkin ghostSkin = GhostSkin.basic;
    FoodSkin foodSkin = FoodSkin.basic;
    TrailEffect trail = TrailEffect.none; // ← این خط اضافه
    BoardPattern pattern = BoardPattern.none;

    bool showGhost = false;

    switch (item.type) {
      case ShopItemType.theme:
        final idx = palettes.indexWhere((pl) => pl.id == item.id);
        if (idx >= 0) previewPalette = palettes[idx];
        break;
      case ShopItemType.snakeSkin:
        snakeSkin = SnakeSkin.fromId(item.id);
        break;
      case ShopItemType.ghostSkin:
        ghostSkin = GhostSkin.fromId(item.id);
        showGhost = true;
        break;
      case ShopItemType.foodSkin:
        foodSkin = FoodSkin.fromId(item.id);
        break;
      case ShopItemType.trail:
        trail = TrailEffect.fromId(item.id);
        break;
      case ShopItemType.pattern:
        pattern = BoardPattern.fromId(item.id);
        break;
      case ShopItemType.intro:
        // انیمیشن شروع، پیش‌نمایش بورد نداره — همون مار پایه نشون داده می‌شه
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BoardPainter(
                snake: mockSnake,
                prevSnake: mockSnake,
                moveProgress: 1.0,
                food: mockFood,
                dir: const Point(1, 0),
                palette: previewPalette,
                pulse: 0.3,
                cols: 6,
                rows: 6,
                snakeSkin: snakeSkin,
                foodSkin: foodSkin,
                trail: trail, // ← این خط اضافه
                pattern: pattern,
                patternIntensity: PatternIntensity.medium,

                ghostSkin: ghostSkin,
                ghost: showGhost ? mockGhost : null,
                timePhase: 0.5,
                showGrid: false,
                rainbow: false,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: previewPalette.surface.withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 1),
              ),
              child: Icon(Icons.visibility_rounded, size: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- اطلاعات و دکمه ----------

  Widget _infoSection(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                L10n.t(item.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_rounded,
                      color: palette.food, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${item.price}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.food,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _actionButton(color),
        ],
      ),
    );
  }

  Widget _actionButton(Color color) {
    if (selected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: palette.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: palette.accent, size: 12),
            const SizedBox(width: 4),
            Text(
              L10n.t('shop_selected'),
              style: TextStyle(
                color: palette.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    if (owned) {
      return Material(
        color: palette.accent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onSelect,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, color: palette.onPrimary, size: 12),
                const SizedBox(width: 4),
                Text(
                  L10n.t('shop_select'),
                  style: TextStyle(
                    color: palette.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: canBuy ? palette.accent : palette.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: canBuy ? onBuy : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!canBuy)
                Icon(Icons.lock_rounded, color: palette.textMuted, size: 10),
              if (!canBuy) const SizedBox(width: 3),
              Text(
                L10n.t('shop_buy'),
                style: TextStyle(
                  color: canBuy ? palette.onPrimary : palette.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
