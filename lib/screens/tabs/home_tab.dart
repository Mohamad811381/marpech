// ignore_for_file: prefer_const_constructors, deprecated_member_use, use_build_context_synchronously

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../models/game_palette.dart';
import '../../services/audio_service.dart';
import '../../services/daily_reward_service.dart';
import '../../services/levels_service.dart';
import '../../services/localization_service.dart';
import '../../services/shop_service.dart';
import '../../services/storage_service.dart';
import '../game_screen.dart';
import '../chapters_screen.dart';
import '../../widgets/daily_reward_dialog.dart';
import '../../services/player_progression_service.dart';
import '../../widgets/level_badge.dart';
import '../../widgets/board_painter.dart';
import '../../models/skins.dart';
import '../../models/board_pattern.dart';

class HomeTab extends StatefulWidget {
  final GamePalette palette;
  final VoidCallback onPaletteChanged;
  final VoidCallback? onLevelBadgeTap;

  const HomeTab({
    super.key,
    required this.palette,
    required this.onPaletteChanged,
    this.onLevelBadgeTap,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  Difficulty _difficulty = Difficulty.normal;
  int _best = 0;
  int _timeAttackBest = 0;
  bool _loaded = false;
  int _completedLevels = 0;
  int _coins = 0;
  DailyRewardStatus? _rewardStatus;
  int _playerXp = 0;
  // اسکین‌های پیش‌نمایش (از انتخاب‌های کاربر)
  SnakeSkin _previewSnakeSkin = SnakeSkin.basic;
  FoodSkin _previewFoodSkin = FoodSkin.basic;
  TrailEffect _previewTrail = TrailEffect.none;
  BoardPattern _previewPattern = BoardPattern.none;
  PatternIntensity _previewIntensity = PatternIntensity.subtle;

  late final AnimationController _boardPulse;

  final _audio = AudioService();
  GamePalette get p => widget.palette;

  // ── Helpers برای i18n ──
  double _ls(double english) => L10n.isFa ? 0.3 : english;
  FontStyle get _italic => L10n.isFa ? FontStyle.normal : FontStyle.italic;
  String _upper(String s) => L10n.isFa ? s : s.toUpperCase();

  @override
  void initState() {
    super.initState();
    PlayerProgressionService.pendingLevelUps.addListener(_onProgressionChanged);
    _boardPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _load();
  }

  @override
  void dispose() {
    PlayerProgressionService.pendingLevelUps
        .removeListener(_onProgressionChanged);
    _boardPulse.dispose();
    super.dispose();
  }

  void _onProgressionChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    final d = await StorageService.getDifficultyIndex();
    final diff = Difficulty.values[d.clamp(0, Difficulty.values.length - 1)];
    final b = await StorageService.getBestScore(diff);
    final ta = await StorageService.getTimeAttackBest();
    final completed = await LevelsService.getCompleted();
    final coins = await ShopService.getCoins();
    final reward = await DailyRewardService.getStatus();
    final xp = await StorageService.getPlayerXpTotal();

    // 🎨 اسکین‌های انتخاب‌شده کاربر
    final snakeId = await ShopService.getSelectedSnakeSkin();
    final foodId = await ShopService.getSelectedFoodSkin();
    final trailId = await ShopService.getSelectedTrail();
    final patternId = await ShopService.getSelectedPattern();
    final intensityId = await ShopService.getPatternIntensity();

    if (!mounted) return;
    setState(() {
      _difficulty = diff;
      _best = b;
      _timeAttackBest = ta;
      _completedLevels = completed.length;
      _coins = coins;
      _rewardStatus = reward;
      _playerXp = xp;
      _previewSnakeSkin = SnakeSkin.fromId(snakeId);
      _previewFoodSkin = FoodSkin.fromId(foodId);
      _previewTrail = TrailEffect.fromId(trailId);
      _previewPattern = BoardPattern.fromId(patternId);
      _previewIntensity = PatternIntensity.fromId(intensityId);
      _loaded = true;
    });
  }

  Future<void> _selectDifficulty(Difficulty d) async {
    await _audio.playSfx(Sfx.button);
    setState(() => _difficulty = d);
    await StorageService.setDifficultyIndex(d.index);
    final b = await StorageService.getBestScore(d);
    if (mounted) setState(() => _best = b);
  }

  Future<void> _cyclePalette() async {
    await _audio.playSfx(Sfx.button);
    final unlocked = await ShopService.getUnlockedThemes();
    final currentIdx = palettes.indexWhere((p) => p.id == widget.palette.id);
    int next = currentIdx;
    for (var i = 1; i <= palettes.length; i++) {
      final idx = (currentIdx + i) % palettes.length;
      if (unlocked.contains(palettes[idx].id)) {
        next = idx;
        break;
      }
    }
    await StorageService.setPaletteIndex(next);
    widget.onPaletteChanged();
    if (mounted) setState(() {});
  }

  Future<void> _startFree() async {
    await _audio.playSfx(Sfx.button);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(difficulty: _difficulty, palette: p),
      ),
    );
    await _load();
  }

  Future<void> _startTimeAttack() async {
    await _audio.playSfx(Sfx.button);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: _difficulty,
          palette: p,
          timeLimit: const Duration(seconds: 60),
        ),
      ),
    );
    await _load();
  }

  Future<void> _openLevels() async {
    await _audio.playSfx(Sfx.button);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChaptersScreen(
          palette: p,
          difficulty: _difficulty,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openDailyReward() async {
    await _audio.playSfx(Sfx.button);
    final status = await DailyRewardService.getStatus();
    if (!mounted) return;

    if (status.claimedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.t('menu_daily_reward_claimed_today'),
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
      return;
    }

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DailyRewardDialog(palette: p, status: status),
    );

    await _load();

    if (result != null && result > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.tf('menu_reward_toast', {'n': result}),
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Center(child: CircularProgressIndicator(color: p.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 26),
          _masthead(),
          const SizedBox(height: 20),
          _heroPreview(),
          const SizedBox(height: 24),
          if (_rewardStatus?.canClaimToday == true) ...[
            _dailyRewardBanner(),
            const SizedBox(height: 18),
          ],
          _sectionHeader(L10n.t('home_select_difficulty')),
          _difficultySelector(),
          const SizedBox(height: 26),
          _continueButton(),
          const SizedBox(height: 12),
          _secondaryRow(),
          const SizedBox(height: 30),
          _footerStats(),
          const SizedBox(height: 20),
          _themeRow(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _drawerButton(context),
        const Spacer(),
        LevelBadge(
          xpTotal: _playerXp,
          palette: p,
          onTap: widget.onLevelBadgeTap,
        ),
        const SizedBox(width: 14),
        _coinDisplay(),
      ],
    );
  }

  Widget _drawerButton(BuildContext context) {
    return InkWell(
      onTap: () {
        _audio.playSfx(Sfx.button);
        Scaffold.of(context).openDrawer();
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(Icons.menu_rounded, color: p.textPrimary, size: 22),
        ),
      ),
    );
  }

  Widget _coinDisplay() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD700),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_coins',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // MASTHEAD
  // ─────────────────────────────────────────

  Widget _masthead() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 40, height: 1, color: p.accent.withOpacity(0.6)),
        const SizedBox(height: 14),
        Text(
          L10n.t('app_name'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w300,
            height: 1.1,
            letterSpacing: _ls(2),
            color: p.textPrimary,
            fontStyle: _italic,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 0.5, color: p.textMuted),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _upper(L10n.t('app_tagline')),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: _ls(4),
                  color: p.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 20, height: 0.5, color: p.textMuted),
          ],
        ),
        const SizedBox(height: 14),
        Container(width: 40, height: 1, color: p.accent.withOpacity(0.6)),
      ],
    );
  }

  // ─────────────────────────────────────────
  // HERO PREVIEW
  // ─────────────────────────────────────────

  Widget _heroPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const gap = 14.0;
        final boardWidth = (totalWidth - gap) * 0.5;
        return SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: boardWidth, child: _boardPreview()),
              const SizedBox(width: gap),
              Expanded(child: _editionCard()),
            ],
          ),
        );
      },
    );
  }

  Widget _boardPreview() {
    return Container(
      decoration: BoxDecoration(
        color: p.board,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: p.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: AnimatedBuilder(
          animation: _boardPulse,
          builder: (_, __) => CustomPaint(
            painter: BoardPainter(
              snake: const [
                math.Point(2, 3),
                math.Point(3, 3),
                math.Point(4, 3),
                math.Point(5, 3),
                math.Point(5, 4),
                math.Point(5, 5),
                math.Point(4, 5),
              ],
              prevSnake: const [
                math.Point(2, 3),
                math.Point(3, 3),
                math.Point(4, 3),
                math.Point(5, 3),
                math.Point(5, 4),
                math.Point(5, 5),
                math.Point(4, 5),
              ],
              moveProgress: 1.0,
              food: const math.Point(8, 2),
              dir: const math.Point(1, 0),
              palette: p,
              pulse: _boardPulse.value,
              cols: 10,
              rows: 10,
              snakeSkin: _previewSnakeSkin, // ← جدید
              foodSkin: _previewFoodSkin, // ← جدید
              trail: _previewTrail, // ← جدید
              pattern: _previewPattern, // ← جدید
              patternIntensity: _previewIntensity, // ← جدید
              ghostSkin: GhostSkin.basic,
              timePhase: _boardPulse.value,
              showGrid: true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Widget _editionCard() {
    final level = PlayerProgressionService.levelFromXp(_playerXp);
    final isMaxLevel = level >= PlayerProgressionService.maxLevel;
    final xpInLevel =
        isMaxLevel ? 0 : PlayerProgressionService.xpCurrent(_playerXp);
    final xpToNext = isMaxLevel ? 0 : PlayerProgressionService.reqXP(level);

    final totalLevels = LevelsService.all.length;
    final remaining = (totalLevels - _completedLevels).clamp(0, totalLevels);
    final levelsProgress =
        totalLevels == 0 ? 0.0 : _completedLevels / totalLevels;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _upper(L10n.t('menu_theme')),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: _ls(3),
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: p.accent,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(width: 16, height: 1, color: p.accent),
              const SizedBox(height: 12),
              Text(
                'LV. $level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMaxLevel ? 'MAX' : '$xpInLevel / $xpToNext XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: p.textMuted,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _upper(L10n.t('menu_levels')),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: _ls(2),
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_completedLevels / $totalLevels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: LinearProgressIndicator(
                  value: levelsProgress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: p.border.withOpacity(0.4),
                  valueColor: AlwaysStoppedAnimation(p.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                L10n.tf('home_levels_remaining', {'n': remaining}),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: p.textMuted,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // DAILY REWARD BANNER
  // ─────────────────────────────────────────

  Widget _dailyRewardBanner() {
    return InkWell(
      onTap: _openDailyReward,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.t('menu_daily_reward_title'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: _ls(1.5),
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L10n.tf('menu_daily_reward_sub',
                        {'n': _rewardStatus?.rewardAmount ?? 0}),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: const Color(0xFFFFD700), size: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 16, height: 0.5, color: p.textMuted),
          const SizedBox(width: 10),
          Text(
            _upper(label),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: _ls(3),
              color: p.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 0.5, color: p.textMuted.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // DIFFICULTY
  // ─────────────────────────────────────────

  Widget _difficultySelector() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: Difficulty.values.asMap().entries.map((entry) {
        final index = entry.key;
        final d = entry.value;
        final selected = d == _difficulty;
        final isLast = index == Difficulty.values.length - 1;

        return Expanded(
          child: GestureDetector(
            onTap: () => _selectDifficulty(d),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: isLast ? 0 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? p.accent : Colors.transparent,
                          border: Border.all(
                            color: selected ? p.accent : p.border,
                            width: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _upper(d.label),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: _ls(1.5),
                            color: selected ? p.textPrimary : p.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: p.textMuted,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // CONTINUE (MAIN CTA)
  // ─────────────────────────────────────────

  Widget _continueButton() {
    return InkWell(
      onTap: _startFree,
      splashColor: p.accent.withOpacity(0.08),
      highlightColor: p.accent.withOpacity(0.03),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: p.accent.withOpacity(0.08),
          border: Border.all(color: p.accent, width: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                L10n.t('menu_free_play'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: _ls(1),
                  color: p.textPrimary,
                  fontStyle: _italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_rounded, color: p.accent, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SECONDARY
  // ─────────────────────────────────────────

  Widget _secondaryRow() {
    return Row(
      children: [
        Expanded(
          child: _secondaryButton(
            label: L10n.t('menu_levels_btn'),
            onTap: _openLevels,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _secondaryButton(
            label: L10n.t('menu_timed_btn'),
            onTap: _startTimeAttack,
          ),
        ),
      ],
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: p.border.withOpacity(0.7),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _upper(label),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: _ls(2),
            color: p.textPrimary,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // FOOTER STATS
  // ─────────────────────────────────────────

  Widget _footerStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.border, width: 0.5),
          bottom: BorderSide(color: p.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statColumn(
              label: L10n.t('menu_record'),
              value: '$_best',
              align: CrossAxisAlignment.start,
            ),
          ),
          Container(width: 0.5, height: 32, color: p.border),
          Expanded(
            child: _statColumn(
              label: L10n.t('menu_levels'),
              value: '$_completedLevels',
              align: CrossAxisAlignment.center,
            ),
          ),
          Container(width: 0.5, height: 32, color: p.border),
          Expanded(
            child: _statColumn(
              label: L10n.t('menu_timed'),
              value: '$_timeAttackBest',
              align: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn({
    required String label,
    required String value,
    required CrossAxisAlignment align,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          _upper(label),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: _ls(2),
            color: p.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            color: p.textPrimary,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // THEME
  // ─────────────────────────────────────────

  Widget _themeRow() {
    return InkWell(
      onTap: _cyclePalette,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              _upper(L10n.t('menu_theme')),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: _ls(2),
                color: p.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 0.5,
                color: p.border.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                  fontStyle: _italic,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.refresh_rounded, color: p.textMuted, size: 13),
          ],
        ),
      ),
    );
  }
}
