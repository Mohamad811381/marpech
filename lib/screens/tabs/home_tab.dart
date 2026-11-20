// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:marpech/models/chapter.dart';
import 'package:marpech/screens/missions_screen.dart';
import 'package:marpech/services/performance_service.dart';
import 'package:marpech/services/theme_service.dart';
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
import '../../services/achievements_service.dart';
import '../achievements_screen.dart';
import '../../services/missions_service.dart';

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

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  Difficulty _difficulty = Difficulty.normal;
  int _best = 0;
  int _timeAttackBest = 0;
  bool _loaded = false;
  int _completedLevels = 0;
  Set<int> _completedIds = {};
  int _coins = 0;
  DailyRewardStatus? _rewardStatus;
  int _playerXp = 0;
  int _unlockedAchievements = 0;
  int _claimableMissions = 0;
  double _missionsRatio = 0;

  // 🎞️ مقایسه‌ی قبل و بعد از بازی
  int _prevCompletedLevels = 0;
  bool _snapshotTaken = false;
  int _gainedLevels = 0;
  bool _showGain = false;
  late final AnimationController _numberAnim;
  late final AnimationController _dotPulse;
  // شماره‌ی مرحله‌ای که در این بازی تازه تمام شده (برای پالس نقطه)
  int? _freshDoneId;

  // اسکین‌های پیش‌نمایش (از انتخاب‌های کاربر)
  SnakeSkin _previewSnakeSkin = SnakeSkin.basic;
  FoodSkin _previewFoodSkin = FoodSkin.basic;
  TrailEffect _previewTrail = TrailEffect.none;
  BoardPattern _previewPattern = BoardPattern.none;
  PatternIntensity _previewIntensity = PatternIntensity.subtle;

  static const _previewSnake = [
    math.Point(2, 3),
    math.Point(3, 3),
    math.Point(4, 3),
    math.Point(5, 3),
    math.Point(5, 4),
    math.Point(5, 5),
    math.Point(4, 5),
  ];

  late final AnimationController _boardPulse;
  late final AnimationController _pulse;
  late final AnimationController _enter;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  final _audio = AudioService();
  GamePalette get p => widget.palette;

  // ── Helpers برای i18n ──
  double _ls(double english) => L10n.isFa ? 0.3 : english;
  FontStyle get _italic => L10n.isFa ? FontStyle.normal : FontStyle.italic;
  String _upper(String s) => L10n.isFa ? s : s.toUpperCase();

  bool get _animationsEnabled =>
      PerformanceService.effective != EffectiveQuality.low;

  @override
  void initState() {
    super.initState();
    PlayerProgressionService.pendingLevelUps.addListener(_onProgressionChanged);

    _boardPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _enterFade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();

    _numberAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.of(context) && _animationsEnabled;

    if (enabled) {
      if (!_boardPulse.isAnimating) _boardPulse.repeat();
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _boardPulse.stop();
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    PlayerProgressionService.pendingLevelUps
        .removeListener(_onProgressionChanged);
    _boardPulse.dispose();
    _pulse.dispose();
    _enter.dispose();
    _numberAnim.dispose();
    _dotPulse.dispose();
    super.dispose();
  }

  void _onProgressionChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([
      StorageService.getDifficultyIndex(), // 0
      StorageService.getTimeAttackBest(), // 1
      LevelsService.getCompleted(), // 2
      ShopService.getCoins(), // 3
      DailyRewardService.getStatus(), // 4
      StorageService.getPlayerXpTotal(), // 5
      ShopService.getSelectedSnakeSkin(), // 6
      ShopService.getSelectedFoodSkin(), // 7
      ShopService.getSelectedTrail(), // 8
      ShopService.getSelectedPattern(), // 9
      ShopService.getPatternIntensity(), // 10
    ]);

    final d = results[0] as int;
    final diff = Difficulty.values[d.clamp(0, Difficulty.values.length - 1)];
    final b = await StorageService.getBestScore(diff);
    final unlockedAch = await AchievementsService.unlockedCount();
    final claimableMissions = await MissionsService.claimableCount();
    final allMissions = await MissionsService.getAllProgress();
    final missionsRatio = allMissions.isEmpty
        ? 0.0
        : allMissions.map((m) => m.ratio).reduce((a, b) => a + b) /
            allMissions.length;
    if (!mounted) return;
    setState(() {
      _difficulty = diff;
      _best = b;
      _timeAttackBest = results[1] as int;
      _completedIds = Set<int>.from(results[2] as Iterable);
      _completedLevels = _completedIds.length;
      _coins = results[3] as int;
      _rewardStatus = results[4] as DailyRewardStatus;
      _playerXp = results[5] as int;
      _unlockedAchievements = unlockedAch;
      _claimableMissions = claimableMissions;
      _missionsRatio = missionsRatio;
      _previewSnakeSkin = SnakeSkin.fromId(results[6] as String);
      _previewFoodSkin = FoodSkin.fromId(results[7] as String);
      _previewTrail = TrailEffect.fromId(results[8] as String);
      _previewPattern = BoardPattern.fromId(results[9] as String);
      _previewIntensity = PatternIntensity.fromId(results[10] as String);
      _loaded = true;
      _compareAfterGame();
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
    final isLight = ThemeService.isLight(context);

    if (isLight) {
      final currentId = ThemeService.lightPaletteId.value;
      final currentIdx = lightPalettes.indexWhere((p) => p.id == currentId);
      final next = lightPalettes[(currentIdx + 1) % lightPalettes.length];
      await ThemeService.setLightPalette(next);
    } else {
      final unlocked = await ShopService.getUnlockedThemes();
      final currentId = ThemeService.darkPalette.value.id;
      final currentIdx = palettes.indexWhere((p) => p.id == currentId);
      var nextIdx = currentIdx;
      for (var i = 1; i <= palettes.length; i++) {
        final idx = (currentIdx + i) % palettes.length;
        if (unlocked.contains(palettes[idx].id)) {
          nextIdx = idx;
          break;
        }
      }
      await ThemeService.setDarkPalette(palettes[nextIdx]);
    }

    widget.onPaletteChanged();
    if (mounted) setState(() {});
  }

  Future<void> _startFree() async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    _snapshotBeforeGame();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(difficulty: _difficulty, palette: p),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _startTimeAttack() async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    _snapshotBeforeGame();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: _difficulty,
          palette: p,
          timeLimit: const Duration(seconds: 60),
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openLevels() async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    _snapshotBeforeGame();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChaptersScreen(
          palette: p,
          difficulty: _difficulty,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  /// قبل از رفتن به بازی وضعیت فعلی رو ذخیره می‌کنه
  void _snapshotBeforeGame() {
    _prevCompletedLevels = _completedLevels;
    _snapshotTaken = true;
  }

  /// بعد از برگشت از بازی مقایسه می‌کنه و انیمیشن‌های عدد و نقطه رو اجرا می‌کنه.
  void _compareAfterGame() {
    if (!_snapshotTaken) return;
    _snapshotTaken = false;

    final levelGain = _completedLevels - _prevCompletedLevels;
    if (levelGain <= 0) return;

    _gainedLevels = levelGain;
    _showGain = true;

    // تازه‌ترین مرحله‌ی تمام‌شده: بزرگ‌ترین شماره‌ی جدید
    _freshDoneId = _completedIds
        .where((id) => id > _prevCompletedLevels)
        .fold<int?>(null, (acc, id) => acc == null || id > acc ? id : acc);

    if (_animationsEnabled) {
      _numberAnim.forward(from: 0);
      _dotPulse.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _showGain = false);
    });
  }

  Future<void> _openAchievements() async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AchievementsScreen(palette: p),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openMissions() async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionsScreen(palette: p),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _playNextLevel() async {
    final total = LevelsService.all.length;
    final level = _completedIds.length >= total
        ? null
        : LevelsService.getById(_nextLevelId(total));

    // اگه همه‌ی مراحل تمام شده، فقط فصل‌ها رو باز کن
    if (level == null) {
      await _openLevels();
      return;
    }

    await _audio.playSfx(Sfx.button);
    if (!mounted) return;
    _snapshotBeforeGame();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: _difficulty,
          palette: p,
          level: level,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openDailyReward() async {
    await _audio.playSfx(Sfx.button);
    if (!mounted) return;

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

    if (!mounted) return;
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
          const SizedBox(height: 22),
          _levelHero(),
          const SizedBox(height: 14),
          if (_rewardStatus?.canClaimToday == true) ...[
            _dailyRewardBanner(),
            const SizedBox(height: 14),
          ],
          _sectionHeader(L10n.t('home_select_difficulty')),
          _difficultySelector(),
          const SizedBox(height: 22),
          _modeCards(),
          const SizedBox(height: 22),
          _statChips(),
          const SizedBox(height: 18),
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
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: p.food, size: 18),
            const SizedBox(width: 6),
            Text(
              '$_coins',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.food,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HERO: ادامه‌ی ماجرا
  // ─────────────────────────────────────────

  Widget _levelHero() {
    final totalLevels = LevelsService.all.length;
    final nextLevel = _nextLevelId(totalLevels);
    final progress = totalLevels == 0
        ? 0.0
        : (_completedLevels / totalLevels).clamp(0.0, 1.0);
    final allDone = _completedLevels >= totalLevels;

    return FadeTransition(
      opacity: _enterFade,
      child: SlideTransition(
        position: _enterSlide,
        child: InkWell(
          onTap: _openLevels,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.accent.withOpacity(0.22),
                  p.surface,
                ],
              ),
              border: Border.all(color: p.accent.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withOpacity(0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _upper(allDone
                            ? L10n.t('home_done')
                            : L10n.t('home_next_level')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: p.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _animatedNumber(
                        allDone ? L10n.t('home_all_done') : '$nextLevel',
                      ),
                      if (_showGain)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            L10n.tf('home_gain_level', {'n': _gainedLevels}),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: p.accent,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: p.border.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation(p.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        L10n.tf('home_levels_progress', {
                          'done': _completedLevels,
                          'total': totalLevels,
                        }),
                        style: TextStyle(fontSize: 11, color: p.textMuted),
                      ),
                      const SizedBox(height: 12),
                      _chapterDots(),
                      const SizedBox(height: 14),
                      _continueCta(),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(width: 128, child: _boardTile()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// عدد بزرگ مرحله. عدد همیشه کامل دیده می‌شه؛ انیمیشن فقط جابه‌جایی کوچیکه.
  Widget _animatedNumber(String text) {
    final number = Text(
      text,
      style: TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.w900,
        height: 1.0,
        color: p.textPrimary,
      ),
    );

    if (!_animationsEnabled) return number;

    return AnimatedBuilder(
      animation: _numberAnim,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_numberAnim.value);
        return Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        );
      },
      child: number,
    );
  }

  Widget _continueCta() {
    return InkWell(
      onTap: _playNextLevel,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(
          scale: 1.0 + _pulse.value * 0.03,
          child: child,
        ),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: p.accent.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.t('home_continue'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: p.bg,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.play_arrow_rounded, color: p.bg, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// اولین مرحله‌ای که هنوز تمام نشده
  int _nextLevelId(int total) {
    for (var i = 1; i <= total; i++) {
      if (!_completedIds.contains(i)) return i;
    }
    return total;
  }

  /// فصلی که مرحله‌ی بعدی در آن قرار دارد
  Chapter _currentChapter(int nextId) {
    const chapters = LevelsService.chapters;
    return chapters.firstWhere(
      (c) => nextId >= c.startLevelId && nextId <= c.endLevelId,
      orElse: () => chapters.last,
    );
  }

  /// ردیف نقطه‌های مراحل فصل فعلی
  Widget _chapterDots() {
    final total = LevelsService.all.length;
    final nextId = _nextLevelId(total);
    final chapter = _currentChapter(nextId);
    final ids = [
      for (var i = chapter.startLevelId; i <= chapter.endLevelId; i++) i,
    ];

    return Row(
      children: [
        for (var k = 0; k < ids.length; k++) ...[
          _levelDot(
            id: ids[k],
            done: _completedIds.contains(ids[k]),
            isNext: ids[k] == nextId,
          ),
          if (k < ids.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: _completedIds.contains(ids[k])
                    ? p.accent
                    : p.border.withOpacity(0.6),
              ),
            ),
        ],
      ],
    );
  }

  Widget _levelDot({
    required int id,
    required bool done,
    required bool isNext,
  }) {
    const double size = 8;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? p.accent : Colors.transparent,
        border: Border.all(
          color: (done || isNext) ? p.accent : p.border,
          width: 1.2,
        ),
      ),
    );

    // نقطه‌ی تازه‌تمام‌شده: یک پالس کوتاه
    if (id == _freshDoneId && _animationsEnabled) {
      return SizedBox(
        width: 14,
        height: 14,
        child: Center(
          child: AnimatedBuilder(
            animation: _dotPulse,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + (1 - _dotPulse.value) * 0.5,
              child: child,
            ),
            child: dot,
          ),
        ),
      );
    }

    if (!isNext) {
      return SizedBox(width: 12, height: 12, child: Center(child: dot));
    }

    // مرحله‌ی بعدی: کمی بزرگ‌تر و با نبض آرام
    return SizedBox(
      width: 14,
      height: 14,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + _pulse.value * 0.35,
            child: child,
          ),
          child: dot,
        ),
      ),
    );
  }

  /// تخته‌ی پیش‌نمایش: حتماً مربعی تا شبکه و مار درست کشیده بشن.
  Widget _boardTile() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.board,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border.withOpacity(0.6), width: 0.5),
        ),
        child: AnimatedBuilder(
          animation: _boardPulse,
          builder: (_, __) => CustomPaint(
            painter: BoardPainter(
              snake: _previewSnake,
              prevSnake: _previewSnake,
              moveProgress: 1.0,
              food: const math.Point(8, 2),
              dir: const math.Point(1, 0),
              palette: p,
              pulse: _boardPulse.value,
              cols: 10,
              rows: 10,
              snakeSkin: _previewSnakeSkin,
              foodSkin: _previewFoodSkin,
              trail: _previewTrail,
              pattern: _previewPattern,
              patternIntensity: _previewIntensity,
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

  // ─────────────────────────────────────────
  // DAILY REWARD BANNER
  // ─────────────────────────────────────────

  Widget _dailyRewardBanner() {
    return InkWell(
      onTap: _openDailyReward,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.food.withOpacity(0.08),
          border: Border.all(color: p.food.withOpacity(0.5), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.food,
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: p.food,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: p.food, size: 16),
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
      padding: const EdgeInsets.only(bottom: 12),
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
  // DIFFICULTY (segmented)
  // ─────────────────────────────────────────

  Widget _difficultySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withOpacity(0.6), width: 0.5),
      ),
      child: Row(
        children: Difficulty.values.map((d) {
          final selected = d == _difficulty;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDifficulty(d),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _upper(d.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: _ls(1.5),
                    color: selected ? p.bg : p.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // MODE CARDS
  // ─────────────────────────────────────────
  Widget _modeCards() {
    return Row(
      children: [
        Expanded(
          child: _modeCard(
            lottieAsset: 'assets/lottie/free_play.json',
            title: L10n.t('menu_free_play'),
            tag: L10n.t('home_mode_endless'),
            record: _best,
            onTap: _startFree,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _modeCard(
            lottieAsset: 'assets/lottie/clock.json',
            title: L10n.t('menu_timed_btn'),
            tag: L10n.t('home_mode_60s'),
            record: _timeAttackBest,
            onTap: _startTimeAttack,
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required String lottieAsset,
    required String title,
    required String tag,
    required int record,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.accent.withOpacity(0.25),
              p.surface,
            ],
          ),
          border: Border.all(color: p.accent.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: p.accent.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _animationsEnabled
                      ? Lottie.asset(
                          lottieAsset,
                          repeat: true,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.play_arrow_rounded,
                          color: p.accent, size: 32),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: p.accent.withOpacity(0.15),
                  ),
                  child: Text(
                    _upper(tag),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: _ls(1),
                      color: p.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _upper(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: _ls(1),
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$record',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    _upper(L10n.t('menu_record')),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: _ls(1.2),
                      color: p.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  } // ─────────────────────────────────────────
  // STAT CHIPS
  // ─────────────────────────────────────────

  Widget _statChips() {
    final level = PlayerProgressionService.levelFromXp(_playerXp);
    final isMax = level >= PlayerProgressionService.maxLevel;

    final inLevel = isMax ? 0 : PlayerProgressionService.xpCurrent(_playerXp);
    final req = isMax ? 1 : math.max(1, PlayerProgressionService.reqXP(level));
    final xpLeft = isMax ? 0 : req - inLevel;
    final progress = isMax ? 1.0 : (inLevel / req).clamp(0.0, 1.0);

    // 📱 ریسپانسیو: عرض هر کاشی ≈ (عرض صفحه - پدینگ - فاصله‌ها) / 3
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 64) / 3; // 44 پدینگ + 20 فاصله
    final iconSize = (tileWidth * 0.45).roundToDouble().clamp(40.0, 56.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ProgressTile(
              palette: p,
              iconSize: iconSize,
              letterSpacing: _ls(1.2),
              animationsEnabled: _animationsEnabled,
              icon: Icons.flag_outlined,
              lottieAsset: 'assets/lottie/mission.json',
              value: '${(_missionsRatio * 100).round()}%',
              label: _upper(_claimableMissions > 0
                  ? L10n.t('home_stat_ready')
                  : L10n.t('home_stat_missions')),
              onTap: _openMissions,
              progress: _missionsRatio,
              highlight: _claimableMissions > 0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProgressTile(
              palette: p,
              iconSize: iconSize,
              letterSpacing: _ls(1.2),
              animationsEnabled: _animationsEnabled,
              icon: Icons.stars_rounded,
              lottieAsset: 'assets/lottie/achievement.json',
              value: '$_unlockedAchievements',
              label: _upper(L10n.t('home_stat_achievements')),
              onTap: _openAchievements,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProgressTile(
              palette: p,
              iconSize: iconSize,
              letterSpacing: _ls(1.2),
              animationsEnabled: _animationsEnabled,
              icon: Icons.trending_up_rounded,
              lottieAsset: 'assets/lottie/trending.json', // اگه داری
              value: isMax ? 'MAX' : '$xpLeft',
              label: _upper(L10n.t('home_stat_xp_next')),
              progress: progress,
            ),
          ),
        ],
      ),
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

class _ProgressTile extends StatefulWidget {
  final GamePalette palette;
  final IconData icon;
  final String value;
  final String label;
  final double iconSize;
  final double letterSpacing;
  final bool animationsEnabled;
  final VoidCallback? onTap;
  final double? progress;
  final bool highlight;
  final String? lottieAsset;

  const _ProgressTile({
    required this.palette,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconSize,
    required this.letterSpacing,
    required this.animationsEnabled,
    this.onTap,
    this.progress,
    this.highlight = false,
    this.lottieAsset,
  });

  @override
  State<_ProgressTile> createState() => _ProgressTileState();
}

class _ProgressTileState extends State<_ProgressTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieCtrl;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // پیش‌فرض تا onLoaded بیاد
    );
  }

  @override
  void dispose() {
    _lottieCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_playing) return;

    // انیمیشن همیشه پخش می‌شه (حتی اگه onTap نداشته باشه)
    if (widget.lottieAsset != null && widget.animationsEnabled) {
      setState(() => _playing = true);
      try {
        await _lottieCtrl.forward(from: 0);
      } finally {
        if (mounted) setState(() => _playing = false);
      }
      if (!mounted) return;
    }

    // ناوبری فقط اگه onTap داده شده باشه
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.highlight ? p.accent : p.border.withOpacity(0.6),
            width: widget.highlight ? 1.2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.iconSize,
              height: widget.iconSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: widget.iconSize * 0.8,
                    height: widget.iconSize * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent.withOpacity(0.15),
                    ),
                  ),
                  if (widget.lottieAsset != null)
                    OverflowBox(
                      maxWidth: widget.iconSize * 1.05,
                      maxHeight: widget.iconSize * 1.05,
                      child: Lottie.asset(
                        widget.lottieAsset!,
                        controller: _lottieCtrl,
                        fit: BoxFit.contain,
                        onLoaded: (comp) {
                          _lottieCtrl.duration = comp.duration;
                        },
                      ),
                    )
                  else
                    Icon(
                      widget.icon,
                      size: widget.iconSize * 0.45,
                      color: p.accent,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: widget.letterSpacing,
                    color: p.textMuted,
                  ),
                ),
              ),
            ),
            if (widget.progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 3,
                  backgroundColor: p.border.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation(p.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
