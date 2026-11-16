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

/// 🐢 ضریب سرعت مخصوص مراحل — 1.0 = عادی، 2.0 = دو برابر کندتر
const double kLevelSpeedMultiplier = 1;

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
  static const int cols = 20;
  static const int rows = 20;

  SnakeSkin _snakeSkin = SnakeSkin.basic;
  GhostSkin _ghostSkin = GhostSkin.basic;
  IntroAnimation _introAnimation = IntroAnimation.none;
  FoodSkin _foodSkin = FoodSkin.basic;
  TrailEffect _trail = TrailEffect.none;
  BoardPattern _pattern = BoardPattern.none;
  PatternIntensity _patternIntensity = PatternIntensity.subtle;

  static const int _maxShields = 3;
  static const Duration _slowDuration = Duration(seconds: 5);
  static const Duration _maxSlowDuration = Duration(seconds: 15);
  static const double _comboMultiplierValue = 1.5;

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
  static const int _shieldSimMaxDepth = 25;
  static const Duration _shieldFreezeDuration = Duration(milliseconds: 250);

  bool _isRecovering = false;
  bool _showShieldFlash = false;
  Timer? _shieldRecoveryTimer;

  // تعداد حرکت‌های موفق پس از آخرین نجات با سپر؛
  // اگر قبل از ۸ حرکت دوباره برخورد کنیم، هنوز همان موقعیت خطرناک محسوب می‌شود.
  static const int _dangerEpisodeSafeSteps = 8;
  int _safeStepsAfterShieldRecovery = 0;
  // 🚨 Emergency Rescue
  static const int _emergencyRescuePrice = 300;
  static const Duration _ghostDuration = Duration(seconds: 3);
  static const Duration _ghostExtension = Duration(seconds: 1);
  bool _isShowingEmergencyDialog = false;
  bool _emergencyUsedThisSession = false;
  bool _ghostActive = false;
  bool _isEmergencyRecovery = false; // ← جدید
  Timer? _ghostTimer;
  // 🐢 Recovery Slow
  static const Duration _recoverySlowDuration = Duration(seconds: 3);
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
  static const List<int> _continuePrices = [50, 100, 200];

  GamePalette get p => widget.palette;
  Difficulty get d => widget.difficulty;
  bool get _isLevelMode => widget.level != null;
  bool get _isTimeAttack => widget.timeLimit != null;

  // ⏱️ فصل ۴ — مرحله‌ی زمان‌دار
  bool get _isTimedLevel => widget.level?.isTimed ?? false;
  bool get _isAnyTimed => _isTimeAttack || _isTimedLevel;

  Duration? get _activeTimeLimit =>
      _isTimeAttack ? widget.timeLimit : widget.level?.timeLimit;

  Set<math.Point<int>> get _walls => widget.level?.walls ?? const {};
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
    return 1.40; // 🔴 فصل ۴
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
      if (SettingsService.current.haptics && _countdown > 0) {
        HapticFeedback.selectionClick().catchError((_) {});
      }
      if (SettingsService.current.sfx && _countdown > 0) {
        _audio.playSfx(Sfx.button);
      }
    });
  }

  void _triggerPortalBurst(math.Point<int> from, math.Point<int> to) {
    _audio.playSfx(Sfx.newRecord);
    if (PerformanceService.particleCount == 0) return;
    if (SettingsService.current.haptics) {
      HapticFeedback.selectionClick().catchError((_) {});
    }
    if (!SettingsService.current.particles) return;

    Color portalColor = const Color(0xFF00E5FF);
    for (final pair in _portals) {
      if (pair.contains(from) || pair.contains(to)) {
        portalColor = pair.color;
        break;
      }
    }

    _currentBurst = ParticleBurst.generate(
      origin: Offset(
        (to.x + 0.5) / cols,
        (to.y + 0.5) / rows,
      ),
      scoreDelta: 0,
      primary: portalColor,
      textColor: portalColor,
      rng: _rng,
    );
    _particles.forward(from: 0);
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

  void _triggerShake({double intensity = 1.0}) {
    if (!SettingsService.current.screenShake) return;
    _shakeIntensity = intensity;
    _shake.forward(from: 0);
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
    if (SettingsService.current.haptics) {
      HapticFeedback.lightImpact().catchError((_) {});
    }

    _checkComboActivation();
  }

  void _checkComboActivation() {
    final isCombo = _isComboActive;
    if (isCombo && !_wasComboActive) {
      _combosThisGame++;
      _comboFlash.forward(from: 0);
      _audio.playSfx(Sfx.newRecord);
      if (SettingsService.current.haptics) {
        HapticFeedback.mediumImpact().catchError((_) {});
      }
    }
    _wasComboActive = isCombo;
  }

  Future<void> _winLevel() async {
    if (_winInProgress || _won) return;
    _winInProgress = true;

    _pulse.stop();
    _timer?.cancel();
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _countdownTimer?.cancel();
    _audio.playSfx(Sfx.newRecord);
    if (SettingsService.current.haptics) {
      HapticFeedback.heavyImpact().catchError((_) {});
    }
    await StorageService.resetPity(widget.level!.id);
    if (!_everHadShield && !_everHadSlow) {
      await StorageService.incrementPerfectLevels();
    }
    await LevelsService.markCompleted(widget.level!.id);
    await LevelsService.unlockNext(widget.level!.id);

    // 🎯 Stage 2: XP برد مرحله + بونوس فصل
    if (!_levelXpCommitted) {
      var bothDone = true;

      // ۱. XP برد مرحله
      try {
        final result = await PlayerProgressionService.addXP(
          eventId: 'level_win:${widget.level!.id}:first',
          amount: _levelWinXp(widget.level!.id),
          source: 'level',
        );
        if (!result.wasDuplicate && result.xpGained == 0) bothDone = false;
      } catch (e) {
        bothDone = false;
        debugPrint('[LEVEL XP] error: $e');
      }

      // ۲. بونوس فصل (مستقل)
      if (_isLastLevelOfChapter(widget.level!.id)) {
        try {
          final bonus = _chapterBonusFor(widget.level!.id);
          if (bonus > 0) {
            final result = await PlayerProgressionService.addXP(
              eventId: 'chapter:${_chapterIdOf(widget.level!.id)}:bonus',
              amount: bonus,
              source: 'chapter',
            );
            if (!result.wasDuplicate && result.xpGained == 0) bothDone = false;
          }
        } catch (e) {
          bothDone = false;
          debugPrint('[CHAPTER XP] error: $e');
        }
      }

      if (bothDone) _levelXpCommitted = true;
    }

    await AchievementsService.checkUnlocks();
    await DailyChallengesService.recordLevelCompleted();
    await _recordHistory(won: true);
    if (!mounted) return;
    setState(() => _won = true);
  }

  void _activateSlow() {
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    final now = DateTime.now();

    if (_slowUntil != null && now.isBefore(_slowUntil!)) {
      final remaining = _slowUntil!.difference(now);
      final newDuration = remaining + _slowDuration;
      _slowUntil = now.add(
        newDuration > _maxSlowDuration ? _maxSlowDuration : newDuration,
      );
    } else {
      _slowUntil = now.add(_slowDuration);
    }

    _slowRemaining = _secondsUntil(_slowUntil!, now);
    _syncMoveDuration();
    _restartTimer();

    final waitMs = _slowUntil!.difference(now).inMilliseconds;
    _slowTimer = Timer(Duration(milliseconds: waitMs), () {
      if (!mounted) return;
      _slowTickTimer?.cancel();
      setState(() {
        _slowUntil = null;
        _slowRemaining = 0;
        _syncMoveDuration();
        _restartTimer();
      });
      _wasComboActive = _isComboActive;
    });

    _slowTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _slowUntil == null) return;
      final left = _secondsUntil(_slowUntil!, DateTime.now());
      if (left <= 0) {
        _slowTickTimer?.cancel();
        return;
      }
      setState(() => _slowRemaining = left);
    });

    setState(() {});
  }

  int _secondsUntil(DateTime end, DateTime now) {
    final ms = end.difference(now).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  // ═══════════════════════════════════════════════════════════
  // 🛡️ Smart Shield Recovery
  // ═══════════════════════════════════════════════════════════
  void _handleCollision(math.Point<int> head) {
    if (_isShowingEmergencyDialog) return;
    if (_isShowingContinueDialog) return;

    final safeDir = _findSafeRoute(head);

    if (safeDir != null && _shieldCount > 0) {
      _startRecovery(head, safeDir);
      return;
    }

    if (safeDir == null && !_emergencyUsedThisSession) {
      _showEmergencyRescueDialog();
      return;
    }

    // اگر نجات‌بخش قبلاً مصرف شده و هیچ مسیر فراری وجود ندارد،
    // بازی مستقیم تمام شود؛ Continue فقط برای برخوردهای دارای مسیر امن باقی می‌ماند.
    if (safeDir == null && _emergencyUsedThisSession) {
      _pulse.stop();
      _timer?.cancel();
      _slowTimer?.cancel();
      _slowTickTimer?.cancel();
      _countdownTimer?.cancel();
      _triggerShake(intensity: 1.0);
      _audio.playSfx(Sfx.gameOver);
      if (SettingsService.current.haptics) {
        HapticFeedback.heavyImpact().catchError((_) {});
      }
      _finalizeGameOver();
      return;
    }

    // مسیر امن وجود دارد اما سپر نداریم؛ Continue عادی حفظ می‌شود.
    _gameOver();
  }

  Future<void> _showEmergencyRescueDialog() async {
    if (_isShowingEmergencyDialog) return;

    setState(() => _isShowingEmergencyDialog = true);
    _timer?.cancel();
    _countdownTimer?.cancel();

    final coins = await ShopService.getCoins();
    if (!mounted) return;

    setState(() => _currentCoins = coins);

    if (coins < _emergencyRescuePrice) {
      setState(() => _isShowingEmergencyDialog = false);
      _gameOver();
      return;
    }
    // نمایش Bottom Sheet از طریق EmergencyOverlay در Stack اصلی بازی انجام می‌شود.
  }

  void _handleEmergencyAccept() {
    if (!mounted) return;
    setState(() => _isShowingEmergencyDialog = false);
    _executeEmergencyRescue();
  }

  void _handleEmergencyDecline() {
    if (!mounted) return;
    if (SettingsService.current.haptics) {
      HapticFeedback.selectionClick().catchError((_) {});
    }
    _audio.playSfx(Sfx.button);
    setState(() => _isShowingEmergencyDialog = false);
    _gameOver();
  }

  Future<void> _executeEmergencyRescue() async {
    final spent = await ShopService.spendCoins(_emergencyRescuePrice);
    if (!mounted) return;

    if (!spent) {
      _gameOver();
      return;
    }

    final newSnake = _tryRespawnSnake(_snake.length);
    if (newSnake == null) {
      // refund — نمی‌تونه جای امن پیدا کنه
      await ShopService.addCoins(_emergencyRescuePrice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.isFa
                ? 'مار بلندتر از فضای خالیه — سکه برگشت'
                : 'Snake too long for available space — coins refunded',
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
      _gameOver();
      return;
    }

    _emergencyUsedThisSession = true;
    _safeStepsAfterShieldRecovery = 0;

    // ⚙️ پاکسازی slow قبلی
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _slowUntil = null;
    _slowRemaining = 0;
    _wasComboActive = false;

    // جهت از snake[0] → snake[1]
    final dir = math.Point(
      newSnake[0].x - newSnake[1].x,
      newSnake[0].y - newSnake[1].y,
    );

    setState(() {
      _snake = newSnake;
      _prevSnake = List.from(newSnake);
      _dir = dir;
      _queued = dir;
      _shieldCount = 0;
      _ghostActive = true;
      _isEmergencyRecovery = true; // ← برای flash طلایی
      _showShieldFlash = true; // ← نمایش flash
    });

    // Feedback
    _audio.playSfx(Sfx.newRecord);
    _triggerShake(intensity: 1.0);
    if (SettingsService.current.haptics) {
      HapticFeedback.heavyImpact().catchError((_) {});
    }

    if (SettingsService.current.particles &&
        PerformanceService.particleCount > 0) {
      _currentBurst = ParticleBurst.generate(
        origin: Offset(
          (newSnake.first.x + 0.5) / cols,
          (newSnake.first.y + 0.5) / rows,
        ),
        scoreDelta: 0,
        primary: const Color(0xFF00F0FF),
        textColor: const Color(0xFF00F0FF),
        rng: _rng,
      );
      _particles.forward(from: 0);
    }

    // 👻 Ghost timer (۳s)
    _ghostTimer?.cancel();
    _ghostTimer = Timer(_ghostDuration, _maybeEndGhost);
    _shieldRecoveryTimer?.cancel();
    _shieldRecoveryTimer = Timer(_shieldFreezeDuration, () {
      if (!mounted) return;
      setState(() {
        _showShieldFlash = false;
      });
    });

    // 🐢 Slowdown ۳ ثانیه (مثل shield)
    _recoverySlowTimer?.cancel();
    _recoverySlowUntil = DateTime.now().add(_recoverySlowDuration);
    _recoverySlowTimer = Timer(_recoverySlowDuration, () {
      if (!mounted) return;
      setState(() => _recoverySlowUntil = null);
      _syncMoveDuration();
      if (!_over &&
          !_won &&
          !_paused &&
          !_isShowingContinueDialog &&
          !_isRecovering &&
          !_isShowingEmergencyDialog) {
        _restartTimer();
      }
    });

    _syncMoveDuration();
    _restartTimer();
    if (!_pulse.isAnimating) _pulse.repeat();
    if (_canRunClock) {
      _startCountdown();
    }
  }

  void _startRecovery(math.Point<int> head, math.Point<int> safeDir) {
    _isRecovering = true;
    _timer?.cancel();

    StorageService.incrementShieldSavedCount();
    _everHadShield = true;
    _wasComboActive = _isComboActive;

    _audio.playSfx(Sfx.newRecord);
    _triggerShake(intensity: 0.55);
    if (SettingsService.current.haptics) {
      HapticFeedback.mediumImpact().catchError((_) {});
    }

    if (SettingsService.current.particles &&
        PerformanceService.particleCount > 0) {
      _currentBurst = ParticleBurst.generate(
        origin: Offset(
          (head.x + 0.5) / cols,
          (head.y + 0.5) / rows,
        ),
        scoreDelta: 0,
        primary: const Color(0xFF00F0FF),
        textColor: const Color(0xFF00F0FF),
        rng: _rng,
      );
      _particles.forward(from: 0);
    }

    setState(() {
      _shieldCount--;
      _dir = safeDir;
      _queued = safeDir;
      _showShieldFlash = true;
    });
    _safeStepsAfterShieldRecovery = 1;

    _shieldRecoveryTimer?.cancel();
    _shieldRecoveryTimer = Timer(_shieldFreezeDuration, () {
      if (!mounted) return;

      // 🐢 Start 3s recovery slow
      _recoverySlowTimer?.cancel();
      _recoverySlowUntil = DateTime.now().add(_recoverySlowDuration);
      _recoverySlowTimer = Timer(_recoverySlowDuration, () {
        if (!mounted) return;
        setState(() => _recoverySlowUntil = null);
        _syncMoveDuration();
        if (!_over &&
            !_won &&
            !_paused &&
            !_isShowingContinueDialog &&
            !_isRecovering) {
          _restartTimer();
        }
      });

      setState(() {
        _isRecovering = false;
        _showShieldFlash = false;
      });

      _syncMoveDuration();
      if (!_over && !_won && !_paused && !_isShowingContinueDialog) {
        _restartTimer();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // 🛡️ Smart Route Evaluation (Time-Aware BFS)
  // ═══════════════════════════════════════════════════════════
  math.Point<int>? _findSafeRoute(math.Point<int> head) {
    final candidates = <math.Point<int>>[
      math.Point(-_dir.y, _dir.x), // ۹۰° چپ
      math.Point(_dir.y, -_dir.x), // ۹۰° راست
    ];

    math.Point<int>? best;
    int bestSpace = -1;

    for (final c in candidates) {
      final space = _evaluateRoute(head, c);
      if (space > bestSpace) {
        bestSpace = space;
        best = c;
      }
    }

    // 🔓 آستانه‌ی آسون‌تر — بین ۴ تا ۱۲ (قبلاً ۶ تا ۲۰)
    final minRequired = math.max(4, math.min(12, _snake.length + 2));

    return bestSpace >= minRequired ? best : null;
  }

  /// ارزیابی یه جهت — خروجی: تعداد cellهای قابل دسترس
  /// -1 = جهت غیرمعتبر (بلافاصله بلاک)
  int _evaluateRoute(math.Point<int> head, math.Point<int> direction) {
    final useWrap = _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;

    // چک سریع: ۱ قدم اول امن؟
    final lineScore = _simulateSafeSteps(head, direction, 3);
    if (lineScore < 3) return -1;

    // موقعیت ۱ قدم بعد
    var firstNext = math.Point(head.x + direction.x, head.y + direction.y);
    if (useWrap) {
      firstNext =
          math.Point(_wrap(firstNext.x, cols), _wrap(firstNext.y, rows));
    } else if (firstNext.x < 0 ||
        firstNext.x >= cols ||
        firstNext.y < 0 ||
        firstNext.y >= rows) {
      return -1;
    }
    if (_walls.contains(firstNext)) return -1;

    // Portal
    final portalDest = _getPortalDestination(firstNext);
    if (portalDest != null) {
      firstNext = portalDest;
      if (_walls.contains(firstNext)) return -1;
    }

    // 🍎 Body بعد از حرکت — با در نظر گرفتن غذا
    final wouldEat = (firstNext == _food);
    final bodyAfter = <math.Point<int>>[firstNext, ..._snake];
    if (!wouldEat) {
      bodyAfter.removeLast(); // ← فقط اگه غذا نمی‌خوره
    }

    // Time-aware BFS
    final space = _timeAwareBfs(
      start: firstNext,
      startStep: 1,
      snakeAtStart: bodyAfter,
      maxSteps: math.min(_shieldSimMaxDepth, _snake.length + 10),
      limit: 250,
    );

    return space;
  }

  /// BFS که آگاهه از اینکه tail با هر حرکت جابه‌جا می‌شه.
  /// خروجی: تعداد cellهای قابل دسترس
  int _timeAwareBfs({
    required math.Point<int> start,
    required int startStep,
    required List<math.Point<int>> snakeAtStart,
    required int maxSteps,
    required int limit,
  }) {
    final visited = <math.Point<int>>{start};
    final queue = <math.Point<int>>[start];
    final movesAt = <math.Point<int>, int>{start: 0};
    var qi = 0; // ✅ index pointer به‌جای removeAt(0)

    final useWrap = _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;
    final L = snakeAtStart.length;

    while (qi < queue.length && visited.length < limit) {
      final curr = queue[qi++];
      final moves = movesAt[curr]!;

      // ✅ سقف عمق
      if (startStep + moves >= maxSteps) continue;

      for (final d in const [
        math.Point(0, -1),
        math.Point(0, 1),
        math.Point(-1, 0),
        math.Point(1, 0),
      ]) {
        var next = math.Point(curr.x + d.x, curr.y + d.y);

        // ─── مرز ───
        if (useWrap) {
          next = math.Point(_wrap(next.x, cols), _wrap(next.y, rows));
        } else if (next.x < 0 ||
            next.x >= cols ||
            next.y < 0 ||
            next.y >= rows) {
          continue;
        }

        // ─── دیوار ───
        if (_walls.contains(next)) continue;

        // ─── قبلاً دیده شده ───
        if (visited.contains(next)) continue;

        // ─── Body (time-aware) ───
        final nextMoves = moves + 1;
        bool blocked = false;
        for (var i = 0; i < L; i++) {
          if (snakeAtStart[i] == next) {
            // segment i بعد از (L - i) حرکت خالی می‌شه
            // پس اگه nextMoves <= (L - i) هنوز اشغاله
            if (nextMoves < L - i || (nextMoves == 0 && L - i == 0)) {
              blocked = true;
              break;
            }
            // اگه nextMoves >= L - i → آزاد
          }
        }
        if (blocked) continue;

        visited.add(next);
        movesAt[next] = nextMoves;
        queue.add(next);

        if (visited.length >= limit) break;
      }
    }

    return visited.length;
  }

  int _simulateSafeSteps(
      math.Point<int> head, math.Point<int> direction, int maxDepth) {
    var simBody = List<math.Point<int>>.from(_snake);
    var pos = head;
    var steps = 0;
    final useWrap = _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;

    for (var i = 0; i < maxDepth; i++) {
      var next = math.Point(pos.x + direction.x, pos.y + direction.y);

      if (useWrap) {
        next = math.Point(_wrap(next.x, cols), _wrap(next.y, rows));
      } else {
        if (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows) {
          return steps;
        }
      }

      if (_walls.contains(next)) return steps;

      final portalDest = _getPortalDestination(next);
      if (portalDest != null) {
        next = portalDest;
        if (_walls.contains(next)) return steps;
        if (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows) {
          return steps;
        }
      }

      final wouldEat = (next == _food);
      final bodyToCheck =
          wouldEat ? simBody : simBody.sublist(0, simBody.length - 1);
      if (bodyToCheck.contains(next)) return steps;

      simBody = [next, ...simBody];
      if (!wouldEat) simBody.removeLast();

      pos = next;
      steps++;
    }

    return steps;
  }

  void _triggerBurst(math.Point<int> foodCell, int scoreDelta,
      [PowerUpType? powerUp]) {
    if (!SettingsService.current.particles) return;
    if (PerformanceService.particleCount == 0) return;

    final origin = Offset(
      (foodCell.x + 0.5) / cols,
      (foodCell.y + 0.5) / rows,
    );

    Color primary;
    switch (powerUp) {
      case PowerUpType.golden:
        primary = const Color(0xFFFFD700);
        break;
      case PowerUpType.shield:
        primary = const Color(0xFF00F0FF);
        break;
      case PowerUpType.slow:
        primary = const Color(0xFF8A7BFF);
        break;
      case null:
        primary = p.food;
    }

    _currentBurst = ParticleBurst.generate(
      origin: origin,
      scoreDelta: scoreDelta,
      primary: primary,
      textColor: p.accent,
      rng: _rng,
    );

    _particles.forward(from: 0);
  }

  void _updateSpeed() {
    if (_isLevelMode) return;
    final base = d.tick.inMilliseconds;
    final speedup = (_score ~/ 50) * 5;
    final ms = math.max(60, base - speedup);
    final newTick = Duration(milliseconds: ms);
    if (newTick != _tick) {
      _tick = newTick;
      _syncMoveDuration();
      _restartTimer();
    }
  }

  Future<void> _recordHistory({required bool won}) async {
    try {
      final mode = _isLevelMode
          ? GameMode.level
          : _isTimeAttack
              ? GameMode.timeAttack
              : GameMode.free;
      await HistoryService.add(
        GameHistoryEntry(
          timestamp: DateTime.now(),
          score: _score,
          difficulty: d,
          mode: mode,
          snakeLength: _snake.length,
          foodsEaten: _foodsThisGame,
          wasNewRecord: _newRecord,
          levelId: widget.level?.id,
          won: won,
        ),
      );
    } catch (_) {}
  }

  // 🎯 Stage 2: XP helpers

  int _calculateGameXp() {
    if (_isLevelMode) return 0;
    if (_score < 10) return 0;
    if (_isTimeAttack && _foodsThisGame < 3) return 0;

    int base;
    if (_isTimeAttack) {
      base = 30;
    } else {
      switch (d) {
        case Difficulty.easy:
          base = 20;
          break;
        case Difficulty.normal:
          base = 25;
          break;
        case Difficulty.hard:
          base = 35;
          break;
      }
    }

    return base +
        _foodsThisGame * 1 +
        _goldenApplesEaten * 5 +
        _combosThisGame * 8 +
        (_newRecord ? 30 : 0);
  }

  int _levelWinXp(int levelId) {
    if (levelId <= 10) return 25;
    if (levelId <= 20) return 40;
    if (levelId <= 30) return 55;
    return 75;
  }

  int _chapterIdOf(int levelId) {
    for (final c in LevelsService.chapters) {
      if (levelId >= c.startLevelId && levelId <= c.endLevelId) {
        return c.id;
      }
    }
    return 1;
  }

  bool _isLastLevelOfChapter(int levelId) {
    for (final c in LevelsService.chapters) {
      if (levelId == c.endLevelId) return true;
    }
    return false;
  }

  int _chapterBonusFor(int levelId) {
    final chapterId = _chapterIdOf(levelId);
    switch (chapterId) {
      case 1:
        return 150;
      case 2:
        return 200;
      case 3:
        return 250;
      case 4:
        return 300;
      default:
        return 0;
    }
  }

  Future<void> _gameOver() async {
    if (_over || _won || _isEnding || _isShowingContinueDialog) return;
    _pulse.stop();

    _timer?.cancel();
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _countdownTimer?.cancel();

    if (_timedOut) {
      // ⏱️ Timeout → مستقیم (بدون shake)
      if (_canContinue) {
        await _showContinueDialog();
        return;
      }
      await _finalizeGameOver();
      return;
    }

    // 💥 برخورد → shake + صدا
    _triggerShake(intensity: 1.0);
    _audio.playSfx(Sfx.gameOver);
    if (SettingsService.current.haptics) {
      HapticFeedback.heavyImpact().catchError((_) {});
    }

    // ⏳ صبر کن تا shake تموم شه (۳۸۰ms) + یه ذره مکث
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    if (_canContinue) {
      await _showContinueDialog();
      return;
    }

    _startEndCountdown();
  }

  void _startEndCountdown() {
    _endCountdownTimer?.cancel();
    setState(() => _endCountdown = 3);

    _endCountdownTimer =
        Timer.periodic(const Duration(milliseconds: 450), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_endCountdown > 1) {
        setState(() => _endCountdown--);
        if (SettingsService.current.haptics) {
          HapticFeedback.selectionClick().catchError((_) {});
        }
        if (SettingsService.current.sfx) {
          _audio.playSfx(Sfx.button);
        }
      } else {
        t.cancel();
        await _finalizeGameOver();
      }
    });
  }

  Future<void> _showContinueDialog() async {
    if (SettingsService.current.haptics) {
      HapticFeedback.mediumImpact().catchError((_) {});
    }

    final coins = await ShopService.getCoins();
    if (!mounted) return;
    setState(() {
      _currentCoins = coins;
      _isShowingContinueDialog = true;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // 🌀 Coil Placement for Emergency Rescue Respawn
  // ═══════════════════════════════════════════════════════════

  List<math.Point<int>>? _tryRespawnSnake(int length) {
    final useWrap = _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;

    final preferredStart = widget.level?.snakeStart ?? const math.Point(9, 10);

    // همه‌ی cellها، مرتب‌شده بر اساس فاصله از preferredStart
    final allCells = <math.Point<int>>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        allCells.add(math.Point(x, y));
      }
    }
    allCells.sort((a, b) {
      final da =
          (a.x - preferredStart.x).abs() + (a.y - preferredStart.y).abs();
      final db =
          (b.x - preferredStart.x).abs() + (b.y - preferredStart.y).abs();
      return da.compareTo(db);
    });

    for (final center in allCells) {
      final snake = _tryCoilPlacementAt(center, length, useWrap);
      if (snake != null) return snake;
    }

    return null;
  }

  /// تلاش برای قرار دادن مار به شکل مارپیچ حول `center`
  /// - head در outer part قرار می‌گیره (نه center)
  /// - direction = outward (خارج از coil)
  /// - body به سمت center می‌پیچه
  List<math.Point<int>>? _tryCoilPlacementAt(
    math.Point<int> center,
    int length,
    bool useWrap,
  ) {
    // ۱. center باید آزاد باشه
    if (center.x < 0 || center.x >= cols || center.y < 0 || center.y >= rows) {
      return null;
    }
    if (_walls.contains(center)) return null;
    if (_portals.any((p) => p.a == center || p.b == center)) return null;

    // ۲. تولید مارپیچ از center به بیرون
    final spiral = _generateSpiralCells(center, length, useWrap);
    if (spiral.length < length) return null;

    // ۳. برعکس کردن: head = outermost, tail = innermost
    final snake = <math.Point<int>>[];
    for (var i = spiral.length - 1; i >= 0; i--) {
      snake.add(spiral[i]);
    }

    // ۴. direction = snake[0] - snake[1] (باید cardinal باشه)
    if (snake.length < 2) return null;
    final dir = math.Point(snake[0].x - snake[1].x, snake[0].y - snake[1].y);
    if (dir.x.abs() + dir.y.abs() != 1) return null;

    // ۵. head + dir باید آزاد باشه (برای اولین حرکت)
    var next = math.Point(snake[0].x + dir.x, snake[0].y + dir.y);
    if (useWrap) {
      next = math.Point(_wrap(next.x, cols), _wrap(next.y, rows));
    } else if (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows) {
      return null;
    }
    if (_walls.contains(next)) return null;
    if (_portals.any((p) => p.a == next || p.b == next)) return null;

    final snakeSet = snake.toSet();
    if (snakeSet.contains(next)) return null;

    // ۶. فضای آزاد کافی برای ادامه‌ی حرکت
    final blocked = <math.Point<int>>{...snakeSet, ..._walls};
    final freeSpace = _floodFillForRespawn(next, blocked);
    final minFree = length + 10;
    if (freeSpace < minFree) return null;

    return snake;
  }

  /// تولید مارپیچ از `center` به بیرون
  /// ترتیب: center → 1right → 1up → 2left → 2down → 3right → 3up → ...
  /// اگه به دیوار/portal/مرز برخورد، متوقف می‌شه
  List<math.Point<int>> _generateSpiralCells(
    math.Point<int> center,
    int maxCells,
    bool useWrap,
  ) {
    final cells = <math.Point<int>>[center];
    final seen = <math.Point<int>>{center};

    final dirs = [
      math.Point(1, 0), // right
      math.Point(0, -1), // up
      math.Point(-1, 0), // left
      math.Point(0, 1), // down
    ];

    var current = center;
    var dirIdx = 0;
    var stepLen = 1;
    var stepsTaken = 0;

    while (cells.length < maxCells) {
      for (var s = 0; s < stepLen; s++) {
        final d = dirs[dirIdx];
        var next = math.Point(current.x + d.x, current.y + d.y);

        if (useWrap) {
          next = math.Point(_wrap(next.x, cols), _wrap(next.y, rows));
        } else if (next.x < 0 ||
            next.x >= cols ||
            next.y < 0 ||
            next.y >= rows) {
          return cells;
        }

        if (seen.contains(next)) return cells;
        if (_walls.contains(next)) return cells;
        if (_portals.any((p) => p.a == next || p.b == next)) {
          return cells;
        }

        cells.add(next);
        seen.add(next);
        current = next;

        if (cells.length >= maxCells) break;
      }

      if (cells.length >= maxCells) break;

      dirIdx = (dirIdx + 1) % 4;
      stepsTaken++;
      if (stepsTaken % 2 == 0) stepLen++;
    }

    return cells;
  }

  /// BFS از head، بدن مار به عنوان obstacle
  /// خروجی: تعداد cellهای قابل دسترس (شامل head)
  int _floodFillForRespawn(
    math.Point<int> start,
    Set<math.Point<int>> blocked,
  ) {
    final visited = <math.Point<int>>{start};
    final queue = <math.Point<int>>[start];
    var qi = 0;
    final useWrap = _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;

    while (qi < queue.length && visited.length < 400) {
      final curr = queue[qi++];

      for (final d in const [
        math.Point(0, -1),
        math.Point(0, 1),
        math.Point(-1, 0),
        math.Point(1, 0),
      ]) {
        var next = math.Point(curr.x + d.x, curr.y + d.y);

        if (useWrap) {
          next = math.Point(_wrap(next.x, cols), _wrap(next.y, rows));
        } else if (next.x < 0 ||
            next.x >= cols ||
            next.y < 0 ||
            next.y >= rows) {
          continue;
        }

        if (blocked.contains(next)) continue;
        if (visited.contains(next)) continue;

        visited.add(next);
        queue.add(next);
      }
    }

    return visited.length;
  }

  void _maybeEndGhost() {
    if (!mounted || !_ghostActive) return;

    final head = _snake.first;
    if (_walls.contains(head)) {
      _ghostTimer?.cancel();
      _ghostTimer = Timer(_ghostExtension, _maybeEndGhost);
      setState(() {});
      return;
    }

    setState(() {
      _ghostActive = false;
      _isEmergencyRecovery = false; // ← اضافه
    });
  }

  Future<void> _handleContinue() async {
    final cost = _continueCost;
    if (cost <= 0) {
      if (mounted) setState(() => _isShowingContinueDialog = false);
      _startEndCountdown();
      return;
    }

    final success = await ShopService.spendCoins(cost);
    if (!mounted) return;

    if (!success) {
      setState(() => _isShowingContinueDialog = false);
      _startEndCountdown();
      return;
    }

    // ⚙️ ری‌ست slow (چون _gameOver تایمرهاش رو cancel کرد)
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _timer?.cancel();

    final wasTimedOut = _timedOut;
    final head = _snake.first;

    final safeDir = wasTimedOut ? null : _findSafeRoute(head);

    if (!wasTimedOut && safeDir == null) {
      // refund سکه — ادامه ممکن نیست
      await ShopService.addCoins(cost);
      if (!mounted) return;
      setState(() {
        _isShowingContinueDialog = false;
        _slowUntil = null;
        _slowRemaining = 0;
        _wasComboActive = false;
      });
      _startEndCountdown();
      return;
    }

    // ───── commit ─────
    setState(() {
      _continueCount++;
      _currentCoins -= cost;
      _isShowingContinueDialog = false;
      _slowUntil = null;
      _slowRemaining = 0;
      _wasComboActive = false;
      _isRecovering = true; // ← برای ۲۵۰ms flash
      _showShieldFlash = true;

      if (wasTimedOut) {
        _secondsLeft = 30;
      } else {
        // Continue = shield مجازی — _shieldCount تغییر نمی‌کنه
        _dir = safeDir!;
        _queued = safeDir;
      }
    });

    // ───── feedback (برای هر دو حالت) ─────
    StorageService.incrementShieldSavedCount();
    _everHadShield = true;
    _audio.playSfx(Sfx.newRecord);
    _triggerShake(intensity: 0.55);
    if (SettingsService.current.haptics) {
      HapticFeedback.mediumImpact().catchError((_) {});
    }

    // ───── ذرات آبی (باگ رفع شد) ─────
    if (SettingsService.current.particles &&
        PerformanceService.particleCount > 0) {
      _currentBurst = ParticleBurst.generate(
        origin: Offset(
          (head.x + 0.5) / cols,
          (head.y + 0.5) / rows,
        ),
        scoreDelta: 0,
        primary: const Color(0xFF00F0FF),
        textColor: const Color(0xFF00F0FF),
        rng: _rng,
      );
      _particles.forward(from: 0); // ← اضافه شد
    }

    // ───── flash ۲۵۰ms → slow ۳ ثانیه ─────
    _shieldRecoveryTimer?.cancel();
    _shieldRecoveryTimer = Timer(_shieldFreezeDuration, () {
      if (!mounted) return;

      // 🐢 شروع slow ۳ ثانیه
      _recoverySlowTimer?.cancel();
      _recoverySlowUntil = DateTime.now().add(_recoverySlowDuration);
      _recoverySlowTimer = Timer(_recoverySlowDuration, () {
        if (!mounted) return;
        setState(() => _recoverySlowUntil = null);
        _syncMoveDuration();
        if (!_over &&
            !_won &&
            !_paused &&
            !_isShowingContinueDialog &&
            !_isRecovering) {
          _restartTimer();
        }
      });

      setState(() {
        _isRecovering = false;
        _showShieldFlash = false;
      });
      _syncMoveDuration();
      if (_canRunClock) {
        _startCountdown();
      }
      _restartTimer();
      if (!_pulse.isAnimating) _pulse.repeat();
    });
  }

  void _handleContinueDecline() {
    if (!mounted) return;
    if (SettingsService.current.haptics) {
      HapticFeedback.selectionClick().catchError((_) {});
    }
    _audio.playSfx(Sfx.button);
    setState(() => _isShowingContinueDialog = false);
    _startEndCountdown();
  }

  Future<void> _finalizeGameOver() async {
    if (_timedOut) {
      _audio.playSfx(Sfx.gameOver);
      if (SettingsService.current.haptics) {
        HapticFeedback.mediumImpact().catchError((_) {});
      }
    }

    await _recordHistory(won: false);
    if (_isLevelMode) {
      _pityCount = await StorageService.incrementPity(widget.level!.id);
    }

    if (!_isLevelMode) {
      if (_newRecord) {
        await GhostService.save(
          difficulty: d,
          timeAttack: _isTimeAttack,
          ticks: _currentRecording,
        );
        _ghostRecording = GhostRecording(List<int>.from(_currentRecording));
      }

      final newAch = await AchievementsService.recordGame(
        score: _score,
        snakeLength: _snake.length,
      );
      _newAchievements = newAch;

      // 🎯 Stage 2: XP بازی (یک‌بار در session)
      if (!_gameXpCommitted) {
        final gameXp = _calculateGameXp();
        if (gameXp > 0) {
          try {
            final result = await PlayerProgressionService.addXP(
              eventId: 'game:$_gameSessionId',
              amount: gameXp,
              source: 'game',
            );
            if (result.wasDuplicate || result.xpGained > 0) {
              _gameXpCommitted = true;
            }
          } catch (e) {
            debugPrint('[GAME XP] error: $e');
          }
        } else {
          _gameXpCommitted = true;
        }
      }

      await DailyChallengesService.recordGameEnd(
        score: _score,
        foodsEaten: _foodsThisGame,
        goldenApples: _goldenApplesEaten,
        usedShield: _everHadShield,
        usedSlow: _everHadSlow,
        snakeLength: _snake.length,
        isTimeAttack: _isTimeAttack,
      );

      await MissionsService.recordGame(
        usedShield: _everHadShield,
        goldenApplesThisGame: _goldenApplesEaten,
        combosThisGame: _combosThisGame,
      );
    }

    if (!mounted) return;
    setState(() {
      _over = true;
      _endCountdown = 0;
    });

    if (_newRecord) {
      Future.delayed(const Duration(milliseconds: 450), () {
        _audio.playSfx(Sfx.newRecord);
      });
    }
  }

  void _turn(math.Point<int> delta) {
    if (_over ||
        _won ||
        _paused ||
        _isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    if (delta == const math.Point(0, 0)) return;
    if (delta.x == -_dir.x && delta.y == -_dir.y) return;
    if (delta == _dir) return;
    _queued = delta;
  }

  void _togglePause() {
    if (_over ||
        _won ||
        _isStarting ||
        _isEnding ||
        _isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    _pulse.stop();
    final next = !_paused;
    setState(() => _paused = next);
    if (next) {
      _audio.pauseMusic();
      _countdownTimer?.cancel();
    } else {
      _audio.resumeMusic();
      if (!_pulse.isAnimating) _pulse.repeat();
      if (_canRunClock) _startCountdown();
    }
  }

  void _onSwipe(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    if (v.distance < 80) return;
    if (v.dx.abs() > v.dy.abs()) {
      _turn(math.Point(v.dx > 0 ? 1 : -1, 0));
    } else {
      _turn(math.Point(0, v.dy > 0 ? 1 : -1));
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;

    final dir = _keyMap[k];
    if (dir != null) {
      _turn(dir);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      _togglePause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _exit() async {
    if (_isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    final wasPaused = _paused;
    if (!_isStarting && !_isEnding) {
      setState(() => _paused = true);
      _audio.pauseMusic();
      _countdownTimer?.cancel();
    }

    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          L10n.t('game_exit_title'),
          style: TextStyle(color: p.textPrimary),
        ),
        content: Text(
          L10n.t('game_exit_content'),
          style: TextStyle(color: p.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              L10n.t('continue_btn'),
              style: TextStyle(color: p.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              L10n.t('back'),
              style: TextStyle(color: p.food),
            ),
          ),
        ],
      ),
    );

    if (leave == true) {
      _countdownTimer?.cancel();
      _startCountdownTimer?.cancel();
      _endCountdownTimer?.cancel();
      _slowTimer?.cancel();
      _slowTickTimer?.cancel();
      _timer?.cancel();
      _audio.stopMusic();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (mounted && !wasPaused && !_isStarting && !_isEnding) {
      setState(() => _paused = false);
      _audio.resumeMusic();
      if (!_pulse.isAnimating) _pulse.repeat(); // ← اضافه
      if (_canRunClock) {
        _startCountdown();
      }
    }
  }

  void _goToNextLevel() {
    final next = LevelsService.getNext(widget.level!.id);
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: d,
          palette: p,
          level: next,
        ),
      ),
    );
  }

  Future<void> _openWinner() async {
    await StorageService.markWinnerSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WinnerScreen(palette: p),
      ),
    );
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

  Widget _header() {
    return Column(
      children: [
        Row(
          children: [
            GameCircleButton(
              palette: p,
              icon: Icons.arrow_back_rounded,
              onTap: _exit,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: L10n.t('game_score'),
                value: '$_score',
                color: p.accent,
                palette: p,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _isAnyTimed
                  ? TimerCard(
                      palette: p,
                      secondsLeft: _secondsLeft,
                      pulse: _pulse,
                    )
                  : _isLevelMode
                      ? StatCard(
                          label: L10n.t('game_progress'),
                          value: '$_foodsEaten/${widget.level!.targetFoods}',
                          color: p.food,
                          palette: p,
                        )
                      : StatCard(
                          label: L10n.t('game_record'),
                          value: '$_best',
                          color: p.food,
                          palette: p,
                        ),
            ),
            const SizedBox(width: 8),
            GameCircleButton(
              palette: p,
              icon: (_over || _won)
                  ? Icons.refresh_rounded
                  : (_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              onTap: (_over || _won) ? _reset : _togglePause,
            ),
          ],
        ),
        if (_isTimedLevel) ...[
          const SizedBox(height: 8),
          FoodProgressBar(
            palette: p,
            eaten: _foodsEaten,
            target: widget.level!.targetFoods,
          ),
        ],
      ],
    );
  }

  Widget _board(GameSettings settings) {
    final animations = <Listenable>[_pulse, _moveAnim];
    // _rainbow animation دیگه لازم نیست (اسکین رنگین‌کمان از _pulse استفاده می‌کنه)
    if (settings.wrapEffect) animations.add(_wrapAnim);
    final hasNextLevel =
        _isLevelMode && LevelsService.getNext(widget.level!.id) != null;
    return AspectRatio(
      aspectRatio: 1,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: p.board,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: p.accent.withOpacity(0.10),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ═══════════ 👻 تغییر ۱: Opacity روی بورد ═══════════
                GestureDetector(
                  onTapDown: (_) => _focus.requestFocus(),
                  onPanEnd: _onSwipe,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(animations),
                    builder: (context, _) => Opacity(
                      opacity: _ghostActive ? 0.55 : 1.0,
                      child: CustomPaint(
                        painter: BoardPainter(
                          snake: _snake,
                          prevSnake: _prevSnake,
                          moveProgress: _moveAnim.value,
                          snakeSkin: _snakeSkin,
                          foodSkin: _foodSkin,
                          trail: _trail,
                          pattern: _pattern,
                          patternIntensity: _patternIntensity,
                          ghostSkin: _ghostSkin,
                          timePhase: _pulse.value,
                          food: _food,
                          dir: _dir,
                          palette: p,
                          pulse: _pulse.value,
                          cols: cols,
                          rows: rows,
                          powerUpType: _currentPowerUp?.type,
                          showGrid: settings.showGrid,
                          rainbow: false,
                          rainbowPhase: _rainbow.value,
                          wrapEvent: _wrapEvent,
                          wrapProgress: _wrapAnim.value,
                          walls: _walls,
                          ghost: settings.showGhost ? _ghostBody() : null,
                          portals: _portals,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _particles,
                    builder: (context, _) => CustomPaint(
                      painter: ParticlePainter(
                        burst: _currentBurst,
                        progress: _particles.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                if (_isComboActive)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) {
                        final alpha = 0.18 + 0.22 * _pulse.value;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(alpha),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withOpacity(alpha * 0.4),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _comboFlash,
                    builder: (_, __) {
                      if (_comboFlash.value >= 1.0) {
                        return const SizedBox.shrink();
                      }
                      final pr = _comboFlash.value;
                      final alpha = (1 - pr).clamp(0.0, 1.0);
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: const Color(0xFFFFD700)
                                .withOpacity(alpha * 0.9),
                            width: 3 + 8 * (1 - pr),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withOpacity(alpha * 0.55),
                              blurRadius: 30 * (1 - pr) + 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_isIntroPlaying)
                  AnimatedBuilder(
                    animation: _introAnim,
                    builder: (_, __) => IntroOverlay(
                      type: _introAnimation,
                      progress: _introAnim.value,
                      palette: p,
                    ),
                  ),
                if (_isStarting)
                  StartCountdownOverlay(
                    palette: p,
                    countdown: _countdown,
                    showPity: _isLevelMode && _pityShields > 0,
                    pityShields: _pityShields,
                  ),
                // ═══════════ 👻 تغییر ۲: Ghost Border Overlay ═══════════
                if (_ghostActive)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: _isEmergencyRecovery
                              ? const Color(0xFFFFD700).withOpacity(0.7)
                              : const Color(0xFF00F0FF).withOpacity(0.7),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isEmergencyRecovery
                                ? const Color(0xFFFFD700).withOpacity(0.5)
                                : const Color(0xFF00F0FF).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showShieldFlash)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: _isEmergencyRecovery
                              ? const Color(0xFFFFD700).withOpacity(0.9)
                              : const Color(0xFF00F0FF).withOpacity(0.8),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isEmergencyRecovery
                                ? const Color(0xFFFFD700).withOpacity(0.6)
                                : const Color(0xFF00F0FF).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isEmergencyRecovery ? '🕊️' : '🛡️',
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                if (_isEnding)
                  EndCountdownOverlay(
                    palette: p,
                    endCountdown: _endCountdown,
                  ),
                if (_isShowingContinueDialog)
                  ContinueOverlay(
                    palette: p,
                    coins: _currentCoins,
                    cost: _continueCost,
                    onContinue: _handleContinue,
                    onDecline: _handleContinueDecline,
                  ),
                if (_isShowingEmergencyDialog)
                  EmergencyOverlay(
                    palette: p,
                    coins: _currentCoins,
                    cost: _emergencyRescuePrice,
                    onContinue: _handleEmergencyAccept,
                    onDecline: _handleEmergencyDecline,
                  ),
                if (_over || _paused || _won)
                  GameOverlay(
                    palette: p,
                    won: _won,
                    over: _over,
                    paused: _paused,
                    timedOut: _timedOut,
                    isLevelMode: _isLevelMode,
                    isTimeAttack: _isTimeAttack,
                    level: widget.level,
                    score: _score,
                    best: _best,
                    foodsEaten: _foodsEaten,
                    newRecord: _newRecord,
                    newAchievements: _newAchievements,
                    hasNextLevel: hasNextLevel,
                    onBack: () => Navigator.of(context).pop(),
                    onReset: _reset,
                    onTogglePause: _togglePause,
                    onNextLevel: _goToNextLevel,
                    onOpenWinner: _openWinner,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
