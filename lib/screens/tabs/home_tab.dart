// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
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
import '../../models/skins.dart';
import '../../models/board_pattern.dart';
import '../../services/achievements_service.dart';
import '../achievements_screen.dart';
import '../../services/missions_service.dart';

import 'home/home_helpers.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/level_hero.dart';
import 'home/widgets/daily_reward_banner.dart';
import 'home/widgets/section_header.dart';
import 'home/widgets/difficulty_selector.dart';
import 'home/widgets/stat_chips.dart';
import 'home/widgets/theme_row.dart';
import 'home/widgets/mode_card.dart';

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

  late final AnimationController _boardPulse;
  late final AnimationController _pulse;
  late final AnimationController _enter;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  final _audio = AudioService();
  GamePalette get p => widget.palette;

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

  /// اولین مرحله‌ای که هنوز تمام نشده
  int _nextLevelId(int total) {
    for (var i = 1; i <= total; i++) {
      if (!_completedIds.contains(i)) return i;
    }
    return total;
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
          HomeHeader(
            palette: p,
            xpTotal: _playerXp,
            coins: _coins,
            onLevelBadgeTap: widget.onLevelBadgeTap,
            onMenuTap: () {
              _audio.playSfx(Sfx.button);
              Scaffold.of(context).openDrawer();
            },
          ),
          const SizedBox(height: 22),
          LevelHero(
            palette: p,
            completedLevels: _completedLevels,
            completedIds: _completedIds,
            nextLevel: _nextLevelId(LevelsService.all.length),
            showGain: _showGain,
            gainedLevels: _gainedLevels,
            freshDoneId: _freshDoneId,
            animationsEnabled: _animationsEnabled,
            enterFade: _enterFade,
            enterSlide: _enterSlide,
            numberAnim: _numberAnim,
            dotPulse: _dotPulse,
            pulse: _pulse,
            boardPulse: _boardPulse,
            snakeSkin: _previewSnakeSkin,
            foodSkin: _previewFoodSkin,
            trail: _previewTrail,
            pattern: _previewPattern,
            intensity: _previewIntensity,
            onOpenLevels: _openLevels,
            onContinue: _playNextLevel,
          ),
          const SizedBox(height: 14),
          if (_rewardStatus?.canClaimToday == true) ...[
            DailyRewardBanner(
              palette: p,
              rewardAmount: _rewardStatus?.rewardAmount ?? 0,
              onTap: _openDailyReward,
            ),
            const SizedBox(height: 14),
          ],
          SectionHeader(
            palette: p,
            label: L10n.t('home_select_difficulty'),
          ),
          DifficultySelector(
            palette: p,
            difficulty: _difficulty,
            onSelected: _selectDifficulty,
          ),
          const SizedBox(height: 22),
          _modeCards(),
          const SizedBox(height: 22),
          StatChips(
            palette: p,
            playerXp: _playerXp,
            missionsRatio: _missionsRatio,
            claimableMissions: _claimableMissions,
            unlockedAchievements: _unlockedAchievements,
            animationsEnabled: _animationsEnabled,
            onOpenMissions: _openMissions,
            onOpenAchievements: _openAchievements,
          ),
          const SizedBox(height: 18),
          ThemeRow(palette: p, onTap: _cyclePalette),
          const SizedBox(height: 10),
        ],
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
          child: ModeCard(
            palette: p,
            lottieAsset: 'assets/lottie/free_play.json',
            title: homeUpper(L10n.t('menu_free_play')),
            tag: homeUpper(L10n.t('home_mode_endless')),
            record: _best,
            recordLabel: homeUpper(L10n.t('menu_record')),
            letterSpacing: homeLs(1),
            animationsEnabled: _animationsEnabled,
            onTap: _startFree,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ModeCard(
            palette: p,
            lottieAsset: 'assets/lottie/clock.json',
            title: homeUpper(L10n.t('menu_timed_btn')),
            tag: homeUpper(L10n.t('home_mode_60s')),
            record: _timeAttackBest,
            recordLabel: homeUpper(L10n.t('menu_record')),
            letterSpacing: homeLs(1),
            animationsEnabled: _animationsEnabled,
            onTap: _startTimeAttack,
          ),
        ),
      ],
    );
  }
}
