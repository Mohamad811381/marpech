// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:marpech/models/board_pattern.dart';
import '../models/game_palette.dart';
import '../models/skins.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../services/shop_service.dart';
import '../services/storage_service.dart';
import '../widgets/board_painter.dart';
import '../widgets/shop_item_card.dart';
import '../services/performance_service.dart';

class ShopScreen extends StatefulWidget {
  final GamePalette palette;
  final bool embedded;
  final VoidCallback? onPaletteChanged;
  final ShopItemType? categoryFilter;

  const ShopScreen({
    super.key,
    required this.palette,
    this.embedded = false,
    this.onPaletteChanged,
    this.categoryFilter,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  final _audio = AudioService();
  int _coins = 0;
  Set<String> _themes = {};
  Set<String> _snakeSkins = {};
  Set<String> _ghostSkins = {};
  Set<String> _foodSkins = {};
  Set<String> _trails = {};
  String _selectedTrailId = 'none';
  Set<String> _patterns = {};
  Set<String> _intros = {};
String _selectedIntroId = 'none';
  String _selectedPatternId = 'none';
  String _selectedThemeId = 'neon';
  String _selectedSnakeSkinId = 'basic';
  String _selectedGhostSkinId = 'basic';
  String _selectedFoodSkinId = 'basic';
  bool _loaded = false;

  late AnimationController _bannerController;
  String? _specialItemKey;
  String? _justPurchasedKey;

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _load();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final coins = await ShopService.getCoins();
    final themes = await ShopService.getUnlockedThemes();
    final snakeSkins = await ShopService.getUnlockedSnakeSkins();
    final ghostSkins = await ShopService.getUnlockedGhostSkins();
    final foodSkins = await ShopService.getUnlockedFoodSkins();
    final trails = await ShopService.getUnlockedTrails();
    final patterns = await ShopService.getUnlockedPatterns();
    final intros = await ShopService.getUnlockedIntros();          // ← این
    final paletteIndex = await StorageService.getPaletteIndex();
    final snakeId = await ShopService.getSelectedSnakeSkin();
    final ghostId = await ShopService.getSelectedGhostSkin();
    final foodId = await ShopService.getSelectedFoodSkin();
    final trailId = await ShopService.getSelectedTrail();
    final patternId = await ShopService.getSelectedPattern();
    final introId = await ShopService.getSelectedIntro();          // ← این
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _themes = themes;
      _snakeSkins = snakeSkins;
      _ghostSkins = ghostSkins;
      _foodSkins = foodSkins;
      _trails = trails;
      _patterns = patterns;
      _intros = intros;                                            // ← این
      _selectedThemeId =
          palettes[paletteIndex.clamp(0, palettes.length - 1)].id;
      _selectedSnakeSkinId = snakeId;
      _selectedGhostSkinId = ghostId;
      _selectedFoodSkinId = foodId;
      _selectedTrailId = trailId;
      _selectedPatternId = patternId;
      _selectedIntroId = introId;                                  // ← این
      _loaded = true;
    });
    _pickSpecialItem();
  }
  void _pickSpecialItem() {
    if (allShopItems.isEmpty) {
      if (mounted) setState(() => _specialItemKey = null);
      return;
    }
    final rng = Random();
    final chosen = allShopItems[rng.nextInt(allShopItems.length)];
    if (mounted) {
      setState(() => _specialItemKey = '${chosen.id}_${chosen.type.name}');
    }
  }

  ShopItem? get _specialItem {
    if (_specialItemKey == null) return null;
    for (final item in allShopItems) {
      if ('${item.id}_${item.type.name}' == _specialItemKey) return item;
    }
    return null;
  }

  bool _isOwned(ShopItem item) {
    switch (item.type) {
      case ShopItemType.theme:
        return _themes.contains(item.id);
      case ShopItemType.snakeSkin:
        return _snakeSkins.contains(item.id);
      case ShopItemType.ghostSkin:
        return _ghostSkins.contains(item.id);
      case ShopItemType.foodSkin:
        return _foodSkins.contains(item.id);
      case ShopItemType.trail:
        return _trails.contains(item.id);
      case ShopItemType.pattern:
        return _patterns.contains(item.id);
      case ShopItemType.intro:
        return _intros.contains(item.id);
    }
  }
  bool _isSelected(ShopItem item) {
    switch (item.type) {
      case ShopItemType.theme:
        return _selectedThemeId == item.id;
      case ShopItemType.snakeSkin:
        return _selectedSnakeSkinId == item.id;
      case ShopItemType.ghostSkin:
        return _selectedGhostSkinId == item.id;
      case ShopItemType.foodSkin:
        return _selectedFoodSkinId == item.id;
      case ShopItemType.trail:
        return _selectedTrailId == item.id;
      case ShopItemType.pattern:
        return _selectedPatternId == item.id;
              case ShopItemType.intro:
        return _selectedIntroId == item.id;
    }
  }

  Future<void> _buy(ShopItem item) async {
    await _audio.playSfx(Sfx.button);
    if (_coins < item.price) {
      _showSnack(L10n.t('shop_not_enough'));
      return;
    }
    final ok = await ShopService.purchase(item);
    if (!ok || !mounted) return;
    await _audio.playSfx(Sfx.newRecord);

    final key = '${item.id}_${item.type.name}';
    if (mounted) setState(() => _justPurchasedKey = key);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _justPurchasedKey == key) {
        setState(() => _justPurchasedKey = null);
      }
    });

    await _selectItem(item);
    _showSnack(L10n.tf('shop_success', {'name': L10n.t(item.name)}));
    await AchievementsService.checkUnlocks();
    await _load();
  }

  Future<void> _selectItem(ShopItem item) async {
    await _audio.playSfx(Sfx.button);
    switch (item.type) {
      case ShopItemType.theme:
        final idx = palettes.indexWhere((pl) => pl.id == item.id);
        if (idx >= 0) {
          await StorageService.setPaletteIndex(idx);
          if (mounted) setState(() => _selectedThemeId = item.id);
          widget.onPaletteChanged?.call();
        }
        break;
      case ShopItemType.snakeSkin:
        await ShopService.setSelectedSnakeSkin(item.id);
        if (mounted) setState(() => _selectedSnakeSkinId = item.id);
        break;
      case ShopItemType.ghostSkin:
        await ShopService.setSelectedGhostSkin(item.id);
        if (mounted) setState(() => _selectedGhostSkinId = item.id);
        break;
      case ShopItemType.foodSkin:
        await ShopService.setSelectedFoodSkin(item.id);
        if (mounted) setState(() => _selectedFoodSkinId = item.id);
        break;
      case ShopItemType.trail:
        await ShopService.setSelectedTrail(item.id);
        if (mounted) setState(() => _selectedTrailId = item.id);
        break;
      case ShopItemType.pattern:
        await ShopService.setSelectedPattern(item.id);
        if (mounted) setState(() => _selectedPatternId = item.id);
        break;
              case ShopItemType.intro:
        await ShopService.setSelectedIntro(item.id);
        if (mounted) setState(() => _selectedIntroId = item.id);
        break;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: p.surface,
        content: Text(message, style: TextStyle(color: p.textPrimary)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 اگه فیلتر دسته داریم → صفحه‌ی دسته
    if (widget.categoryFilter != null) {
      return _buildCategoryPage();
    }
    return _buildMainShop();
  }

  // ────────── فروشگاه اصلی ──────────
  Widget _buildMainShop() {
    final content = Column(
      children: [
        _topBar(),
        if (!_loaded)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(color: p.accent),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _coinsCard(),
                ),
                if (_specialItem != null) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _specialBanner(_specialItem!),
                  ),
                ],
                const SizedBox(height: 20),
                _section(
                  L10n.t('shop_section_themes'),
                  Icons.palette_rounded,
                  ShopItemType.theme,
                ),
                const SizedBox(height: 20),

                _section(
  L10n.t('shop_section_intros'),
  Icons.movie_rounded,
  ShopItemType.intro,
),
                _section(
                  L10n.t('shop_section_snake_skins'),
                  Icons.gesture_rounded,
                  ShopItemType.snakeSkin,
                ),
                const SizedBox(height: 20),
                _section(
                  L10n.t('shop_section_ghost_skins'),
                  Icons.blur_on_rounded,
                  ShopItemType.ghostSkin,
                ),
                const SizedBox(height: 20),
                _section(
                  L10n.t('shop_section_food_skins'),
                  Icons.restaurant_rounded,
                  ShopItemType.foodSkin,
                ),
                const SizedBox(height: 20),
                _section(
                  L10n.t('shop_section_trails'),
                  Icons.waves_rounded,
                  ShopItemType.trail,
                ),
                const SizedBox(height: 20),
                _section(
                  L10n.t('shop_section_patterns'),
                  Icons.grid_on_rounded,
                  ShopItemType.pattern,
                ),
              ],
            ),
          ),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(child: content),
    );
  }

  // ────────── صفحه‌ی دسته ──────────
  Widget _buildCategoryPage() {
    final type = widget.categoryFilter!;
    final items = allShopItems.where((i) => i.type == type).toList();

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _categoryTopBar(),
            if (!_loaded)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: p.accent),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final key = '${item.id}_${item.type.name}';
                    return ShopItemCard(
                      item: item,
                      palette: p,
                      owned: _isOwned(item),
                      selected: _isSelected(item),
                      canBuy: _coins >= item.price,
                      justPurchased: _justPurchasedKey == key,
                      onTap: () => _showPreview(item),
                      onBuy: () => _buy(item),
                      onSelect: () => _selectItem(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTopBar() {
    final type = widget.categoryFilter!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Icon(_categoryIcon(type), size: 22, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _categoryTitle(type),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on_rounded, color: p.food, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.food,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryTitle(ShopItemType type) {
    switch (type) {
      case ShopItemType.theme:
        return L10n.t('shop_section_themes');
      case ShopItemType.snakeSkin:
        return L10n.t('shop_section_snake_skins');
      case ShopItemType.ghostSkin:
        return L10n.t('shop_section_ghost_skins');
      case ShopItemType.foodSkin:
        return L10n.t('shop_section_food_skins');
      case ShopItemType.trail:
        return L10n.t('shop_section_trails');
      case ShopItemType.pattern:
        return L10n.t('shop_section_patterns');
      case ShopItemType.intro:
        return L10n.t('shop_section_intros');
    }
  }

  IconData _categoryIcon(ShopItemType type) {
    switch (type) {
      case ShopItemType.theme:
        return Icons.palette_rounded;
      case ShopItemType.snakeSkin:
        return Icons.gesture_rounded;
      case ShopItemType.ghostSkin:
        return Icons.blur_on_rounded;
      case ShopItemType.foodSkin:
        return Icons.restaurant_rounded;
      case ShopItemType.trail:
        return Icons.waves_rounded;
      case ShopItemType.pattern:
        return Icons.grid_on_rounded;
      case ShopItemType.intro:
        return Icons.movie_rounded;
    }
  }

  Future<void> _openCategory(ShopItemType type) async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopScreen(
          palette: p,
          categoryFilter: type,
          onPaletteChanged: widget.onPaletteChanged,
        ),
      ),
    );
    // بعد از برگشت، state رو refresh کن
    await _load();
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (!widget.embedded) ...[
            _backButton(),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('shop_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.t('shop_sub'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await ShopService.addCoins(1000);
              await _load();
              if (mounted) _showSnack('🧪 +1000 سکه');
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.storefront_rounded, color: p.accent, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: p.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.border),
          ),
          child: Icon(Icons.arrow_back_rounded, color: p.accent, size: 22),
        ),
      ),
    );
  }

  Widget _coinsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.20),
            p.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.22),
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
            ),
            child: const Icon(Icons.monetization_on_rounded,
                color: Color(0xFFFFD700), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('shop_coins'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialBanner(ShopItem item) {
    final color = previewColorFor(item, p);

    // 🍎 روی کیفیت پایین → بدون انیمیشن، glow ثابت
    if (PerformanceService.effective == EffectiveQuality.low) {
      return _buildSpecialBannerContent(item, color, 0.35);
    }

    return AnimatedBuilder(
      animation: _bannerController,
      builder: (context, _) {
        final glow = 0.25 + 0.25 * sin(_bannerController.value * pi * 2);
        return _buildSpecialBannerContent(item, color, glow);
      },
    );
  }

  Widget _buildSpecialBannerContent(ShopItem item, Color color, double glow) {
    return GestureDetector(
      onTap: () => _showPreview(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.30), p.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(glow),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    L10n.t('shop_special_today'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.65),
                        color.withOpacity(0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.t(item.name),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.monetization_on_rounded,
                              color: p.food, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${item.price}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.food,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _specialBannerButton(item, color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _specialBannerButton(ShopItem item, Color color) {
    final owned = _isOwned(item);
    final selected = _isSelected(item);
    final canBuy = _coins >= item.price;

    if (selected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: p.accent, size: 16),
            const SizedBox(width: 4),
            Text(
              L10n.t('shop_selected'),
              style: TextStyle(
                color: p.accent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (owned) {
      return Material(
        color: p.accent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: p.onPrimary, size: 14),
                const SizedBox(width: 4),
                Text(
                  L10n.t('shop_select'),
                  style: TextStyle(
                    color: p.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: canBuy ? color : p.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canBuy ? () => _buy(item) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canBuy) ...[
                Icon(Icons.lock_rounded, color: p.textMuted, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                L10n.t('shop_buy'),
                style: TextStyle(
                  color: canBuy ? Colors.white : p.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, ShopItemType type) {
    final allItems = allShopItems.where((i) => i.type == type).toList();
    final displayItems = allItems.take(3).toList();
    final hasMore = allItems.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 16, color: p.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: () => _openCategory(type),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          L10n.t('shop_see_all'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: p.accent),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = displayItems[i];
              final key = '${item.id}_${item.type.name}';
              return SizedBox(
                width: 160,
                child: ShopItemCard(
                  item: item,
                  palette: p,
                  owned: _isOwned(item),
                  selected: _isSelected(item),
                  canBuy: _coins >= item.price,
                  justPurchased: _justPurchasedKey == key,
                  onTap: () => _showPreview(item),
                  onBuy: () => _buy(item),
                  onSelect: () => _selectItem(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showPreview(ShopItem item) async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        final owned = _isOwned(item);
        final selected = _isSelected(item);
        final canBuy = _coins >= item.price;

        return Dialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        L10n.t(item.name),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.close_rounded,
                          color: p.textMuted, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildPreviewMockup(item),
                ),
                const SizedBox(height: 14),
                if (!owned)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on_rounded,
                          color: p.food, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: p.food,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                if (selected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: p.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: p.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          L10n.t('shop_selected'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (owned)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _selectItem(item);
                      },
                      icon: Icon(Icons.check_rounded, color: p.onPrimary),
                      label: Text(
                        L10n.t('shop_select'),
                        style: TextStyle(
                          color: p.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: canBuy
                          ? () async {
                              Navigator.pop(ctx);
                              await _buy(item);
                            }
                          : null,
                      icon: Icon(
                        Icons.shopping_bag_rounded,
                        color: canBuy ? p.onPrimary : p.textMuted,
                      ),
                      label: Text(
                        L10n.tf('shop_buy_for', {'n': item.price}),
                        style: TextStyle(
                          color: canBuy ? p.onPrimary : p.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBuy ? p.accent : p.surfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  

  Widget _buildPreviewMockup(ShopItem item) {
    BoardPattern previewPattern = BoardPattern.none;
    PatternIntensity previewIntensity = PatternIntensity.subtle;
    GamePalette previewPalette = p;
    SnakeSkin previewSnakeSkin = SnakeSkin.basic;
    GhostSkin previewGhostSkin = GhostSkin.basic;
    FoodSkin previewFoodSkin = FoodSkin.basic;
    TrailEffect previewTrail = TrailEffect.none; // ← این خط اضافه

    bool showGhost = false;

    switch (item.type) {
      case ShopItemType.theme:
        final idx = palettes.indexWhere((pl) => pl.id == item.id);
        if (idx >= 0) previewPalette = palettes[idx];
        break;
      case ShopItemType.snakeSkin:
        previewSnakeSkin = SnakeSkin.fromId(item.id);
        break;
      case ShopItemType.ghostSkin:
        previewGhostSkin = GhostSkin.fromId(item.id);
        showGhost = true;
        break;
      case ShopItemType.foodSkin:
        previewFoodSkin = FoodSkin.fromId(item.id);
        break;
      case ShopItemType.trail:
        previewTrail = TrailEffect.fromId(item.id);
        break;
      case ShopItemType.pattern:
        previewPattern = BoardPattern.fromId(item.id);
        previewIntensity = PatternIntensity.medium;
        break;
      case ShopItemType.intro:
        // انیمیشن شروع، پیش‌نمایش بورد نداره — مار پایه نشون داده می‌شه
        break;
    }
    final mockSnake = [
      const Point(2, 3),
      const Point(3, 3),
      const Point(4, 3),
      const Point(5, 3),
      const Point(6, 3),
      const Point(6, 4),
      const Point(6, 5),
      const Point(5, 5),
      const Point(4, 5),
    ];

    final mockGhost = <({int x, int y})>[
      (x: 8, y: 7),
      (x: 7, y: 7),
      (x: 7, y: 8),
    ];

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: BoardPainter(
          snake: mockSnake,
          prevSnake: mockSnake,
          moveProgress: 1.0,
          food: const Point(3, 7),
          dir: const Point(1, 0),
          palette: previewPalette,
          pulse: 0.5,
          cols: 10,
          rows: 10,
          snakeSkin: previewSnakeSkin,
          foodSkin: previewFoodSkin,
          trail: previewTrail, // ← این خط اضافه شد
          pattern: previewPattern,
          patternIntensity: previewIntensity,
          ghostSkin: previewGhostSkin,
          ghost: showGhost ? mockGhost : null,
          timePhase: 0.5,
        ),
      ),
    );
  }
}
