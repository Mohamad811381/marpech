// ignore_for_file: unused_element, invalid_use_of_protected_member

part of '../game_screen.dart';

const math.Point<int> _botSpawnPoint = math.Point(cols - 5, 4);
const Duration _botRespawnDelay = Duration(milliseconds: 1500);

const List<math.Point<int>> _kDirs = [
  math.Point(0, -1),
  math.Point(0, 1),
  math.Point(-1, 0),
  math.Point(1, 0),
];

extension _GameBotLogic on _GameScreenState {
  bool get _useWrap =>
      _isLevelMode ? (widget.level?.wrapEnabled ?? true) : d.wrap;

  // ───────── شروع ─────────

  void _resetBot() {
    _botRespawnTimer?.cancel();
    _botScore = 0;
    _botSnake = [];
    _prevBotSnake = [];
    if (_hasBot) _spawnBot();
  }

  void _spawnBot() {
    final s = _tryRespawnSnake(
      3,
      preferred: _botSpawnPoint,
      avoid: {..._snake, ..._botSnake},
    );
    if (s == null) return;
    _botSnake = s;
    _prevBotSnake = List.from(s);
    _botDir = math.Point(s[0].x - s[1].x, s[0].y - s[1].y);
  }

  void _killBot() {
    _botSnake = [];
    _prevBotSnake = [];
    _botRespawnTimer?.cancel();
    _botRespawnTimer = Timer(_botRespawnDelay, () {
      if (!mounted || _over || _won) return;
      setState(_spawnBot);
    });
  }

  // ───────── حرکت ─────────

  /// خانه‌ی بعدی با در نظر گرفتن wrap، دیوار و پورتال. null یعنی مسدوده.
  math.Point<int>? _peekNext(math.Point<int> head, math.Point<int> dir) {
    var next = math.Point(head.x + dir.x, head.y + dir.y);
    if (_useWrap) {
      next = math.Point(_wrap(next.x, cols), _wrap(next.y, rows));
    } else if (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows) {
      return null;
    }
    if (_walls.contains(next)) return null;
    final dest = _getPortalDestination(next);
    if (dest != null) {
      next = dest;
      if (_walls.contains(next)) return null;
    }
    return next;
  }

  void _botStep() {
    if (!_hasBot || _botSnake.isEmpty) return;

    final dir = _botPickDir();
    if (dir == null) {
      _killBot();
      return;
    }
    final next = _peekNext(_botSnake.first, dir)!;
    final ate = next == _food;

    _prevBotSnake = List.from(_botSnake);
    _botDir = dir;
    _botSnake = [next, ..._botSnake];
    if (ate) {
      _botScore += 10 * d.multiplier;
      _spawnFood();
    } else {
      _botSnake.removeLast();
    }
  }

  // ───────── انتخاب جهت ─────────

  math.Point<int>? _botPickDir() {
    final head = _botSnake.first;
    final blocked = <math.Point<int>>{
      ..._snake,
      ..._botSnake.take(_botSnake.length - 1), // دم ربات آزاد می‌شه
    };

    // جهت ← خانه‌ی بعدی
    final options = <math.Point<int>, math.Point<int>>{};
    for (final dir in _kDirs) {
      if (dir.x == -_botDir.x && dir.y == -_botDir.y) continue;
      final cell = _peekNext(head, dir);
      if (cell == null || blocked.contains(cell)) continue;
      options[dir] = cell;
    }
    if (options.isEmpty) return null;

    // 🎲 اشتباه تصادفی
    if (_rng.nextDouble() < d.botMistakeChance) {
      return options.keys.elementAt(_rng.nextInt(options.length));
    }

    // مسیر به غذا
    final toFood = _botFirstStepToFood(options, blocked);
    if (toFood != null &&
        (!d.botLooksAhead ||
            _floodFillForRespawn(options[toFood]!, blocked) >=
                _botSnake.length)) {
      return toFood;
    }

    // وگرنه جهتی که بیشترین فضای خالی رو داره
    math.Point<int>? best;
    var bestSpace = -1;
    for (final e in options.entries) {
      final space = _floodFillForRespawn(e.value, blocked);
      if (space > bestSpace) {
        bestSpace = space;
        best = e.key;
      }
    }
    return best;
  }

  /// BFS تا غذا. خروجی: اولین جهت مسیر (یا null اگه مسیری نباشه)
  math.Point<int>? _botFirstStepToFood(
    Map<math.Point<int>, math.Point<int>> options,
    Set<math.Point<int>> blocked,
  ) {
    final firstDir = <math.Point<int>, math.Point<int>>{};
    final queue = <math.Point<int>>[];
    for (final e in options.entries) {
      firstDir[e.value] = e.key;
      queue.add(e.value);
    }
    var qi = 0;
    while (qi < queue.length) {
      final cur = queue[qi++];
      if (cur == _food) return firstDir[cur];
      for (final dir in _kDirs) {
        final n = _peekNext(cur, dir);
        if (n == null || blocked.contains(n) || firstDir.containsKey(n)) {
          continue;
        }
        firstDir[n] = firstDir[cur]!;
        queue.add(n);
      }
    }
    return null;
  }
}
