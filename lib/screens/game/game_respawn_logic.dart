// ignore_for_file: curly_braces_in_flow_control_structures, unused_element

part of '../game_screen.dart';

extension _GameRespawnLogic on _GameScreenState {
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
    var dx = snake[0].x - snake[1].x;
    var dy = snake[0].y - snake[1].y;
    if (useWrap) {
      if (dx > 1)
        dx -= cols;
      else if (dx < -1) dx += cols;
      if (dy > 1)
        dy -= rows;
      else if (dy < -1) dy += rows;
    }
    final dir = math.Point(dx, dy);
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
      const math.Point(1, 0), // right
      const math.Point(0, -1), // up
      const math.Point(-1, 0), // left
      const math.Point(0, 1), // down
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
}
