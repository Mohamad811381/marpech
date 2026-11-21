// ignore_for_file: curly_braces_in_flow_control_structures, unused_element, prefer_const_constructors, prefer_const_declarations, deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marpech/models/board_pattern.dart';
import 'package:marpech/services/shop_service.dart';
import '../models/achievement.dart';
import '../models/difficulty.dart';
import '../models/game_history_entry.dart';
import '../models/game_palette.dart';
import '../models/game_settings.dart';
import '../models/level.dart';
import '../models/power_up.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/daily_challenges_service.dart';
import '../services/ghost_service.dart';
import '../services/history_service.dart';
import '../services/levels_service.dart';
import '../services/localization_service.dart';
import '../services/missions_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/board_painter.dart';
import '../widgets/dpad.dart';
import '../widgets/particle_painter.dart';
import '../widgets/stat_card.dart';
import '../models/skins.dart';
import '../models/portal.dart';
import '../widgets/virtual_joystick.dart';
import 'winner_screen.dart';
import '../services/performance_service.dart';
import '../models/intro_animation.dart';
import '../widgets/intro_overlay.dart';
import '../services/player_progression_service.dart';
import 'game/game_hud.dart';
import 'game/game_overlays.dart';
import 'game/game_shake_wrapper.dart';
import '../services/app_haptics.dart';
part 'game/game_route_logic.dart';
part 'game/game_respawn_logic.dart';
part 'game/game_xp_logic.dart';
part 'game/game_board_view.dart';
part 'game/game_end_logic.dart';
part 'game/game_input_logic.dart';
part 'game/game_effects_logic.dart';

/// 🐢 ضریب سرعت مخصوص مراحل — 1.0 = عادی، 2.0 = دو برابر کندتر
const double kLevelSpeedMultiplier = 1;
const int cols = 20;
const int rows = 20;

const int _maxShields = 3;
const Duration _slowDuration = Duration(seconds: 5);
const Duration _maxSlowDuration = Duration(seconds: 15);
const double _comboMultiplierValue = 1.5;

const int _shieldSimMaxDepth = 25;
const Duration _shieldFreezeDuration = Duration(milliseconds: 250);

const int _dangerEpisodeSafeSteps = 8;

const int _emergencyRescuePrice = 300;
const Duration _ghostDuration = Duration(seconds: 3);
const Duration _ghostExtension = Duration(seconds: 1);

const Duration _recoverySlowDuration = Duration(seconds: 3);

const List<int> _continuePrices = [50, 100, 200];

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final GamePalette palette;
  final Level? level;
  final Duration? timeLimit;

  const GameScreen({
    super.key,
    required this.difficulty,
    required this.palette,
    this.level,
    this.timeLimit,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  SnakeSkin _snakeSkin = SnakeSkin.basic;
  GhostSkin _ghostSkin = GhostSkin.basic;
  IntroAnimation _introAnimation = IntroAnimation.none;
  FoodSkin _foodSkin = FoodSkin.basic;
  TrailEffect _trail = TrailEffect.none;
  BoardPattern _pattern = BoardPattern.none;
  PatternIntensity _patternIntensity = PatternIntensity.subtle;

  final math.Random _rng = math.Random();
  final FocusNode _focus = FocusNode();
  final AudioService _audio = AudioService();
  late final AnimationController _pulse;
  late final AnimationController _particles;
  late final AnimationController _moveAnim;
  late final AnimationController _rainbow;
  late final AnimationController _shake;
  late final AnimationController _wrapAnim;
  late final AnimationController _comboFlash;

  ParticleBurst? _currentBurst;
  WrapEvent? _wrapEvent;

  GhostRecording? _ghostRecording;
  List<int> _currentRecording = [];
  int _playerStateIndex = 0;

  late List<math.Point<int>> _snake;
  List<math.Point<int>> _prevSnake = [];
  late math.Point<int> _food;
  math.Point<int> _dir = const math.Point(0, -1);
  math.Point<int> _queued = const math.Point(0, -1);
  Timer? _timer;
  Timer? _slowTimer;
  Timer? _slowTickTimer;
  Timer? _countdownTimer;
  late final AnimationController _introAnim;
  bool _isIntroPlaying = false;
  Duration _tick = const Duration(milliseconds: 150);
  int _score = 0;
  int _best = 0;
  int _secondsLeft = 0;
  bool _over = false;
  bool _paused = false;
  bool _newRecord = false;
  bool _won = false;
  int _foodsEaten = 0;
  List<Achievement> _newAchievements = [];

  PowerUp? _currentPowerUp;
  int _shieldCount = 0;
  int _pityCount = 0;

  String? _gameSessionId;
  bool _gameXpCommitted = false;
  bool _levelXpCommitted = false;
  bool _winInProgress = false;

  DateTime? _slowUntil;
  int _slowRemaining = 0;
  bool _wasComboActive = false;

  // 📊 چالش‌ها/ماموریت‌ها
  int _foodsThisGame = 0;
  int _goldenApplesEaten = 0;
  int _combosThisGame = 0;
  bool _everHadShield = false;
  bool _everHadSlow = false;

  double _shakeIntensity = 1.0;
  // 💥 شمارش معکوس پایان
  int _endCountdown = 0;
  Timer? _endCountdownTimer;
  bool get _isEnding => _endCountdown > 0;
  // 🎬 شمارش معکوس شروع
  int _countdown = 0;
  Timer? _startCountdownTimer;
  // 🛡️ Smart Shield Recovery

  bool _isRecovering = false;
  bool _showShieldFlash = false;
  Timer? _shieldRecoveryTimer;

  // تعداد حرکت‌های موفق پس از آخرین نجات با سپر؛
  // اگر قبل از ۸ حرکت دوباره برخورد کنیم، هنوز همان موقعیت خطرناک محسوب می‌شود.
  int _safeStepsAfterShieldRecovery = 0;
  // 🚨 Emergency Rescue

  bool _isShowingEmergencyDialog = false;
  bool _emergencyUsedThisSession = false;
  bool _ghostActive = false;
  bool _isEmergencyRecovery = false; // ← جدید
  Timer? _ghostTimer;
  // 🐢 Recovery Slow
  DateTime? _recoverySlowUntil;
  Timer? _recoverySlowTimer;

  bool get _isRecoverySlowActive =>
      _recoverySlowUntil != null &&
      DateTime.now().isBefore(_recoverySlowUntil!);

  bool get _isStarting => _countdown > 0;
  // 🪙 Continue
  int _continueCount = 0;
  int _currentCoins = 0;
  bool _isShowingContinueDialog = false;

  GamePalette get p => widget.palette;
  Difficulty get d => widget.difficulty;
  bool get _isLevelMode => widget.level != null;
  bool get _isTimeAttack => widget.timeLimit != null;

  // ⏱️ فصل ۴ — مرحله‌ی زمان‌دار
  bool get _isTimedLevel => widget.level?.isTimed ?? false;
  bool get _isAnyTimed => _isTimeAttack || _isTimedLevel;

  Duration? get _activeTimeLimit =>
      _isTimeAttack ? widget.timeLimit : widget.level?.timeLimit;

  Set<math.Point<int>> get _walls =>
      widget.level?.walls ?? LevelsService.freePlayWalls(d);
  List<PortalPair> get _portals => widget.level?.portals ?? const [];

  Point<int>? _getPortalDestination(math.Point<int> pos) {
    for (final pair in _portals) {
      final dest = pair.destination(pos);
      if (dest != null) return dest;
    }
    return null;
  }

  bool get _isSlowActive =>
      _slowUntil != null && DateTime.now().isBefore(_slowUntil!);

  bool get _isComboActive => _shieldCount > 0 && _isSlowActive;
  double get _comboMultiplier => _isComboActive ? _comboMultiplierValue : 1.0;

  // ⏱️ برای هر دو حالت (Time Attack + فصل ۴)
  bool get _timedOut => _isAnyTimed && _secondsLeft <= 0;
  bool get _canRunClock =>
      _isAnyTimed && _secondsLeft > 0 && !_isStarting && !_isEnding;

  int get _pityShields {
    if (!_isLevelMode) return 0;
    return StorageService.pityShieldsForCount(_pityCount);
  }

  int get _continueCost => _continueCount < _continuePrices.length
      ? _continuePrices[_continueCount]
      : 0;

  bool get _canContinue =>
      !_isLevelMode && _continueCount < _continuePrices.length;

  int get _pityStage {
    if (_pityCount >= 4) return 4;
    return _pityCount;
  }

  double get _chapterSpeedMultiplier {
    if (!_isLevelMode) return 1.0;
    final id = widget.level!.id;
    if (id <= 10) return 1.0; // 🟢 فصل ۱
    if (id <= 20) return 1.15; // 🟡 فصل ۲
    if (id <= 30) return 1.30; // 🟣 فصل ۳
    return 1.20; // 🔴 فصل ۴
  }

  Duration _baseTick() {
    if (_isLevelMode) {
      final base = widget.level!.tick.inMilliseconds * kLevelSpeedMultiplier;
      return Duration(
        milliseconds: (base / _chapterSpeedMultiplier).round(),
      );
    }
    return d.tick;
  }

  static final Map<LogicalKeyboardKey, math.Point<int>> _keyMap = {
    LogicalKeyboardKey.arrowUp: const math.Point(0, -1),
    LogicalKeyboardKey.keyW: const math.Point(0, -1),
    LogicalKeyboardKey.arrowDown: const math.Point(0, 1),
    LogicalKeyboardKey.keyS: const math.Point(0, 1),
    LogicalKeyboardKey.arrowLeft: const math.Point(-1, 0),
    LogicalKeyboardKey.keyA: const math.Point(-1, 0),
    LogicalKeyboardKey.arrowRight: const math.Point(1, 0),
    LogicalKeyboardKey.keyD: const math.Point(1, 0),
  };

  @override
  void initState() {
    super.initState();
    PlayerProgressionService.blockDialogsFor(this); // ← Stage 4
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // بعد از شروع بازی شروع می‌شه
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _moveAnim = AnimationController(
      vsync: this,
      duration: d.tick,
      value: 1.0,
    );
    _introAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _moveAnim.duration = _baseTick();
    _rainbow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // فقط اگه رنگین‌کمان فعاله بچرخه — بعد از load تنظیمات در _initGame
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1.0,
    );
    _wrapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1.0,
    );
    _comboFlash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: 1.0,
    );
    _initGame();
  }

  @override
  void dispose() {
    PlayerProgressionService.unblockDialogsFor(this); // ← Stage 4
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _countdownTimer?.cancel();
    _endCountdownTimer?.cancel();
    _startCountdownTimer?.cancel();
    _shieldRecoveryTimer?.cancel();
    _ghostTimer?.cancel();
    _recoverySlowTimer?.cancel();
    _pulse.dispose();
    _introAnim.dispose();
    _particles.dispose();
    _moveAnim.dispose();
    _rainbow.dispose();
    _shake.dispose();
    _wrapAnim.dispose();
    _comboFlash.dispose();
    _focus.dispose();
    _audio.stopMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!_over && !_won && !_paused) {
        setState(() => _paused = true);
        _countdownTimer?.cancel();
      }
      _audio.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      if (!_over && !_won) {
        // اگه بازی pause بود، خودکار resume شه
        if (_paused) {
          setState(() => _paused = false);
        }
        if (!_pulse.isAnimating) _pulse.repeat();
        _audio.resumeMusic();

        // تایمر رو فقط وقتی از سر بگیر که بازی واقعاً شروع شده باشد
        if (_canRunClock) {
          _startCountdown();

          // Safety: restart timer if it might have stopped
          if (!_isRecovering &&
              !_isShowingContinueDialog &&
              !_isShowingEmergencyDialog) {
            _timer?.cancel();
            _restartTimer();
          }
        }
      }
    }
  }
  // ---------- منطق بازی ----------

  Future<void> _initGame() async {
    if (_isTimeAttack) {
      _best = await StorageService.getTimeAttackBest();
    } else if (!_isLevelMode) {
      _best = await StorageService.getBestScore(d);
    }
    if (_isLevelMode) {
      _pityCount = await StorageService.getPityCount(widget.level!.id);
    }

    // 🎨 بارگذاری اسکین‌های انتخاب‌شده از فروشگاه
    final snakeSkinId = await ShopService.getSelectedSnakeSkin();
    final ghostSkinId = await ShopService.getSelectedGhostSkin();
    final foodSkinId = await ShopService.getSelectedFoodSkin();
    final trailId = await ShopService.getSelectedTrail();
    final patternId = await ShopService.getSelectedPattern();
    final intensityId = await ShopService.getPatternIntensity();
    _pattern = BoardPattern.fromId(patternId);
    _patternIntensity = PatternIntensity.fromId(intensityId);
    _trail = TrailEffect.fromId(trailId);
    _foodSkin = FoodSkin.fromId(foodSkinId);
    _snakeSkin = SnakeSkin.fromId(snakeSkinId);
    _ghostSkin = GhostSkin.fromId(ghostSkinId);
    final introId = await ShopService.getSelectedIntro();
    _introAnimation = IntroAnimation.fromId(introId);

    // 🌈 شروع rainbow فقط اگه لازمه (بهینه‌سازی)
    final needsRainbow = _snakeSkin == SnakeSkin.rainbow ||
        _trail == TrailEffect.rainbow ||
        _ghostSkin == GhostSkin.rainbow;
    if (needsRainbow && !_rainbow.isAnimating) {
      _rainbow.repeat();
    } else if (!needsRainbow && _rainbow.isAnimating) {
      _rainbow.stop();
      _rainbow.value = 0;
    }

    await _loadGhost();
    if (!mounted) return;

    _reset();
  }

  Future<void> _loadGhost() async {
    if (_isLevelMode || !SettingsService.current.showGhost) {
      _ghostRecording = null;
      return;
    }
    _ghostRecording = await GhostService.load(
      difficulty: d,
      timeAttack: _isTimeAttack,
    );
  }

  void _reset() {
    PlayerProgressionService.blockDialogsFor(this); // ← Stage 4 (idempotent)
    _gameSessionId = DateTime.now().microsecondsSinceEpoch.toString();
    _gameXpCommitted = false;
    _levelXpCommitted = false;
    _timer?.cancel();
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _countdownTimer?.cancel();
    _endCountdownTimer?.cancel();
    _startCountdownTimer?.cancel();
    _shieldRecoveryTimer?.cancel();
    _recoverySlowTimer?.cancel();

    final start = widget.level?.snakeStart ?? const math.Point(9, 10);
    final sdir = widget.level?.snakeDir ?? const math.Point(0, -1);
    _snake = [
      start,
      math.Point(start.x - sdir.x, start.y - sdir.y),
      math.Point(start.x - sdir.x * 2, start.y - sdir.y * 2),
    ];
    _prevSnake = List.from(_snake);
    _dir = sdir;
    _queued = sdir;
    _score = 0;
    _over = false;
    _paused = false;
    _won = false;
    _newRecord = false;
    _foodsEaten = 0;
    _newAchievements = [];
    _endCountdown = 0;
    _continueCount = 0;
    _isShowingContinueDialog = false;
    _isShowingEmergencyDialog = false;
    _emergencyUsedThisSession = false;
    _ghostActive = false;
    _isEmergencyRecovery = false;
    _ghostTimer?.cancel();
    _isRecovering = false;
    _showShieldFlash = false;
    _safeStepsAfterShieldRecovery = 0;
    _recoverySlowUntil = null;
    _currentBurst = null;
    _wrapEvent = null;
    _shieldCount = _isLevelMode ? _pityShields : 0;
    _slowUntil = null;
    _slowRemaining = 0;
    _wasComboActive = false;
    _currentPowerUp = null;
    _foodsThisGame = 0;
    _goldenApplesEaten = 0;
    _combosThisGame = 0;
    _everHadShield = false;
    _everHadSlow = false;
    _tick = _baseTick();
    // ⏱️ برای هر دو حالت (Time Attack + فصل ۴)
    _secondsLeft = _activeTimeLimit?.inSeconds ?? 0;
    _syncMoveDuration();
    _moveAnim.value = 1.0;
    _shake.value = 1.0;
    _wrapAnim.value = 1.0;
    _comboFlash.value = 1.0;
    _food = const math.Point(0, 0);

    _currentRecording = [];
    _playerStateIndex = 0;
    _recordCurrentState();

    _spawnFood();
    _focus.requestFocus();
    _audio.startMusic();
    _isIntroPlaying = false;
    _introAnim.reset();
    if (!_pulse.isAnimating) _pulse.repeat(); // ← اضافه
    setState(() {});

    if (_introAnimation != IntroAnimation.none) {
      _startIntro();
    } else {
      _startStartCountdown();
    }
  }

  void _startIntro() {
    setState(() => _isIntroPlaying = true);
    _introAnim.duration = const Duration(milliseconds: 900);
    _introAnim.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _isIntroPlaying = false);
      _startStartCountdown();
    });
  }

  void _recordCurrentState() {
    if (_isLevelMode) return;
    final head = _snake.first;
    _currentRecording.add(GhostRecording.encode(
      x: head.x,
      y: head.y,
      length: _snake.length,
    ));
  }

  List<({int x, int y})> _ghostBody() {
    final g = _ghostRecording;
    if (g == null) return const [];
    return g.bodyAt(_playerStateIndex);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _over || _won || _paused) return;
      if (_secondsLeft <= 0) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _onTimeOut();
    });
  }

  /// 🎬 شمارش معکوس قبل از شروع بازی
  void _startStartCountdown() {
    _startCountdownTimer?.cancel();
    setState(() => _countdown = 3);

    _startCountdownTimer =
        Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          _beginPlay();
        }
      });
      if (_countdown > 0) {
        AppHaptics.selection();
      }
      if (SettingsService.current.sfx && _countdown > 0) {
        _audio.playSfx(Sfx.button);
      }
    });
  }

  /// شروع واقعی حرکت مار بعد از شمارش
  void _beginPlay() {
    if (_isAnyTimed) _startCountdown();
    _restartTimer();
  }

  void _onTimeOut() {
    _countdownTimer?.cancel();
    _gameOver();
  }

  int _wrap(int v, int max) => ((v % max) + max) % max;

  Duration _effectiveTick() {
    // هر دو slow (powerup + recovery) ×۲ می‌کنن، ولی جمع نمی‌شن (نه ×۴)
    if (_isSlowActive || _isRecoverySlowActive) return _tick * 2;
    return _tick;
  }

  void _syncMoveDuration() {
    _moveAnim.duration = _effectiveTick();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_effectiveTick(), (_) => _step());
  }

  void _spawnFood() {
    final occupied = _snake.toSet();
    final walls = _walls;
    final portalCells = <math.Point<int>>{};
    for (final p in _portals) {
      portalCells.add(p.a);
      portalCells.add(p.b);
    }
    final free = <math.Point<int>>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final pt = math.Point(x, y);
        if (!occupied.contains(pt) &&
            !walls.contains(pt) &&
            !portalCells.contains(pt)) {
          free.add(pt);
        }
      }
    }
    if (free.isEmpty) {
      _gameOver();
      return;
    }
    _food = free[_rng.nextInt(free.length)];

    final r = _rng.nextDouble();
    if (r < 0.70) {
      _currentPowerUp = null;
    } else if (r < 0.85) {
      _currentPowerUp = PowerUp.golden;
    } else if (r < 0.95) {
      _currentPowerUp = PowerUp.shield;
    } else {
      _currentPowerUp = PowerUp.slow;
    }
  }

  void _step() {
    if (_over ||
        _won ||
        _paused ||
        _isStarting ||
        _isEnding ||
        _isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    _dir = _queued;
    final head = _snake.first;
    var next = math.Point(head.x + _dir.x, head.y + _dir.y);

    final useWrap = _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;

    if (!useWrap &&
        (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows)) {
      _handleCollision(head);
      return;
    }

    if (useWrap) {
      final rawNext = next;
      next = math.Point(_wrap(rawNext.x, cols), _wrap(rawNext.y, rows));
      if (rawNext != next && SettingsService.current.wrapEffect) {
        _wrapEvent = WrapEvent(from: head, to: next, dir: _dir);
        _wrapAnim.forward(from: 0);
      }
    }
    if (_walls.contains(next)) {
      _handleCollision(head);
      return;
    }

    // 🌀 Portal teleport
    var portalTeleported = false;
    final portalDest = _getPortalDestination(next);
    if (portalDest != null) {
      _triggerPortalBurst(next, portalDest);
      StorageService.incrementPortalsPassed();
      next = portalDest;
      portalTeleported = true;
      if (_walls.contains(next)) {
        if (!_ghostActive) {
          _handleCollision(head);
          return;
        }
        // ghost active — اجازه عبور از دیوار
      }
    }
    final ate = next == _food;
    final body = ate ? _snake : _snake.sublist(0, _snake.length - 1);

    if (body.contains(next)) {
      _handleCollision(head);
      return;
    }

    _prevSnake = List<math.Point<int>>.from(_snake);
    setState(() {
      _snake = [next, ..._snake];
      if (ate) {
        _handleEat(next);
      } else {
        _snake.removeLast();
      }
    });

    // حرکت موفق یعنی مار در حال خارج شدن از موقعیت خطرناک است.
    // پس از ۸ حرکت امن، برخورد بعدی یک خطر جدید محسوب می‌شود.
    if (_safeStepsAfterShieldRecovery > 0) {
      _safeStepsAfterShieldRecovery++;
      if (_safeStepsAfterShieldRecovery >= _dangerEpisodeSafeSteps) {
        _safeStepsAfterShieldRecovery = 0;
      }
    }

    if (portalTeleported) {
      final len = math.min(_prevSnake.length, _snake.length);
      for (var i = 0; i < len; i++) {
        final f = _prevSnake[i];
        final t = _snake[i];
        final dx = (t.x - f.x).abs();
        final dy = (t.y - f.y).abs();
        if (dx >= 5 || dy >= 5) {
          _prevSnake[i] = t;
        }
      }
    }

    _playerStateIndex++;
    _recordCurrentState();

    if (SettingsService.current.smoothMovement) {
      _moveAnim.forward(from: 0);
    } else {
      _moveAnim.value = 1.0;
    }

    if (_isLevelMode &&
        !_winInProgress &&
        _foodsEaten >= widget.level!.targetFoods) {
      _winLevel();
    }
  }

  void _handleEat(math.Point<int> foodPos) {
    _foodsThisGame++;
    final eaten = _currentPowerUp;
    var gained = 10 * (_isLevelMode ? 1 : d.multiplier);
    switch (eaten?.type) {
      case PowerUpType.golden:
        gained *= 2;
        _goldenApplesEaten++;
        break;
      case PowerUpType.shield:
        _shieldCount = (_shieldCount + 1).clamp(0, _maxShields);
        _everHadShield = true;
        break;
      case PowerUpType.slow:
        _activateSlow();
        _everHadSlow = true;
        break;
      case null:
        break;
    }

    if (_isComboActive) {
      gained = (gained * _comboMultiplier).round();
    }

    _score += gained;
    _triggerBurst(foodPos, gained, eaten?.type);

    if (_isLevelMode) {
      _foodsEaten++;
    } else {
      if (_score > _best) {
        _best = _score;
        _newRecord = true;
        if (_isTimeAttack) {
          StorageService.setTimeAttackBest(_best);
        } else {
          StorageService.setBestScore(d, _best);
        }
      }
    }

    _spawnFood();
    _updateSpeed();
    _audio.playSfx(Sfx.eat);
    AppHaptics.light();

    _checkComboActivation();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.current;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _header(),
                PowerUpHud(
                  palette: p,
                  shieldCount: _shieldCount,
                  slowActive: _isSlowActive,
                  slowRemaining: _slowRemaining,
                  comboActive: _isComboActive,
                  comboMultiplier: _comboMultiplier,
                  showGhost: !_isLevelMode &&
                      _ghostRecording != null &&
                      SettingsService.current.showGhost,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: GameShakeWrapper(
                      controller: _shake,
                      intensity: () => _shakeIntensity,
                      child: _board(settings),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (settings.controlType == ControlType.joystick)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: VirtualJoystick(
                      size: settings.dpadSize.pixels,
                      background: p.surface,
                      foreground: p.accent,
                      enabled: !_over &&
                          !_won &&
                          !_paused &&
                          !_isStarting &&
                          !_isEnding,
                      enableHaptics: settings.haptics,
                      onDirection: _turn,
                    ),
                  )
                else
                  DPad(
                    palette: p,
                    onDirection: _turn,
                    size: settings.dpadSize.pixels,
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
