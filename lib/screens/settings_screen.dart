// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marpech/services/player_progression_service.dart';
import 'package:marpech/services/theme_service.dart';
import '../models/game_palette.dart';
import '../models/game_settings.dart';
import '../models/skins.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import '../services/shop_service.dart';
import '../services/storage_service.dart';
import '../models/board_pattern.dart';
import '../services/performance_service.dart';
import '../models/intro_animation.dart';
import '../models/level_cosmetics.dart';
import '../widgets/board_painter.dart';

class SettingsScreen extends StatefulWidget {
  final GamePalette palette;
  const SettingsScreen({super.key, required this.palette});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late GameSettings _settings;
  late GamePalette _currentPalette;
  GamePalette get p => _currentPalette;
  final _audio = AudioService();

  String _selectedThemeId = 'neon';
  String _selectedSnakeSkinId = 'basic';
  String _selectedGhostSkinId = 'basic';
  String _selectedFoodSkinId = 'basic';
  String _selectedTrailId = 'none';
  String _selectedPatternId = 'none';
  String _selectedIntroId = 'none';
  Set<String> _unlockedIntros = {'none'};
  Set<String> _levelOwnedCosmetics = {};
  Set<String> _unlockedThemes = {'neon', 'sunset', 'cyber'};
  Set<String> _unlockedSnakeSkins = {'basic'};
  Set<String> _unlockedGhostSkins = {'basic'};
  Set<String> _unlockedFoodSkins = {'basic'};
  Set<String> _unlockedTrails = {'none'};
  Set<String> _unlockedPatterns = {'none'};

  PatternIntensity _patternIntensity = PatternIntensity.subtle;
  int _coins = 0;
  int _playerXp = 0;

  late final AnimationController _boardPulse;

  static const _mockSnake = [
    math.Point(1, 2),
    math.Point(2, 2),
    math.Point(3, 2),
    math.Point(4, 2),
    math.Point(4, 3),
  ];
  static const _mockFood = math.Point(1, 4);
  static const _mockGhost = <({int x, int y})>[
    (x: 4, y: 1),
    (x: 3, y: 1),
    (x: 2, y: 1),
  ];

  @override
  void initState() {
    super.initState();
    _settings = SettingsService.current;
    _currentPalette = widget.palette;
    ThemeService.mode.addListener(_onThemeChanged);
    ThemeService.darkPalette.addListener(_onThemeChanged);
    _boardPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadShop();
    _loadHud();
  }

  @override
  void dispose() {
    _boardPulse.dispose();
    ThemeService.mode.removeListener(_onThemeChanged);
    ThemeService.darkPalette.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentPalette = ThemeService.resolve(context);
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() => _currentPalette = ThemeService.resolve(context));
  }

  Future<void> _loadHud() async {
    final coins = await ShopService.getCoins();
    final xp = await StorageService.getPlayerXpTotal();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _playerXp = xp;
    });
  }

  Future<void> _loadShop() async {
    final themes = await ShopService.getUnlockedThemes();
    final snakeSkins = await ShopService.getUnlockedSnakeSkins();
    final ghostSkins = await ShopService.getUnlockedGhostSkins();
    final foodSkins = await ShopService.getUnlockedFoodSkins();
    final trails = await ShopService.getUnlockedTrails();
    final patterns = await ShopService.getUnlockedPatterns();
    final intros = await ShopService.getUnlockedIntros();
    final levelOwned = await StorageService.getLevelOwnedCosmetics();
    final intensityId = await ShopService.getPatternIntensity();
    final paletteIndex = await StorageService.getPaletteIndex();

    final snakeId = await ShopService.getSelectedSnakeSkin();
    final ghostId = await ShopService.getSelectedGhostSkin();
    final foodId = await ShopService.getSelectedFoodSkin();
    final trailId = await ShopService.getSelectedTrail();
    final patternId = await ShopService.getSelectedPattern();
    final introId = await ShopService.getSelectedIntro();
    if (!mounted) return;
    setState(() {
      _unlockedThemes = themes;
      _unlockedSnakeSkins = snakeSkins;
      _unlockedGhostSkins = ghostSkins;
      _unlockedFoodSkins = foodSkins;
      _unlockedTrails = trails;
      _unlockedPatterns = patterns;
      _unlockedIntros = intros;
      _levelOwnedCosmetics = levelOwned;
      _patternIntensity = PatternIntensity.fromId(intensityId);
      _selectedThemeId =
          palettes[paletteIndex.clamp(0, palettes.length - 1)].id;
      _selectedSnakeSkinId = snakeId;
      _selectedGhostSkinId = ghostId;
      _selectedFoodSkinId = foodId;
      _selectedTrailId = trailId;
      _selectedPatternId = patternId;
      _selectedIntroId = introId;
    });
  }

  Future<void> _update(GameSettings s) async {
    setState(() => _settings = s);
    await SettingsService.save(s);
    await _audio.onSettingsChanged();
  }

  Future<void> _resetDefaults() async {
    await _update(const GameSettings());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: p.surface,
        content: Text(
          L10n.t('settings_reset_toast'),
          style: TextStyle(color: p.textPrimary),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _stickyPreview(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // ───── 🆕 زبان ─────
                  _sectionCard(
                    icon: Icons.language_rounded,
                    title: L10n.t('settings_section_language'),
                    child: _languageRow(),
                  ),
                  // ───── 🆕 تم ─────
                  _sectionCard(
                    icon: Icons.palette_rounded,
                    title: L10n.t('settings_theme_select'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _themeModeRow(),
                        const SizedBox(height: 14),
                        _themeRow(),
                      ],
                    ),
                  ),
                  // ───── اسکین‌ها (کد پیوست) ─────
                  _section(
                    icon: Icons.brush_rounded,
                    title: L10n.t('settings_section_skins'),
                    children: [
                      _snakeSkinSelector(),
                      _ghostSkinSelector(),
                      _foodSkinSelector(),
                      _trailSelector(),
                      _patternSelector(),
                      _introSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ───── 🆕 حرکت و بازی ─────
                  _sectionCard(
                    icon: Icons.sports_esports_rounded,
                    title: L10n.t('settings_section_game'),
                    child: _gameplaySection(),
                  ),
                  // ───── 🆕 صدا ─────
                  _sectionCard(
                    icon: Icons.volume_up_rounded,
                    title: L10n.t('settings_section_sound'),
                    child: _soundSection(),
                  ),
                  // ───── 🆕 افکت‌ها ─────
                  _sectionCard(
                    icon: Icons.auto_awesome_rounded,
                    title: L10n.t('settings_section_effects'),
                    child: _effectsSection(),
                  ),
                  const SizedBox(height: 22),
                  // ───── 🆕 Reset + Debug ─────
                  _resetButton(),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    _debugButton(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('settings_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.t('settings_subtitle'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          _coinChip(),
          const SizedBox(width: 6),
          _levelChip(),
        ],
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════
  // HUD CHIPS
  // ═══════════════════════════════════════════════════════════

  Widget _coinChip() {
    const gold = Color(0xFFFFD700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withOpacity(0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            size: 14,
            color: gold,
          ),
          const SizedBox(width: 5),
          Text(
            '$_coins',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelChip() {
    final level = PlayerProgressionService.levelFromXp(_playerXp);
    final isMax = level >= PlayerProgressionService.maxLevel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.accent.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMax
                ? Icons.workspace_premium_rounded
                : Icons.military_tech_rounded,
            size: 14,
            color: p.accent,
          ),
          const SizedBox(width: 5),
          Text(
            isMax ? 'MAX' : 'Lv.$level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: p.accent,
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

  // ═══════════════════════════════════════════════════════════
  // STICKY PREVIEW
  // ═══════════════════════════════════════════════════════════

  Widget _stickyPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: p.accent.withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: p.accent.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: p.board,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _boardPulse,
                    builder: (_, __) => CustomPaint(
                      painter: BoardPainter(
                        snake: _mockSnake,
                        prevSnake: _mockSnake,
                        moveProgress: 1.0,
                        food: _mockFood,
                        dir: const math.Point(1, 0),
                        palette: p,
                        pulse: _boardPulse.value,
                        cols: 6,
                        rows: 6,
                        snakeSkin: SnakeSkin.fromId(_selectedSnakeSkinId),
                        foodSkin: FoodSkin.fromId(_selectedFoodSkinId),
                        trail: TrailEffect.fromId(_selectedTrailId),
                        pattern: BoardPattern.fromId(_selectedPatternId),
                        patternIntensity: _patternIntensity,
                        ghostSkin: GhostSkin.fromId(_selectedGhostSkinId),
                        ghost: _settings.showGhost ? _mockGhost : null,
                        timePhase: _boardPulse.value,
                        showGrid: false,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      L10n.isFa ? 'پیش‌نمایش زنده' : 'LIVE PREVIEW',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: L10n.isFa ? 0.3 : 2,
                        color: p.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _previewInfoRow('🎨', p.name, p.accent),
                const SizedBox(height: 4),
                _previewInfoRow(
                  '🐍',
                  SnakeSkin.fromId(_selectedSnakeSkinId).name,
                  p.textPrimary,
                ),
                const SizedBox(height: 4),
                _previewInfoRow(
                  '🍎',
                  FoodSkin.fromId(_selectedFoodSkinId).name,
                  p.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewInfoRow(String emoji, String label, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION CARD (برای زبان، تم، بازی، صدا، افکت)
  // ═══════════════════════════════════════════════════════════

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.border.withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: p.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: p.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: p.border.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 LANGUAGE
  // ═══════════════════════════════════════════════════════════

  Widget _languageRow() {
    final current = LocalizationService.instance.lang;
    return Row(
      children: [
        _bigLangBtn(
          label: 'فارسی',
          selected: current == 'fa',
          onTap: () async {
            await _audio.playSfx(Sfx.button);
            await LocalizationService.instance.setLanguage('fa');
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(width: 8),
        _bigLangBtn(
          label: 'English',
          selected: current == 'en',
          onTap: () async {
            await _audio.playSfx(Sfx.button);
            await LocalizationService.instance.setLanguage('en');
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }

  Widget _bigLangBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? p.accent.withOpacity(0.12)
                : p.surfaceAlt.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? p.accent : p.border.withOpacity(0.5),
              width: selected ? 1.5 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? p.accent : p.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 THEME
  // ═══════════════════════════════════════════════════════════

  Widget _themeRow() {
    final displayed = palettes.where((pal) {
      if (_unlockedThemes.contains(pal.id)) return true;
      return levelCosmeticById(pal.id) != null;
    }).toList();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: displayed.map((pal) {
        final lc = levelCosmeticById(pal.id);
        final owned = _unlockedThemes.contains(pal.id) ||
            _levelOwnedCosmetics.contains(pal.id);
        final selected = pal.id == _selectedThemeId;

        return _cosmeticChip(
          label: pal.name,
          owned: owned,
          selected: selected,
          requiredLevel: lc?.requiredLevel,
          leading: owned
              ? Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pal.snakeHead, pal.snakeTail],
                    ),
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: owned
              ? () async {
                  await _audio.playSfx(Sfx.button);
                  await ThemeService.setDarkPalette(pal);
                  if (mounted) setState(() => _selectedThemeId = pal.id);
                }
              : null,
        );
      }).toList(),
    );
  }

  Widget _themeModeRow() {
    return _segmentRow<ThemeMode>(
      title: L10n.t('settings_theme_mode'),
      options: ThemeMode.values,
      current: ThemeService.mode.value,
      labelOf: (m) => L10n.t('settings_theme_${m.name}'),
      onChanged: (m) async {
        await _audio.playSfx(Sfx.button);
        await ThemeService.setMode(m);
      },
    );
  }
  // ═══════════════════════════════════════════════════════════
  // 🆕 GAMEPLAY
  // ═══════════════════════════════════════════════════════════

  Widget _gameplaySection() {
    return Column(
      children: [
        _editorialToggle(
          L10n.t('settings_smooth'),
          _settings.smoothMovement,
          (v) => _update(_settings.copyWith(smoothMovement: v)),
        ),
        _divider(),
        _editorialToggle(
          L10n.t('settings_grid'),
          _settings.showGrid,
          (v) => _update(_settings.copyWith(showGrid: v)),
        ),
        _divider(),
        _editorialToggle(
          L10n.t('settings_haptics'),
          _settings.haptics,
          (v) => _update(_settings.copyWith(haptics: v)),
        ),
        const SizedBox(height: 14),
        _segmentRow<DPadSize>(
          title: L10n.t('settings_dpad'),
          options: DPadSize.values,
          current: _settings.dpadSize,
          labelOf: (v) {
            switch (v) {
              case DPadSize.small:
                return L10n.t('settings_dpad_small');
              case DPadSize.medium:
                return L10n.t('settings_dpad_medium');
              case DPadSize.large:
                return L10n.t('settings_dpad_large');
            }
          },
          onChanged: (v) => _update(_settings.copyWith(dpadSize: v)),
        ),
        const SizedBox(height: 14),
        _segmentRow<ControlType>(
          title: L10n.t('settings_control_type'),
          options: ControlType.values,
          current: _settings.controlType,
          labelOf: (v) => v == ControlType.dpad
              ? L10n.t('settings_control_dpad')
              : L10n.t('settings_control_joystick'),
          onChanged: (v) => _update(_settings.copyWith(controlType: v)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 SOUND
  // ═══════════════════════════════════════════════════════════

  Widget _soundSection() {
    return Column(
      children: [
        _editorialToggle(
          L10n.t('settings_sfx'),
          _settings.sfx,
          (v) => _update(_settings.copyWith(sfx: v)),
        ),
        _divider(),
        _editorialToggle(
          L10n.t('settings_music'),
          _settings.music,
          (v) => _update(_settings.copyWith(music: v)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 EFFECTS
  // ═══════════════════════════════════════════════════════════

  Widget _effectsSection() {
    return Column(
      children: [
        _segmentRow<GraphicsQuality>(
          title: L10n.t('settings_graphics_quality'),
          options: GraphicsQuality.values,
          current: PerformanceService.quality,
          labelOf: (q) => L10n.t('settings_graphics_${q.id}'),
          onChanged: (q) async {
            await _audio.playSfx(Sfx.button);
            await PerformanceService.setQuality(q);
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 14),
        _editorialToggle(
          L10n.t('settings_particles'),
          _settings.particles,
          (v) => _update(_settings.copyWith(particles: v)),
        ),
        _divider(),
        _editorialToggle(
          L10n.t('settings_shake'),
          _settings.screenShake,
          (v) => _update(_settings.copyWith(screenShake: v)),
        ),
        _divider(),
        _editorialToggle(
          L10n.t('settings_wrap'),
          _settings.wrapEffect,
          (v) => _update(_settings.copyWith(wrapEffect: v)),
        ),
        _divider(),
        _editorialToggle(
          L10n.t('settings_ghost'),
          _settings.showGhost,
          (v) => _update(_settings.copyWith(showGhost: v)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 SHARED TOGGLE / SEGMENT / DIVIDER
  // ═══════════════════════════════════════════════════════════

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: 0.5,
        color: p.border.withOpacity(0.3),
      ),
    );
  }

  Widget _editorialToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: p.textPrimary,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 0.5,
              color: p.border.withOpacity(0.5),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? p.accent : Colors.transparent,
                border: Border.all(
                  color: value ? p.accent : p.textMuted.withOpacity(0.6),
                  width: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentRow<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.textPrimary,
            ),
          ),
        ),
        Row(
          children: options.asMap().entries.map((entry) {
            final opt = entry.value;
            final isLast = entry.key == options.length - 1;
            final selected = opt == current;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 6),
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? p.accent.withOpacity(0.1)
                          : p.surfaceAlt.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selected ? p.accent : p.border.withOpacity(0.5),
                        width: selected ? 1 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labelOf(opt),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? p.accent : p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 RESET / DEBUG
  // ═══════════════════════════════════════════════════════════

  Widget _resetButton() {
    return InkWell(
      onTap: _resetDefaults,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: p.border.withOpacity(0.6),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            L10n.isFa
                ? L10n.t('settings_reset_defaults')
                : L10n.t('settings_reset_defaults').toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: L10n.isFa ? 0.3 : 2,
              color: p.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _debugButton() {
    return InkWell(
      onTap: () async {
        const target = 100000;
        final current = await StorageService.getPlayerXpTotal();
        if (current >= target) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: p.surface,
                content: Text(
                  '🧪 XP already: $current',
                  style: TextStyle(color: p.textPrimary),
                ),
              ),
            );
          }
          return;
        }
        final delta = target - current;
        await PlayerProgressionService.addXP(
          eventId: 'debug:xp_${DateTime.now().millisecondsSinceEpoch}',
          amount: delta,
          source: 'debug',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: p.surface,
              content: Text(
                '🧪 +$delta XP → Lv.100',
                style: TextStyle(color: p.textPrimary),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: p.food.withOpacity(0.3),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '🧪 SET LV.100 (DEBUG)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: p.food,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ⬇️⬇️ از این به بعد دقیقاً کد پیوست (اسکین‌ها) ⬇️⬇️
  // ═══════════════════════════════════════════════════════════

  Widget _cosmeticChip({
    required String label,
    required bool owned,
    required bool selected,
    int? requiredLevel,
    VoidCallback? onTap,
    Widget? leading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.accent : (owned ? p.surfaceAlt : p.surface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? p.accent
                : (owned ? p.border : p.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 6),
            ] else if (!owned) ...[
              Icon(Icons.lock_rounded, size: 12, color: p.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? p.onPrimary
                    : (owned ? p.textPrimary : p.textMuted),
              ),
            ),
            if (!owned && requiredLevel != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: p.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lv.$requiredLevel',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(Divider(
          height: 1,
          color: p.border.withOpacity(0.4),
          indent: 52,
          endIndent: 14,
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(icon, size: 14, color: p.textMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Column(children: spaced),
        ),
      ],
    );
  }

  Widget _snakeSkinSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('settings_snake_skin'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SnakeSkin.values
                .where((s) =>
                    _unlockedSnakeSkins.contains(s.id) ||
                    levelCosmeticById(s.id) != null)
                .map((skin) {
              final lc = levelCosmeticById(skin.id);
              final owned = _unlockedSnakeSkins.contains(skin.id) ||
                  _levelOwnedCosmetics.contains(skin.id);
              return _cosmeticChip(
                label: skin.name,
                owned: owned,
                selected: skin.id == _selectedSnakeSkinId,
                requiredLevel: lc?.requiredLevel,
                onTap: owned
                    ? () async {
                        await _audio.playSfx(Sfx.button);
                        await ShopService.setSelectedSnakeSkin(skin.id);
                        if (mounted) {
                          setState(() => _selectedSnakeSkinId = skin.id);
                        }
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _ghostSkinSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('settings_ghost_skin'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GhostSkin.values
                .where((s) =>
                    _unlockedGhostSkins.contains(s.id) ||
                    levelCosmeticById(s.id) != null)
                .map((skin) {
              final lc = levelCosmeticById(skin.id);
              final owned = _unlockedGhostSkins.contains(skin.id) ||
                  _levelOwnedCosmetics.contains(skin.id);
              return _cosmeticChip(
                label: skin.name,
                owned: owned,
                selected: skin.id == _selectedGhostSkinId,
                requiredLevel: lc?.requiredLevel,
                onTap: owned
                    ? () async {
                        await _audio.playSfx(Sfx.button);
                        await ShopService.setSelectedGhostSkin(skin.id);
                        if (mounted) {
                          setState(() => _selectedGhostSkinId = skin.id);
                        }
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _foodSkinSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('settings_food_skin'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FoodSkin.values
                .where((s) =>
                    _unlockedFoodSkins.contains(s.id) ||
                    levelCosmeticById(s.id) != null)
                .map((skin) {
              final lc = levelCosmeticById(skin.id);
              final owned = _unlockedFoodSkins.contains(skin.id) ||
                  _levelOwnedCosmetics.contains(skin.id);
              return _cosmeticChip(
                label: skin.name,
                owned: owned,
                selected: skin.id == _selectedFoodSkinId,
                requiredLevel: lc?.requiredLevel,
                onTap: owned
                    ? () async {
                        await _audio.playSfx(Sfx.button);
                        await ShopService.setSelectedFoodSkin(skin.id);
                        if (mounted) {
                          setState(() => _selectedFoodSkinId = skin.id);
                        }
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _trailSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('settings_trail'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrailEffect.values
                .where((s) =>
                    _unlockedTrails.contains(s.id) ||
                    levelCosmeticById(s.id) != null)
                .map((trail) {
              final lc = levelCosmeticById(trail.id);
              final owned = _unlockedTrails.contains(trail.id) ||
                  _levelOwnedCosmetics.contains(trail.id);
              return _cosmeticChip(
                label: trail.name,
                owned: owned,
                selected: trail.id == _selectedTrailId,
                requiredLevel: lc?.requiredLevel,
                onTap: owned
                    ? () async {
                        await _audio.playSfx(Sfx.button);
                        await ShopService.setSelectedTrail(trail.id);
                        if (mounted) {
                          setState(() => _selectedTrailId = trail.id);
                        }
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _patternSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('settings_pattern'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BoardPattern.values
                .where((s) =>
                    _unlockedPatterns.contains(s.id) ||
                    levelCosmeticById(s.id) != null)
                .map((pattern) {
              final lc = levelCosmeticById(pattern.id);
              final owned = _unlockedPatterns.contains(pattern.id) ||
                  _levelOwnedCosmetics.contains(pattern.id);
              return _cosmeticChip(
                label: pattern.name,
                owned: owned,
                selected: pattern.id == _selectedPatternId,
                requiredLevel: lc?.requiredLevel,
                onTap: owned
                    ? () async {
                        await _audio.playSfx(Sfx.button);
                        await ShopService.setSelectedPattern(pattern.id);
                        if (mounted) {
                          setState(() => _selectedPatternId = pattern.id);
                        }
                      }
                    : null,
              );
            }).toList(),
          ),
          if (_selectedPatternId != 'none') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.opacity_rounded, size: 14, color: p.textMuted),
                const SizedBox(width: 6),
                Text(
                  L10n.t('pattern_intensity_title'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: PatternIntensity.values.map((intensity) {
                final selected = intensity.id == _patternIntensity.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () async {
                        await _audio.playSfx(Sfx.button);
                        setState(() => _patternIntensity = intensity);
                        await ShopService.setPatternIntensity(intensity.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? p.accent : p.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? p.accent : p.border,
                          ),
                        ),
                        child: Text(
                          intensity.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? p.onPrimary : p.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _introSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('settings_intro'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IntroAnimation.values
                .where((s) =>
                    _unlockedIntros.contains(s.id) ||
                    levelCosmeticById(s.id) != null)
                .map((intro) {
              final lc = levelCosmeticById(intro.id);
              final owned = _unlockedIntros.contains(intro.id) ||
                  _levelOwnedCosmetics.contains(intro.id);
              return _cosmeticChip(
                label: intro.name,
                owned: owned,
                selected: intro.id == _selectedIntroId,
                requiredLevel: lc?.requiredLevel,
                onTap: owned
                    ? () async {
                        await _audio.playSfx(Sfx.button);
                        await ShopService.setSelectedIntro(intro.id);
                        if (mounted) {
                          setState(() => _selectedIntroId = intro.id);
                        }
                      }
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
