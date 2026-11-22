// ignore_for_file: unused_element, invalid_use_of_protected_member

part of '../game_screen.dart';

extension _GameSuddenPortalLogic on _GameScreenState {
  List<PortalPair> get _visiblePortals {
    final pending = _pendingPortal;
    if (pending == null) return _portals;
    final show = (DateTime.now().millisecondsSinceEpoch ~/ 250).isEven;
    return show ? [..._portals, pending] : _portals;
  }

  void _schedulePortalSpawn() {
    _portalTimer?.cancel();
    if (_isLevelMode) return;
    _portalTimer = Timer(
      Duration(seconds: 20 + _rng.nextInt(36)),
      _spawnSuddenPortal,
    );
  }

  void _spawnSuddenPortal() {
    if (!mounted || _over || _won) return;
    if (_paused ||
        _isStarting ||
        _isEnding ||
        _isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      _portalTimer = Timer(const Duration(seconds: 3), _spawnSuddenPortal);
      return;
    }
    final pair = _pickPortalPair();
    if (pair == null) {
      _portalTimer = Timer(const Duration(seconds: 4), _spawnSuddenPortal);
      return;
    }
    setState(() => _pendingPortal = pair);
    AppHaptics.selection();
    if (SettingsService.current.sfx) _audio.playSfx(Sfx.button);
    _portalTimer = Timer(const Duration(seconds: 1), _activatePortal);
  }

  PortalPair? _pickPortalPair() {
    final head = _snake.first;
    final walls = _walls;

    math.Point<int>? norm(math.Point<int> c) {
      if (_useWrap) return math.Point(_wrap(c.x, cols), _wrap(c.y, rows));
      if (c.x < 0 || c.x >= cols || c.y < 0 || c.y >= rows) return null;
      return c;
    }

    bool free(math.Point<int>? c) =>
        c != null &&
        c != _food &&
        !_snake.contains(c) &&
        !_botSnake.contains(c) &&
        !walls.contains(c);

    // ورودی: چند خونه جلوی سر مار
    final perSec = math.max(1, 1000 ~/ _effectiveTick().inMilliseconds);
    math.Point<int>? a;
    for (var i = 0; i < 12 && a == null; i++) {
      final k = perSec + 3 + _rng.nextInt(4);
      final side = _rng.nextInt(3) - 1;
      final c = norm(math.Point(
        head.x + _dir.x * k + _dir.y.abs() * side,
        head.y + _dir.y * k + _dir.x.abs() * side,
      ));
      if (free(c)) a = c;
    }
    if (a == null) return null;

    // خروجی: گاهی نزدیک غذای طلایی
    final nearFood =
        _currentPowerUp?.type == PowerUpType.golden && _rng.nextDouble() < 0.5;
    math.Point<int>? b;
    for (var i = 0; i < 30 && b == null; i++) {
      final c = nearFood
          ? norm(math.Point(
              _food.x + _rng.nextInt(7) - 3,
              _food.y + _rng.nextInt(7) - 3,
            ))
          : math.Point(_rng.nextInt(cols), _rng.nextInt(rows));
      if (c == null || c == a || !free(c)) continue;
      if (!nearFood && (c.x - a.x).abs() + (c.y - a.y).abs() < 8) continue;
      if (!free(norm(math.Point(c.x + _dir.x, c.y + _dir.y)))) continue;
      b = c;
    }
    if (b == null) return null;

    final color = nearFood
        ? PortalColors.gold
        : const [
            PortalColors.cyan,
            PortalColors.purple,
            PortalColors.green,
          ][_rng.nextInt(3)];
    return PortalPair(a: a, b: b, color: color);
  }

  void _activatePortal() {
    final pair = _pendingPortal;
    if (!mounted || pair == null) return;
    if (_paused) {
      _portalTimer = Timer(const Duration(seconds: 1), _activatePortal);
      return;
    }
    final walls = _walls;
    bool bad(math.Point<int> c) =>
        c == _food ||
        _snake.contains(c) ||
        _botSnake.contains(c) ||
        walls.contains(c);
    if (bad(pair.a) || bad(pair.b)) {
      setState(() => _pendingPortal = null);
      _schedulePortalSpawn();
      return;
    }
    _botTakesPortal = _hasBot && _rng.nextDouble() < 0.35;
    setState(() {
      _dynamicPortals = [pair];
      _pendingPortal = null;
    });
    _portalLife = 8;
    _portalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (--_portalLife <= 0) _closePortal();
    });
  }

  void _closePortal() {
    _portalTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _dynamicPortals = [];
      _pendingPortal = null;
    });
    _schedulePortalSpawn();
  }

  void _onSuddenPortalUsed() {
    if (_dynamicPortals.isEmpty) return;
    _closePortal();
  }

  bool _botEnteredSuddenPortal(math.Point<int> head, math.Point<int> dir) {
    if (_dynamicPortals.isEmpty) return false;
    var cell = math.Point(head.x + dir.x, head.y + dir.y);
    if (_useWrap) cell = math.Point(_wrap(cell.x, cols), _wrap(cell.y, rows));
    return _dynamicPortals.any((p) => p.contains(cell));
  }
}
