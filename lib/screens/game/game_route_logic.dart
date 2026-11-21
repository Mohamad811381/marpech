// ignore_for_file: invalid_use_of_protected_member, unused_element

part of '../game_screen.dart';

extension _GameRouteLogic on _GameScreenState {
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

    if (safeDir == null && !_isLevelMode && !_emergencyUsedThisSession) {
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
      AppHaptics.heavy();
      _finalizeGameOver();
      return;
    }

    // مسیر امن وجود دارد اما سپر نداریم؛ Continue عادی حفظ می‌شود.
    _gameOver();
  }

  Future<void> _showEmergencyRescueDialog() async {
    if (_isLevelMode || _isShowingEmergencyDialog) return;
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
    AppHaptics.selection();
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
    AppHaptics.heavy();

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
    AppHaptics.medium();

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
    AppHaptics.medium();

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
    AppHaptics.selection();
    _audio.playSfx(Sfx.button);
    setState(() => _isShowingContinueDialog = false);
    _startEndCountdown();
  }

  Future<void> _showContinueDialog() async {
    AppHaptics.medium();

    final coins = await ShopService.getCoins();
    if (!mounted) return;
    setState(() {
      _currentCoins = coins;
      _isShowingContinueDialog = true;
    });
  }
}
