// ignore_for_file: unused_element, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of '../game_screen.dart';

extension _GameEffectsLogic on _GameScreenState {

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

  void _triggerPortalBurst(math.Point<int> from, math.Point<int> to) {
    _audio.playSfx(Sfx.newRecord);
    if (PerformanceService.particleCount == 0) return;
    AppHaptics.selection();
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

  void _triggerShake({double intensity = 1.0}) {
    if (!SettingsService.current.screenShake) return;
    _shakeIntensity = intensity;
    _shake.forward(from: 0);
  }

  void _checkComboActivation() {
    final isCombo = _isComboActive;
    if (isCombo && !_wasComboActive) {
      _combosThisGame++;
      _comboFlash.forward(from: 0);
      _audio.playSfx(Sfx.newRecord);
      AppHaptics.medium();
    }
    _wasComboActive = isCombo;
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




}