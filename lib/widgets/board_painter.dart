// ignore_for_file: unused_local_variable, prefer_const_declarations, unrelated_type_equality_checks, deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../models/power_up.dart';
import '../models/skins.dart';
import '../models/portal.dart';
import '../models/board_pattern.dart';
import '../services/performance_service.dart';

class WrapEvent {
  final Point<int> from;
  final Point<int> to;
  final Point<int> dir;
  const WrapEvent({required this.from, required this.to, required this.dir});
}

class BoardPainter extends CustomPainter {
  final List<PortalPair> portals;
  final List<Point<int>> snake;
  final List<Point<int>>? prevSnake;
  final double moveProgress;
  final Point<int> food;
  final Point<int> dir;
  final GamePalette palette;
  final double pulse;
  final int cols, rows;
  final PowerUpType? powerUpType;
  final bool showGrid;
  final bool rainbow;
  final double rainbowPhase;
  final WrapEvent? wrapEvent;
  final double wrapProgress;
  final Set<Point<int>> walls;
  final SnakeSkin snakeSkin;
  final FoodSkin foodSkin;
  final TrailEffect trail;
  final BoardPattern pattern;
  final PatternIntensity patternIntensity;
  final GhostSkin ghostSkin;
  final double timePhase; // 0..1 for animated skins

  /// 👻 بدن شبح، از سر به دم
  final List<({int x, int y})>? ghost;

  BoardPainter({
    this.portals = const [], // ← جدید

    required this.snake,
    required this.prevSnake,
    required this.moveProgress,
    required this.food,
    required this.dir,
    required this.palette,
    required this.pulse,
    required this.cols,
    required this.rows,
    this.powerUpType,
    this.showGrid = true,
    this.rainbow = false,
    this.rainbowPhase = 0,
    this.wrapEvent,
    this.wrapProgress = 1,
    this.walls = const {},
    this.ghost,
    this.snakeSkin = SnakeSkin.basic,
    this.foodSkin = FoodSkin.basic,
    this.trail = TrailEffect.none,
    this.pattern = BoardPattern.none,
    this.patternIntensity = PatternIntensity.subtle,
    this.ghostSkin = GhostSkin.basic,
    this.timePhase = 0,
  });
  Color get _foodColor {
    switch (powerUpType) {
      case PowerUpType.golden:
        return const Color(0xFFFFD700);
      case PowerUpType.shield:
        return const Color(0xFF00F0FF);
      case PowerUpType.slow:
        return const Color(0xFF8A7BFF);
      default:
        return _foodSkinColor(foodSkin);
    }
  }

  Color _foodSkinColor(FoodSkin skin) {
    switch (skin) {
      case FoodSkin.basic:
        return const Color(0xFFE53935);
      case FoodSkin.pizza:
        return const Color(0xFFFF9800);
      case FoodSkin.burger:
        return const Color(0xFF8D6E63);
      case FoodSkin.donut:
        return const Color(0xFFEC407A);
      case FoodSkin.grape:
        return const Color(0xFF9C27B0);
      case FoodSkin.star:
        return const Color(0xFFFFD700);
      case FoodSkin.cherry:
        return const Color(0xFFD32F2F);
      case FoodSkin.watermelon:
        return const Color(0xFF4CAF50);
      case FoodSkin.goldenTrophyFood:
        return const Color(0xFFFFD700);
    }
  }

  void _paintPortals(Canvas canvas, double cell) {
    if (portals.isEmpty) return;
    for (final pair in portals) {
      _paintSinglePortal(canvas, pair.a, cell, pair.color);
      _paintSinglePortal(canvas, pair.b, cell, pair.color);
    }
  }

  void _paintSinglePortal(
      Canvas canvas, Point<int> pos, double cell, Color color) {
    final cx = (pos.x + 0.5) * cell;
    final cy = (pos.y + 0.5) * cell;
    final center = Offset(cx, cy);
    final pulseT = 0.5 + 0.5 * sin(pulse * pi * 2);

    // هاله‌ی بیرونی
    canvas.drawCircle(
      center,
      cell * 0.45,
      Paint()
        ..color = color.withOpacity(0.15 + 0.15 * pulseT)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // حلقه‌ی بیرونی رنگی
    canvas.drawCircle(
      center,
      cell * 0.35,
      Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.09,
    );

    // حلقه‌ی درونی سفید
    canvas.drawCircle(
      center,
      cell * 0.18,
      Paint()
        ..color = Colors.white.withOpacity(0.45 + 0.30 * pulseT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.04,
    );

    // نقطه‌ی مرکزی
    canvas.drawCircle(
      center,
      cell * 0.05,
      Paint()..color = color.withOpacity(0.7),
    );
  }

  Color _segmentColor(int index, int total) {
    // 🎨 اگه اسکین basic هست، rainbow تنظیمات اعمال می‌شه
    // اگه اسکین خاص انتخاب شده، اسکین اولویت داره
    // if (snakeSkin == SnakeSkin.basic && rainbow) {
    //   final hue = (rainbowPhase * 360 + index * 15) % 360;
    //   return HSVColor.fromAHSV(1.0, hue, 0.7, 1.0).toColor();
    // }

    final t = total <= 1 ? 0.0 : index / (total - 1);

    switch (snakeSkin) {
      case SnakeSkin.fire:
        // نارنجی آتشین → زرد شعله
        return Color.lerp(
          const Color(0xFFFF2E00),
          const Color(0xFFFFDD00),
          t,
        )!;

      case SnakeSkin.pixel:
        // فیروزه‌ای → مجنتا
        return Color.lerp(
          const Color(0xFF00FFFF),
          const Color(0xFFFF00FF),
          t,
        )!;

      case SnakeSkin.galaxy:
        // بنفش روشن → سرمه‌ای
        return Color.lerp(
          const Color(0xFFB388FF),
          const Color(0xFF311B92),
          t,
        )!;

      case SnakeSkin.rainbow:
        // رنگین‌کمان جاری
        final hue = (t * 360 + timePhase * 360) % 360;
        return HSVColor.fromAHSV(1.0, hue, 0.9, 1.0).toColor();

      case SnakeSkin.ice:
        // یخی: سفید-آبی → آبی متوسط
        return Color.lerp(
          const Color(0xFFE1F5FE),
          const Color(0xFF0288D1),
          t,
        )!;

      case SnakeSkin.gold:
        // طلایی روشن → نارنجی تیره
        return Color.lerp(
          const Color(0xFFFFE082),
          const Color(0xFF8B6914),
          t,
        )!;

      case SnakeSkin.neon:
        // صورتی نئون ثابت
        return const Color(0xFFFF1493);

      case SnakeSkin.shadow:
        // تقریباً سیاه → بنفش تیره
        return Color.lerp(
          const Color(0xFF000000),
          const Color(0xFF4A148C),
          t,
        )!;
      case SnakeSkin.veteranSnakeSkin:
        // سبز زیتونی کهنه‌کار → سبز تیره نظامی
        return Color.lerp(
          const Color(0xFF9ACD32),
          const Color(0xFF3E5010),
          t,
        )!;

      case SnakeSkin.basic:
        return Color.lerp(palette.snakeHead, palette.snakeTail, t)!;
    }
  }

  Offset _interpCenter(int index) {
    final to = snake[index];
    final from = (prevSnake != null && index < prevSnake!.length)
        ? prevSnake![index]
        : to;

    final dx = (to.x - from.x).abs();
    final dy = (to.y - from.y).abs();
    final wrapped = dx > cols ~/ 2 || dy > rows ~/ 2;

    if (wrapped) {
      return Offset(to.x + 0.5, to.y + 0.5);
    }
    final ix = from.x + (to.x - from.x) * moveProgress;
    final iy = from.y + (to.y - from.y) * moveProgress;
    return Offset(ix + 0.5, iy + 0.5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;
    final q = PerformanceService.effective;
    final blur = PerformanceService.blurMultiplier;
    final glow = PerformanceService.glowEnabled;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = palette.grid
        ..strokeWidth = 1;
      for (var i = 1; i < cols; i++) {
        final x = i * cell;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (var j = 1; j < rows; j++) {
        final y = j * cell;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    if (pattern != BoardPattern.none) {
      _paintPattern(canvas, size, cell);
    }

    _paintWalls(canvas, cell);
    if (trail != TrailEffect.none) _paintTrail(canvas, cell);
    _paintPortals(canvas, cell);
    _paintGhost(canvas, cell);
    _paintFood(canvas, cell);

    // بدن مار بازیکن
    for (var i = snake.length - 1; i >= 0; i--) {
      final c = _interpCenter(i);
      final cx = c.dx * cell;
      final cy = c.dy * cell;
      final color = _segmentColor(i, snake.length);

      final rect = Rect.fromLTWH(
        cx - cell / 2,
        cy - cell / 2,
        cell,
        cell,
      ).deflate(cell * 0.07);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(cell * 0.32),
      );

      if (i == 0 && glow) {
        canvas.drawRRect(
          rrect.inflate(cell * 0.04),
          Paint()
            ..color = color.withOpacity(0.38)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * blur),
        );
      }

      // 🎨 رندر مخصوص اسکین
      switch (snakeSkin) {
        case SnakeSkin.pixel:
          final pixelRect = Rect.fromLTWH(
            cx - cell / 2 + 1,
            cy - cell / 2 + 1,
            cell - 2,
            cell - 2,
          );
          canvas.drawRect(pixelRect, Paint()..color = color);
          canvas.drawRect(
            pixelRect.deflate(cell * 0.22),
            Paint()..color = color.withOpacity(0.55),
          );
          break;

        case SnakeSkin.galaxy:
          canvas.drawRRect(rrect, Paint()..color = color);
          if (i % 2 == 0) {
            final starSeed = (i * 37 + 13) % 100;
            final sx = cx + (starSeed % 7 - 3) * cell * 0.08;
            final sy = cy + ((starSeed * 7) % 7 - 3) * cell * 0.08;
            canvas.drawCircle(
              Offset(sx, sy),
              cell * 0.05,
              Paint()..color = Colors.white.withOpacity(0.85),
            );
          }
          break;

        case SnakeSkin.fire:
          canvas.drawRRect(rrect, Paint()..color = color);
          if (PerformanceService.fancySkinEnabled) {
            canvas.drawRRect(
              rrect.inflate(cell * 0.02),
              Paint()
                ..color = const Color(0xFFFFAA00).withOpacity(
                    0.35 + 0.25 * sin(timePhase * pi * 2 + i * 0.4))
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * blur),
            );
          }
          break;

        case SnakeSkin.rainbow:
          canvas.drawRRect(rrect, Paint()..color = color);
          break;

        case SnakeSkin.ice:
          canvas.drawRRect(rrect, Paint()..color = color);
          // بلور کریستالی سفید
          final crystalAlpha = 0.35 + 0.20 * sin(timePhase * pi * 2 + i * 0.5);
          canvas.drawCircle(
            Offset(cx + cell * 0.06, cy - cell * 0.06),
            cell * 0.09,
            Paint()..color = Colors.white.withOpacity(crystalAlpha),
          );
          if (i % 3 == 0) {
            canvas.drawCircle(
              Offset(cx - cell * 0.08, cy + cell * 0.08),
              cell * 0.05,
              Paint()..color = Colors.white.withOpacity(0.6),
            );
          }
          break;

        case SnakeSkin.gold:
          canvas.drawRRect(rrect, Paint()..color = color);
          // درخشش عبوری (shine sweep)
          final shinePos = (timePhase * 3 - i * 0.15) % 1.0;
          if (shinePos > 0.0 && shinePos < 0.5) {
            final shineAlpha =
                (0.55 * (1 - (shinePos - 0.25).abs() * 4)).clamp(0.0, 0.55);
            canvas.drawRRect(
              rrect,
              Paint()
                ..shader = LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(shineAlpha),
                    Colors.white.withOpacity(0),
                  ],
                ).createShader(rect),
            );
          }
          // ستاره‌های کوچک
          if (i % 3 == 0) {
            _drawStar(
              canvas,
              Offset(cx, cy),
              cell * 0.12,
              Colors.white.withOpacity(0.85),
            );
          }
          break;

        case SnakeSkin.neon:
          if (PerformanceService.fancySkinEnabled) {
            final pulse = 0.5 + 0.5 * sin(timePhase * pi * 2 + i * 0.2);
            canvas.drawRRect(
              rrect.inflate(cell * 0.06),
              Paint()
                ..color =
                    const Color(0xFFFF1493).withOpacity(0.30 + 0.40 * pulse)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * blur),
            );
          }
          canvas.drawRRect(rrect, Paint()..color = color);
          break;

        case SnakeSkin.shadow:
          if (PerformanceService.fancySkinEnabled) {
            canvas.drawRRect(
              rrect.inflate(cell * 0.03),
              Paint()
                ..color = const Color(0xFF9C27B0).withOpacity(
                    0.30 + 0.15 * sin(timePhase * pi * 2 + i * 0.3))
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * blur),
            );
          }
          canvas.drawRRect(rrect, Paint()..color = color);
          canvas.drawRRect(
            rrect.deflate(cell * 0.15),
            Paint()..color = Colors.black.withOpacity(0.45),
          );
          break;

        case SnakeSkin.veteranSnakeSkin:
          canvas.drawRRect(rrect, Paint()..color = color);
          // نشان کهنه‌کار — رگه‌های نظامی
          if (i % 3 == 0) {
            canvas.drawCircle(
              Offset(cx, cy),
              cell * 0.08,
              Paint()..color = Colors.white.withOpacity(0.6),
            );
          }
          break;

        case SnakeSkin.basic:
          canvas.drawRRect(rrect, Paint()..color = color);
          break;
      }
    }

    // چشم‌ها
    final headCenter = _interpCenter(0);
    final center = Offset(headCenter.dx * cell, headCenter.dy * cell);
    final f = Offset(dir.x.toDouble(), dir.y.toDouble()) * (cell * 0.16);
    final s = Offset(-dir.y.toDouble(), dir.x.toDouble()) * (cell * 0.17);
    final eyePaint = Paint()..color = palette.bg;
    canvas.drawCircle(center + f + s, cell * 0.085, eyePaint);
    canvas.drawCircle(center + f - s, cell * 0.085, eyePaint);

    if (wrapEvent != null && wrapProgress < 1.0) {
      _paintWrapEffect(canvas, size, cell);
    }
  }

  // ---------- 👻 شبح ----------

  void _paintGhost(Canvas canvas, double cell) {
    final g = ghost;
    if (g == null || g.isEmpty) return;

    for (var i = g.length - 1; i >= 0; i--) {
      final p = g[i];
      final isHead = i == 0;
      final t = g.length <= 1 ? 0.0 : i / (g.length - 1);

      Color ghostColor;
      double alpha;
      double glow = 1.0;

      switch (ghostSkin) {
        case GhostSkin.basic:
          ghostColor = Colors.white;
          alpha = isHead ? 0.42 : 0.24;
          break;

        case GhostSkin.golden:
          ghostColor = const Color(0xFFFFD700);
          alpha = isHead ? 0.55 : 0.35;
          glow = 1.4;
          break;

        case GhostSkin.dragon:
          ghostColor = const Color(0xFFFF4400);
          alpha = isHead ? 0.55 : 0.35;
          glow = 1.5;
          break;

        case GhostSkin.spirit:
          final wave = 0.5 + 0.3 * sin(timePhase * pi * 2);
          ghostColor = const Color(0xFF80E0FF);
          alpha = isHead ? (0.35 + 0.15 * wave) : (0.20 + 0.10 * wave);
          glow = 1.2;
          break;

        case GhostSkin.rainbow:
          final hue = (t * 360 + timePhase * 360) % 360;
          ghostColor = HSVColor.fromAHSV(1.0, hue, 0.75, 1.0).toColor();
          alpha = isHead ? 0.55 : 0.35;
          glow = 1.3;
          break;

        case GhostSkin.ice:
          ghostColor = Color.lerp(
            const Color(0xFFB3E5FC),
            const Color(0xFF0288D1),
            t,
          )!;
          alpha = isHead ? 0.50 : 0.30;
          glow = 1.3;
          break;

        case GhostSkin.electric:
          final flicker = 0.7 + 0.3 * sin(timePhase * pi * 2 + i * 0.5);
          ghostColor = const Color(0xFFFFEB3B);
          alpha = (isHead ? 0.60 : 0.40) * flicker;
          glow = 1.6;
          break;

        case GhostSkin.phantom:
          ghostColor = const Color(0xFF4A148C);
          alpha = isHead ? 0.45 : 0.28;
          glow = 1.2;
          break;

        case GhostSkin.blossom:
          ghostColor = Color.lerp(
            const Color(0xFFFFB6E0),
            const Color(0xFFC2185B),
            t,
          )!;
          alpha = isHead ? 0.55 : 0.35;
          glow = 1.3;
          break;

        case GhostSkin.eliteGhostSkin:
          ghostColor = const Color(0xFF7C4DFF);
          alpha = isHead ? 0.55 : 0.35;
          glow = 1.5;
          break;
      }

      final rect = Rect.fromLTWH(
        p.x * cell,
        p.y * cell,
        cell,
        cell,
      ).deflate(cell * 0.10);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(cell * 0.32),
      );

      if (isHead) {
        canvas.drawRRect(
          rrect.inflate(cell * 0.04 * glow),
          Paint()
            ..color = ghostColor.withOpacity(0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * glow),
        );
      }
      canvas.drawRRect(
        rrect,
        Paint()..color = ghostColor.withOpacity(alpha),
      );

      // ✨ افکت‌های ویژه
      final cx = (p.x + 0.5) * cell;
      final cy = (p.y + 0.5) * cell;

      // ❄️ یخی — بلورهای سفید
      if (ghostSkin == GhostSkin.ice && i % 2 == 0) {
        canvas.drawCircle(
          Offset(cx + cell * 0.08, cy - cell * 0.06),
          cell * 0.05,
          Paint()..color = Colors.white.withOpacity(0.85),
        );
      }

      // ⚡ الکتریکی — رعد کوچیک
      if (ghostSkin == GhostSkin.electric && i % 3 == 0) {
        final boltPaint = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..strokeWidth = cell * 0.05
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(cx - cell * 0.10, cy - cell * 0.15),
          Offset(cx + cell * 0.05, cy + cell * 0.15),
          boltPaint,
        );
      }

      // 💀 شبح — چشم‌های گود روی سر
      if (ghostSkin == GhostSkin.phantom && isHead) {
        final eyeOffset = cell * 0.15;
        final eyeY = cy - cell * 0.05;
        // گود سیاه
        canvas.drawCircle(
          Offset(cx - eyeOffset, eyeY),
          cell * 0.08,
          Paint()..color = Colors.black.withOpacity(0.75),
        );
        canvas.drawCircle(
          Offset(cx + eyeOffset, eyeY),
          cell * 0.08,
          Paint()..color = Colors.black.withOpacity(0.75),
        );
        // درخشش ارغوانی داخل
        canvas.drawCircle(
          Offset(cx - eyeOffset, eyeY),
          cell * 0.03,
          Paint()..color = const Color(0xFFE040FB).withOpacity(0.9),
        );
        canvas.drawCircle(
          Offset(cx + eyeOffset, eyeY),
          cell * 0.03,
          Paint()..color = const Color(0xFFE040FB).withOpacity(0.9),
        );
      }

      // 🌸 شکوفه — گلبرگ‌های سفید
      if (ghostSkin == GhostSkin.blossom && i % 2 == 0) {
        canvas.drawCircle(
          Offset(cx - cell * 0.06, cy + cell * 0.06),
          cell * 0.04,
          Paint()..color = Colors.white.withOpacity(0.85),
        );
      }
    }
  }
  // ---------- دیوارها ----------

  void _paintWalls(Canvas canvas, double cell) {
    if (walls.isEmpty) return;
    final fill = Paint()..color = palette.border.withOpacity(0.62);
    final edge = Paint()
      ..color = palette.border.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final w in walls) {
      final rect = Rect.fromLTWH(
        w.x * cell,
        w.y * cell,
        cell,
        cell,
      ).deflate(cell * 0.04);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(cell * 0.15),
      );
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, edge);
    }
  }

  // ---------- افکت عبور ----------

  void _paintWrapEffect(Canvas canvas, Size size, double cell) {
    final e = wrapEvent!;
    final pr = wrapProgress;
    final alpha = (1.0 - pr).clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final headColor = _segmentColor(0, snake.length);
    final dirVec = Offset(e.dir.x.toDouble(), e.dir.y.toDouble());

    final exitCenter = Offset(
      (e.from.x + 0.5) * cell,
      (e.from.y + 0.5) * cell,
    );
    final entryCenter = Offset(
      (e.to.x + 0.5) * cell,
      (e.to.y + 0.5) * cell,
    );

    final exitPortal = _portalPos(size, exitCenter, dirVec);
    final entryPortal = _portalPos(size, entryCenter, -dirVec);

    _drawPortalFlash(canvas, exitPortal, headColor, alpha, cell);
    _drawPortalFlash(canvas, entryPortal, headColor, alpha, cell);

    final ghostPos = exitCenter + dirVec * cell * (pr * 2.0);
    final ghostAlpha = (alpha * 1.1).clamp(0.0, 1.0);

    final trailStart = ghostPos - dirVec * cell * 1.4;
    _drawGlowingLine(
        canvas, trailStart, ghostPos, headColor, ghostAlpha * 0.7, cell);

    final ghostR = cell * 0.32 * (1 - pr * 0.6);
    canvas.drawCircle(
      ghostPos,
      ghostR * 2.0,
      Paint()
        ..color = headColor.withOpacity(ghostAlpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      ghostPos,
      ghostR,
      Paint()..color = headColor.withOpacity(ghostAlpha),
    );

    final entryTrailStart =
        entryCenter - dirVec * cell * ((1 - pr) * 2.0 + 0.5);
    _drawGlowingLine(
        canvas, entryTrailStart, entryCenter, headColor, alpha * 0.55, cell);
  }

  Offset _portalPos(Size size, Offset cellCenter, Offset dirVec) {
    if (dirVec.dx != 0) {
      final edgeX = dirVec.dx > 0 ? size.width : 0.0;
      return Offset(edgeX, cellCenter.dy);
    } else {
      final edgeY = dirVec.dy > 0 ? size.height : 0.0;
      return Offset(cellCenter.dx, edgeY);
    }
  }

  void _drawPortalFlash(
      Canvas canvas, Offset pos, Color color, double alpha, double cell) {
    canvas.drawCircle(
      pos,
      cell * 0.7,
      Paint()
        ..color = color.withOpacity(alpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      pos,
      cell * 0.3,
      Paint()..color = color.withOpacity(alpha * 0.85),
    );
    canvas.drawCircle(
      pos,
      cell * 0.12,
      Paint()..color = Colors.white.withOpacity(alpha * 0.95),
    );
  }

  void _drawGlowingLine(Canvas canvas, Offset a, Offset b, Color color,
      double alpha, double cell) {
    if (alpha <= 0) return;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color.withOpacity(alpha * 0.45)
        ..strokeWidth = cell * 0.9
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color.withOpacity(alpha)
        ..strokeWidth = cell * 0.32
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---------- غذا ----------

  void _paintFood(Canvas canvas, double cell) {
    final fc = Offset((food.x + 0.5) * cell, (food.y + 0.5) * cell);
    final color = _foodColor;

    // Pulse glow (همیشه)
    if (PerformanceService.glowEnabled) {
      final pulseR = cell * (0.55 + 0.15 * pulse);
      canvas.drawCircle(
        fc,
        pulseR,
        Paint()
          ..color = color.withOpacity(0.22 + 0.10 * pulse)
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, 6 * PerformanceService.blurMultiplier),
      );
    }

    // اگه پاوراپ فعاله → شکل پاوراپ
    if (powerUpType != null) {
      canvas.drawCircle(fc, cell * 0.3, Paint()..color = color);
      canvas.drawCircle(
        fc.translate(-cell * 0.08, -cell * 0.08),
        cell * 0.09,
        Paint()..color = Colors.white.withOpacity(0.85),
      );
      _paintPowerUpIcon(canvas, fc, cell, powerUpType!);
      return;
    }

    // وگرنه → شکل اسکین غذا
    _paintFoodSkin(canvas, fc, cell * 0.32, foodSkin);
  }

  void _paintFoodSkin(Canvas canvas, Offset c, double r, FoodSkin skin) {
    switch (skin) {
      case FoodSkin.basic:
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFFE53935));
        canvas.drawCircle(
          c.translate(-r * 0.3, -r * 0.3),
          r * 0.3,
          Paint()..color = Colors.white.withOpacity(0.7),
        );
        break;

      case FoodSkin.pizza:
        final path = Path()
          ..moveTo(c.dx - r * 0.9, c.dy - r * 0.4)
          ..lineTo(c.dx + r * 0.9, c.dy - r * 0.4)
          ..lineTo(c.dx, c.dy + r * 0.9)
          ..close();
        canvas.drawPath(path, Paint()..color = const Color(0xFFFFCC80));
        canvas.drawLine(
          Offset(c.dx - r * 0.9, c.dy - r * 0.4),
          Offset(c.dx + r * 0.9, c.dy - r * 0.4),
          Paint()
            ..color = const Color(0xFFD84315)
            ..strokeWidth = r * 0.25
            ..strokeCap = StrokeCap.round,
        );
        final pep = Paint()..color = const Color(0xFFC62828);
        canvas.drawCircle(Offset(c.dx - r * 0.3, c.dy), r * 0.15, pep);
        canvas.drawCircle(Offset(c.dx + r * 0.3, c.dy), r * 0.15, pep);
        canvas.drawCircle(Offset(c.dx, c.dy + r * 0.4), r * 0.13, pep);
        break;

      case FoodSkin.burger:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: c.translate(0, r * 0.4),
                width: r * 1.8,
                height: r * 0.45),
            Radius.circular(r * 0.2),
          ),
          Paint()..color = const Color(0xFFF5B960),
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: c.translate(0, -r * 0.05),
              width: r * 1.8,
              height: r * 0.3),
          Paint()..color = const Color(0xFF4E342E),
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: c.translate(0, -r * 0.35),
              width: r * 1.7,
              height: r * 0.15),
          Paint()..color = const Color(0xFF7CB342),
        );
        final topBun = Path()
          ..moveTo(c.dx - r * 0.85, c.dy - r * 0.5)
          ..quadraticBezierTo(
              c.dx, c.dy - r * 1.1, c.dx + r * 0.85, c.dy - r * 0.5)
          ..close();
        canvas.drawPath(topBun, Paint()..color = const Color(0xFFFFB74D));
        break;

      case FoodSkin.donut:
        canvas.drawCircle(c, r * 0.9, Paint()..color = const Color(0xFFEC407A));
        canvas.drawCircle(c, r * 0.35, Paint()..color = palette.bg);
        final sprinkle = Paint()..color = Colors.white;
        canvas.drawCircle(c.translate(-r * 0.5, -r * 0.4), r * 0.08, sprinkle);
        canvas.drawCircle(c.translate(r * 0.5, r * 0.3), r * 0.08, sprinkle);
        canvas.drawCircle(c.translate(-r * 0.3, r * 0.5), r * 0.08, sprinkle);
        break;

      case FoodSkin.grape:
        final grape = Paint()..color = const Color(0xFF7B1FA2);
        final positions = [
          Offset(c.dx, c.dy - r * 0.5),
          Offset(c.dx - r * 0.5, c.dy - r * 0.1),
          Offset(c.dx + r * 0.5, c.dy - r * 0.1),
          Offset(c.dx - r * 0.25, c.dy + r * 0.35),
          Offset(c.dx + r * 0.25, c.dy + r * 0.35),
          Offset(c.dx, c.dy + r * 0.75),
        ];
        for (final p in positions) {
          canvas.drawCircle(p, r * 0.3, grape);
        }
        break;

      case FoodSkin.star:
        final starPath = Path();
        for (var i = 0; i < 10; i++) {
          final angle = i * pi / 5 - pi / 2;
          final radius = i.isEven ? r * 0.9 : r * 0.4;
          final x = c.dx + cos(angle) * radius;
          final y = c.dy + sin(angle) * radius;
          if (i == 0) {
            starPath.moveTo(x, y);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD700));
        break;

      case FoodSkin.cherry:
        canvas.drawCircle(
          Offset(c.dx - r * 0.35, c.dy + r * 0.3),
          r * 0.4,
          Paint()..color = const Color(0xFFD32F2F),
        );
        canvas.drawCircle(
          Offset(c.dx + r * 0.35, c.dy + r * 0.3),
          r * 0.4,
          Paint()..color = const Color(0xFFD32F2F),
        );
        final stem = Paint()
          ..color = const Color(0xFF43A047)
          ..strokeWidth = r * 0.12
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(c.dx - r * 0.35, c.dy - r * 0.1),
          Offset(c.dx, c.dy - r * 0.9),
          stem,
        );
        canvas.drawLine(
          Offset(c.dx + r * 0.35, c.dy - r * 0.1),
          Offset(c.dx, c.dy - r * 0.9),
          stem,
        );
        break;

      case FoodSkin.watermelon:
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.95),
          pi,
          pi,
          true,
          Paint()..color = const Color(0xFF2E7D32),
        );
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.75),
          pi,
          pi,
          true,
          Paint()..color = const Color(0xFFE53935),
        );
        final seed = Paint()..color = const Color(0xFF1A1A1A);
        canvas.drawCircle(
            Offset(c.dx - r * 0.35, c.dy + r * 0.3), r * 0.08, seed);
        canvas.drawCircle(
            Offset(c.dx + r * 0.35, c.dy + r * 0.3), r * 0.08, seed);
        canvas.drawCircle(Offset(c.dx, c.dy + r * 0.5), r * 0.08, seed);
        break;

      case FoodSkin.goldenTrophyFood:
        // جام طلایی
        final cupPath = Path()
          ..moveTo(c.dx - r * 0.7, c.dy - r * 0.7)
          ..lineTo(c.dx + r * 0.7, c.dy - r * 0.7)
          ..lineTo(c.dx + r * 0.55, c.dy + r * 0.2)
          ..quadraticBezierTo(
              c.dx, c.dy + r * 0.7, c.dx - r * 0.55, c.dy + r * 0.2)
          ..close();
        canvas.drawPath(cupPath, Paint()..color = const Color(0xFFFFD700));
        // دسته‌ها
        final handlePaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.15;
        canvas.drawArc(
          Rect.fromCenter(
              center: c.translate(-r * 0.75, -r * 0.15),
              width: r * 0.4,
              height: r * 0.7),
          -pi / 2,
          pi,
          false,
          handlePaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
              center: c.translate(r * 0.75, -r * 0.15),
              width: r * 0.4,
              height: r * 0.7),
          -pi / 2,
          pi,
          false,
          handlePaint,
        );
        // پایه
        canvas.drawRect(
          Rect.fromCenter(
              center: c.translate(0, r * 0.75),
              width: r * 0.5,
              height: r * 0.2),
          Paint()..color = const Color(0xFFB8860B),
        );
        // ستاره روی جام
        _drawStar(canvas, c.translate(0, -r * 0.15), r * 0.2, Colors.white);
        break;
    }
  }

  void _paintPowerUpIcon(
      Canvas canvas, Offset center, double cell, PowerUpType type) {
    switch (type) {
      case PowerUpType.golden:
        _drawStar(canvas, center, cell * 0.16, Colors.white);
      case PowerUpType.shield:
        final paint = Paint()
          ..color = Colors.white
          ..strokeWidth = cell * 0.055
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          center.translate(-cell * 0.09, 0),
          center.translate(cell * 0.09, 0),
          paint,
        );
        canvas.drawLine(
          center.translate(0, -cell * 0.09),
          center.translate(0, cell * 0.09),
          paint,
        );
      case PowerUpType.slow:
        final s = cell * 0.09;
        final path = Path()
          ..moveTo(center.dx - s, center.dy - s)
          ..lineTo(center.dx + s, center.dy - s)
          ..lineTo(center.dx, center.dy)
          ..close()
          ..moveTo(center.dx - s, center.dy + s)
          ..lineTo(center.dx + s, center.dy + s)
          ..lineTo(center.dx, center.dy)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.white);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 - pi / 2;
      final r = i.isEven ? radius : radius * 0.4;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ---------- ✨ Trail effects ----------
  void _paintTrail(Canvas canvas, double cell) {
    // روی کیفیت پایین یا متوسط، خط ساده
    if (!PerformanceService.fancyTrailEnabled) {
      _paintSimpleTrail(canvas, cell);
      return;
    }

    switch (trail) {
      case TrailEffect.none:
        return;
      case TrailEffect.neon:
        _paintNeonTrail(canvas, cell);
        return;
      case TrailEffect.fire:
        _paintFireTrail(canvas, cell);
        return;
      case TrailEffect.stars:
        _paintStarsTrail(canvas, cell);
        return;
      case TrailEffect.smoke:
        _paintSmokeTrail(canvas, cell);
        return;
      case TrailEffect.rainbow:
        _paintRainbowTrail(canvas, cell);
        return;
      case TrailEffect.ice:
        _paintIceTrail(canvas, cell);
        return;
      case TrailEffect.electric:
        _paintElectricTrail(canvas, cell);
        return;
      case TrailEffect.blossom:
        _paintBlossomTrail(canvas, cell);
        return;
      case TrailEffect.phantom:
        _paintPhantomTrail(canvas, cell);
        return;
      case TrailEffect.water:
        _paintWaterTrail(canvas, cell);
        return;
      case TrailEffect.bronzeTrail:
        _paintBronzeTrail(canvas, cell);
        return;
      case TrailEffect.mythicTrail:
        _paintMythicTrail(canvas, cell);
        return;
    }
  }

  void _paintSimpleTrail(Canvas canvas, double cell) {
    if (snake.length < 2 || trail == TrailEffect.none) return;

    final path = Path();
    for (var i = 0; i < snake.length; i++) {
      final c = _interpCenter(i);
      final p = Offset(c.dx * cell, c.dy * cell);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    Color trailColor;
    switch (trail) {
      case TrailEffect.neon:
        trailColor = palette.accent;
        break;
      case TrailEffect.fire:
        trailColor = const Color(0xFFFF6600);
        break;
      case TrailEffect.stars:
        trailColor = const Color(0xFFFFD700);
        break;
      case TrailEffect.smoke:
        trailColor = Colors.grey;
        break;
      case TrailEffect.rainbow:
        trailColor = const Color(0xFFFF4081);
        break;
      case TrailEffect.ice:
        trailColor = const Color(0xFF4FC3F7);
        break;
      case TrailEffect.electric:
        trailColor = const Color(0xFFFFEB3B);
        break;
      case TrailEffect.blossom:
        trailColor = const Color(0xFFFF8FB3);
        break;
      case TrailEffect.phantom:
        trailColor = const Color(0xFF9C27B0);
        break;
      case TrailEffect.water:
        trailColor = const Color(0xFF00BCD4);
        break;
      case TrailEffect.bronzeTrail:
        trailColor = const Color(0xFFCD7F32);
        break;
      case TrailEffect.mythicTrail:
        trailColor = const Color(0xFFFF00E5);
        break;
      case TrailEffect.none:
        return;
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = trailColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // 💫 نئون — خط ضخیم درخشان
  void _paintNeonTrail(Canvas canvas, double cell) {
    if (snake.length < 2) return;
    final path = Path();
    for (var i = 0; i < snake.length; i++) {
      final c = _interpCenter(i);
      final p = Offset(c.dx * cell, c.dy * cell);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // لایه‌ی اول — هاله‌ی بزرگ
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.accent.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // لایه‌ی دوم — درخشش متوسط
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.accent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // لایه‌ی سوم — هسته‌ی سفید
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // 🔥 آتش — شعله‌های بزرگ و روشن
  void _paintFireTrail(Canvas canvas, double cell) {
    // 🚀 برای مار بلند، فاصله بیشتر
    final step = snake.length > 30 ? 2 : 1;
    for (var i = 1; i < snake.length; i += step) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final baseOpacity = (1 - t * 0.5).clamp(0.4, 1.0);

      // ۳ شعله‌ی مستقل که به بالا می‌رن
      for (var j = 0; j < 3; j++) {
        // هر شعله فاز مستقل داره
        final phase = timePhase * pi * 2 + i * 0.5 + j * 2.1;
        final rise = (timePhase * 1.5 + j * 0.33 + i * 0.07) % 1.0;

        // موقعیت — شعله‌ها به بالا و کمی چپ/راست حرکت می‌کنن
        final offsetX = sin(phase) * cell * 0.35;
        final offsetY = -rise * cell * 1.3;

        final cx = c.dx * cell + offsetX;
        final cy = c.dy * cell + offsetY;

        // شعله با بالا رفتن کوچیک و محو می‌شه
        final size = cell * (0.55 - rise * 0.4);
        final opacity = baseOpacity * (1 - rise * 0.75);

        if (opacity <= 0.05) continue;

        // لایه ۱ — هاله‌ی قرمز بیرونی
        canvas.drawCircle(
          Offset(cx, cy),
          size * 1.6,
          Paint()
            ..color = const Color(0xFFFF2200).withOpacity(opacity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );

        // لایه ۲ — بدنه‌ی نارنجی
        canvas.drawCircle(
          Offset(cx, cy),
          size,
          Paint()
            ..color = const Color(0xFFFF6600).withOpacity(opacity * 0.75)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );

        // لایه ۳ — نارنجی روشن داخلی
        canvas.drawCircle(
          Offset(cx, cy),
          size * 0.7,
          Paint()..color = const Color(0xFFFFAA00).withOpacity(opacity * 0.9),
        );

        // لایه ۴ — زرد روشن مرکزی
        canvas.drawCircle(
          Offset(cx, cy),
          size * 0.45,
          Paint()..color = const Color(0xFFFFDD00).withOpacity(opacity),
        );

        // لایه ۵ — هسته‌ی سفید داغ (فقط نزدیک مار)
        if (rise < 0.5) {
          canvas.drawCircle(
            Offset(cx, cy),
            size * 0.22,
            Paint()..color = Colors.white.withOpacity(opacity * (1 - rise * 2)),
          );
        }
      }
    }
  }

  // ⭐ ستاره — بزرگ و درخشان
  void _paintStarsTrail(Canvas canvas, double cell) {
    for (var i = 1; i < snake.length; i += 2) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final opacity = (1 - t * 0.5).clamp(0.4, 1.0);
      final seed = (i * 37 + 13) % 100;
      final ox = ((seed % 20) - 10) / 10.0 * cell * 0.7;
      final oy = (((seed * 7) % 20) - 10) / 10.0 * cell * 0.7;
      final twinkle = 0.7 + 0.3 * sin(timePhase * pi * 6 + i * 0.7);
      final center = Offset(c.dx * cell + ox, c.dy * cell + oy);
      final size = cell * 0.4 * twinkle;

      // هاله‌ی درخشان طلایی
      canvas.drawCircle(
        center,
        size * 1.8,
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(opacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // ستاره‌ی سفید بزرگ
      _drawStar(
        canvas,
        center,
        size,
        Colors.white.withOpacity(opacity),
      );
      // هسته‌ی زرد
      _drawStar(
        canvas,
        center,
        size * 0.5,
        const Color(0xFFFFEB3B).withOpacity(opacity),
      );
    }
  }

  // 💨 دود — توده‌های بزرگ و پف‌کرده
  void _paintSmokeTrail(Canvas canvas, double cell) {
    for (var i = 1; i < snake.length; i++) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final opacity = (1 - t) * 0.6;
      final phase = timePhase * pi * 2 + i * 0.5;
      final ox = sin(phase) * cell * 0.5;
      final oy = -cell * (t * 2.0);
      final baseSize = cell * (0.6 + t * 0.9);

      // هاله‌ی بزرگ
      canvas.drawCircle(
        Offset(c.dx * cell + ox, c.dy * cell + oy),
        baseSize * 1.4,
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // هسته‌ی دود
      canvas.drawCircle(
        Offset(c.dx * cell + ox, c.dy * cell + oy),
        baseSize,
        Paint()
          ..color = Colors.grey.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // پف سفید
      canvas.drawCircle(
        Offset(c.dx * cell + ox - cell * 0.1, c.dy * cell + oy - cell * 0.1),
        baseSize * 0.5,
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  // 🌈 رنگین‌کمان — خط ضخیم رنگارنگ
  void _paintRainbowTrail(Canvas canvas, double cell) {
    if (snake.length < 2) return;

    // ✅ یک path پیوسته
    final path = Path();
    final first = _interpCenter(0);
    path.moveTo(first.dx * cell, first.dy * cell);
    for (var i = 1; i < snake.length; i++) {
      final c = _interpCenter(i);
      path.lineTo(c.dx * cell, c.dy * cell);
    }

    // ✅ shader گرادیانت رنگین‌کمان با چرخش آروم
    final rect = Rect.fromLTWH(0, 0, cols * cell, rows * cell);
    final shader = LinearGradient(
      colors: const [
        Color(0xFFFF1744), // قرمز
        Color(0xFFFF9100), // نارنجی
        Color(0xFFFFEA00), // زرد
        Color(0xFF00E676), // سبز
        Color(0xFF00B0FF), // آبی
        Color(0xFF651FFF), // بنفش
        Color(0xFFF50057), // صورتی
        Color(0xFFFF1744), // برگشت به قرمز
      ],
      transform: GradientRotation(timePhase * pi * 2), // ← چرخش
    ).createShader(rect);

    // ✅ فقط ۲ draw برای کل مار
    // ۱. هاله‌ی درخشان (blur کاهش ۱۸ → ۱۲)
    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // ۲. خط میانی پررنگ
    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ❄️ یخ — کریستال‌های آبی چرخان
  void _paintIceTrail(Canvas canvas, double cell) {
    for (var i = 1; i < snake.length; i += 2) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final opacity = (1 - t * 0.5).clamp(0.5, 1.0);
      final seed = (i * 37 + 13) % 100;
      final ox = ((seed % 20) - 10) / 10.0 * cell * 0.45;
      final oy = (((seed * 7) % 20) - 10) / 10.0 * cell * 0.45;
      final center = Offset(c.dx * cell + ox, c.dy * cell + oy);
      final size = cell * 0.42;
      final rotation = timePhase * pi * 2 + i * 0.3;

      // هاله‌ی آبی نرم
      canvas.drawCircle(
        center,
        size * 2.0,
        Paint()
          ..color = const Color(0xFFB3E5FC).withOpacity(opacity * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // دانه‌ی برف — ۶ پر
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);

      final armPaint = Paint()
        ..color = const Color(0xFF81D4FA).withOpacity(opacity * 0.9)
        ..strokeWidth = cell * 0.06
        ..strokeCap = StrokeCap.round;
      final branchPaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..strokeWidth = cell * 0.035
        ..strokeCap = StrokeCap.round;

      for (var k = 0; k < 6; k++) {
        final angle = k * pi / 3;
        final endX = cos(angle) * size;
        final endY = sin(angle) * size;

        // پر اصلی
        canvas.drawLine(Offset.zero, Offset(endX, endY), armPaint);

        // شاخه‌های ریز روی هر پر
        final midX = cos(angle) * size * 0.55;
        final midY = sin(angle) * size * 0.55;
        const branchLen = 0.28;
        final b1 = angle + pi / 4;
        final b2 = angle - pi / 4;
        canvas.drawLine(
          Offset(midX, midY),
          Offset(midX + cos(b1) * size * branchLen,
              midY + sin(b1) * size * branchLen),
          branchPaint,
        );
        canvas.drawLine(
          Offset(midX, midY),
          Offset(midX + cos(b2) * size * branchLen,
              midY + sin(b2) * size * branchLen),
          branchPaint,
        );
      }
      canvas.restore();

      // درخشش مرکزی سفید
      canvas.drawCircle(
        center,
        cell * 0.1,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  // ⚡ الکتریکی — جرقه‌های زیگزاگ
  void _paintElectricTrail(Canvas canvas, double cell) {
    if (snake.length < 3) return;

    // فلیکر کل مسیر — بعضی فریم‌ها کلاً skip
    final flicker = sin(timePhase * pi * 8);
    if (flicker < -0.3) return;

    // ✅ یک path پیوسته برای کل مار (به‌جای N path جدا)
    final path = Path();
    final first = _interpCenter(0);
    path.moveTo(first.dx * cell, first.dy * cell);

    for (var i = 1; i < snake.length; i++) {
      final c1 = _interpCenter(i - 1);
      final c2 = _interpCenter(i);
      final p1 = Offset(c1.dx * cell, c1.dy * cell);
      final p2 = Offset(c2.dx * cell, c2.dy * cell);

      // ۲ نقطه‌ی زیگزاگ بین p1 و p2
      final perpX = -(p2.dy - p1.dy);
      final perpY = (p2.dx - p1.dx);
      final len = sqrt(perpX * perpX + perpY * perpY);

      for (var k = 1; k <= 2; k++) {
        final frac = k / 3;
        final mx = p1.dx + (p2.dx - p1.dx) * frac;
        final my = p1.dy + (p2.dy - p1.dy) * frac;
        final jitter = sin(timePhase * pi * 6 + i + k) * cell * 0.35;
        final nx = len > 0 ? perpX / len * jitter : 0.0;
        final ny = len > 0 ? perpY / len * jitter : 0.0;
        path.lineTo(mx + nx, my + ny);
      }
      path.lineTo(p2.dx, p2.dy);
    }

    // ✅ فقط ۲ draw برای کل مار
    // ۱. هاله‌ی زرد (blur کاهش ۱۰ → ۶)
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFEB3B).withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // ۲. هسته‌ی سفید
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // 🌸 شکوفه — گلبرگ‌های صورتی
  void _paintBlossomTrail(Canvas canvas, double cell) {
    // 🚀 برای مار بلند، فاصله بیشتر
    final step = snake.length > 30 ? 4 : 2;
    for (var i = 1; i < snake.length; i += step) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final baseOpacity = (1 - t * 0.6).clamp(0.35, 1.0);
      final phase = timePhase * pi * 2 + i * 0.4;

      // چرخش آروم + تنفس
      final rotation = phase * 0.3;
      final breath = 0.9 + 0.1 * sin(phase * 1.3);
      final size = cell * 0.55 * breath;

      // موقعیت با باد آروم
      final windX = sin(phase * 0.7 + i) * cell * 0.15;
      final windY = cos(phase * 0.5 + i * 0.8) * cell * 0.1 - cell * 0.2;
      final center = Offset(c.dx * cell + windX, c.dy * cell + windY);

      // ─────────────── گل کوچیک عقب (برای عمق) ───────────────
      if (i % 4 == 0) {
        _drawBlossomFlower(
          canvas,
          center.translate(cell * 0.3, -cell * 0.25),
          size * 0.55,
          rotation + 0.8,
          baseOpacity * 0.55,
          cell,
        );
      }

      // ─────────────── هاله‌ی صورتی نرم ───────────────
      canvas.drawCircle(
        center,
        size * 1.4,
        Paint()
          ..color = const Color(0xFFFFB6C1).withOpacity(baseOpacity * 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // ─────────────── گل اصلی ───────────────
      _drawBlossomFlower(
        canvas,
        center,
        size,
        rotation,
        baseOpacity,
        cell,
      );

      // ─────────────── برگ سبز کوچیک کنار ───────────────
      if (i % 3 == 0) {
        _drawBlossomLeaf(
          canvas,
          center.translate(-size * 1.1, size * 0.2),
          size * 0.45,
          rotation - 0.5,
          baseOpacity * 0.7,
          cell,
        );
      }
    }
  }

  /// رسم یک شکوفه‌ی کامل
  void _drawBlossomFlower(
    Canvas canvas,
    Offset center,
    double size,
    double rotation,
    double opacity,
    double cell,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // ۵ گلبرگ
    for (var j = 0; j < 5; j++) {
      final angle = j * pi * 2 / 5 - pi / 2;

      canvas.save();
      canvas.rotate(angle);

      // شکل گلبرگ — نوک‌تیز و کشیده (مثل شکوفه‌ی گیلاس)
      final petalPath = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          -size * 0.35,
          -size * 0.15,
          -size * 0.42,
          -size * 0.55,
          0,
          -size * 0.85,
        )
        ..cubicTo(
          size * 0.42,
          -size * 0.55,
          size * 0.35,
          -size * 0.15,
          0,
          0,
        )
        ..close();

      // گرادیانت زیبا از سفید مرکزی به صورتی عمیق
      canvas.drawPath(
        petalPath,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.8),
            radius: 1.2,
            colors: [
              const Color(0xFFFFF0F5).withOpacity(opacity),
              const Color(0xFFFFB6D0).withOpacity(opacity * 0.95),
              const Color(0xFFF06292).withOpacity(opacity * 0.85),
              const Color(0xFFC2185B).withOpacity(opacity * 0.7),
            ],
            stops: const [0.0, 0.4, 0.75, 1.0],
          ).createShader(Rect.fromLTWH(
            -size * 0.5,
            -size * 0.9,
            size,
            size * 0.9,
          )),
      );

      // رگبرگ مرکزی ظریف
      canvas.drawLine(
        Offset(0, -size * 0.05),
        Offset(0, -size * 0.7),
        Paint()
          ..color = const Color(0xFFFF80AB).withOpacity(opacity * 0.35)
          ..strokeWidth = cell * 0.012
          ..strokeCap = StrokeCap.round,
      );

      // رگبرگ‌های جانبی
      for (var k = 1; k <= 2; k++) {
        final yPos = -size * 0.25 * k;
        final xSpread = size * 0.08 * k;
        canvas.drawLine(
          Offset(0, yPos),
          Offset(xSpread, yPos - size * 0.08),
          Paint()
            ..color = const Color(0xFFFF80AB).withOpacity(opacity * 0.25)
            ..strokeWidth = cell * 0.008,
        );
        canvas.drawLine(
          Offset(0, yPos),
          Offset(-xSpread, yPos - size * 0.08),
          Paint()
            ..color = const Color(0xFFFF80AB).withOpacity(opacity * 0.25)
            ..strokeWidth = cell * 0.008,
        );
      }

      canvas.restore();
    }

    // ─────────────── پرچم‌های زرد (مرکز گل) ───────────────
    // دایره‌ی زرد پایه
    canvas.drawCircle(
      Offset.zero,
      size * 0.18,
      Paint()
        ..color = const Color(0xFFFFC107).withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // نقاط ریز زرد اطراف
    for (var k = 0; k < 8; k++) {
      final angle = k * pi / 4;
      final r = size * 0.28;
      canvas.drawCircle(
        Offset(cos(angle) * r, sin(angle) * r),
        size * 0.06,
        Paint()..color = const Color(0xFFFFEB3B).withOpacity(opacity * 0.95),
      );
    }
    // نقطه‌های نارنجی وسط
    for (var k = 0; k < 5; k++) {
      final angle = k * pi * 2 / 5 + 0.3;
      final r = size * 0.12;
      canvas.drawCircle(
        Offset(cos(angle) * r, sin(angle) * r),
        size * 0.05,
        Paint()..color = const Color(0xFFFF9800).withOpacity(opacity),
      );
    }
    // هسته‌ی سفید درخشان
    canvas.drawCircle(
      Offset.zero,
      size * 0.05,
      Paint()..color = Colors.white.withOpacity(opacity),
    );

    canvas.restore();
  }

  /// رسم برگ سبز کوچیک
  void _drawBlossomLeaf(
    Canvas canvas,
    Offset center,
    double size,
    double rotation,
    double opacity,
    double cell,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // شکل برگ
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.6, -size * 0.3, size * 1.2, 0)
      ..quadraticBezierTo(size * 0.6, size * 0.3, 0, 0)
      ..close();

    // برگ با گرادیانت سبز
    canvas.drawPath(
      leafPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF81C784).withOpacity(opacity * 0.9),
            const Color(0xFF2E7D32).withOpacity(opacity * 0.85),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, -size * 0.3, size * 1.2, size * 0.6)),
    );

    // رگبرگ برگ
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size * 1.1, 0),
      Paint()
        ..color = const Color(0xFF1B5E20).withOpacity(opacity * 0.6)
        ..strokeWidth = cell * 0.015,
    );

    canvas.restore();
  }

  // 💀 شبح — هاله‌های بنفش
  void _paintPhantomTrail(Canvas canvas, double cell) {
    for (var i = 2; i < snake.length; i += 2) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final opacity = (1 - t * 0.5).clamp(0.25, 0.9);
      final phase = timePhase * pi * 2 + i * 0.4;

      // شناوری آروم
      final ox = sin(phase) * cell * 0.45;
      final oy = cos(phase * 0.7) * cell * 0.35 - cell * 0.35;
      final center = Offset(c.dx * cell + ox, c.dy * cell + oy);

      // تنفس — اندازه بین ۰.۸ و ۱.۰
      final breath = 0.85 + 0.15 * sin(phase * 1.5);
      final size = cell * 0.42 * breath;

      // هاله‌ی بنفش بیرونی
      canvas.drawCircle(
        center,
        size * 2.5,
        Paint()
          ..color = const Color(0xFF7B1FA2).withOpacity(opacity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // بدن شبح — بالا گِرد، پایین موج‌دار
      final topY = center.dy - size * 0.9;
      final bottomY = center.dy + size * 1.1;
      final ghostPath = Path()
        ..moveTo(center.dx - size * 0.75, bottomY)
        ..quadraticBezierTo(center.dx - size * 0.95, center.dy - size * 0.2,
            center.dx - size * 0.65, topY)
        ..quadraticBezierTo(
            center.dx, topY - size * 0.65, center.dx + size * 0.65, topY)
        ..quadraticBezierTo(center.dx + size * 0.95, center.dy - size * 0.2,
            center.dx + size * 0.75, bottomY)
        // دامن موج‌دار
        ..quadraticBezierTo(center.dx + size * 0.35, bottomY + size * 0.35,
            center.dx + size * 0.15, bottomY)
        ..quadraticBezierTo(center.dx - size * 0.1, bottomY - size * 0.2,
            center.dx - size * 0.35, bottomY)
        ..quadraticBezierTo(center.dx - size * 0.55, bottomY + size * 0.3,
            center.dx - size * 0.75, bottomY)
        ..close();

      // بدن با گرادیانت بنفش
      canvas.drawPath(
        ghostPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE1BEE7).withOpacity(opacity * 0.85),
              const Color(0xFF9C27B0).withOpacity(opacity * 0.55),
              const Color(0xFF4A148C).withOpacity(opacity * 0.35),
            ],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: size * 2,
              height: size * 2.4,
            ),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // لبه‌ی روشن بالای بدن
      canvas.drawPath(
        ghostPath,
        Paint()
          ..color = const Color(0xFFCE93D8).withOpacity(opacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.04
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // چشم‌های درخشان
      final eyeY = center.dy - size * 0.35;
      final eyeOffset = size * 0.32;
      final eyeGlowPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final pupilPaint = Paint()
        ..color = const Color(0xFF4A148C).withOpacity(opacity);

      // هاله‌ی چشم
      canvas.drawCircle(
        Offset(center.dx - eyeOffset, eyeY),
        size * 0.2,
        Paint()
          ..color = const Color(0xFFE1BEE7).withOpacity(opacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffset, eyeY),
        size * 0.2,
        Paint()
          ..color = const Color(0xFFE1BEE7).withOpacity(opacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // سفیدی چشم
      canvas.drawCircle(
        Offset(center.dx - eyeOffset, eyeY),
        size * 0.13,
        eyeGlowPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffset, eyeY),
        size * 0.13,
        eyeGlowPaint,
      );
      // مردمک
      canvas.drawCircle(
        Offset(center.dx - eyeOffset, eyeY),
        size * 0.06,
        pupilPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffset, eyeY),
        size * 0.06,
        pupilPaint,
      );
    }
  }

  // 🌊 آب — موج‌های فیروزه‌ای
  void _paintWaterTrail(Canvas canvas, double cell) {
    for (var i = 1; i < snake.length; i++) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final opacity = (1 - t * 0.6).clamp(0.3, 1.0);
      final phase = timePhase * pi * 2 + i * 0.5;

      // ۲ موج که از هم فاصله می‌گیرن
      for (var j = 0; j < 2; j++) {
        final wavePhase = phase + j * pi;
        final wave = sin(wavePhase) * 0.5 + 0.5;
        final radius = cell * (0.3 + wave * 0.4);
        final ox = sin(wavePhase) * cell * 0.35;
        final oy = -cell * 0.15 + cos(wavePhase * 1.3) * cell * 0.1;
        final center = Offset(c.dx * cell + ox, c.dy * cell + oy);

        // هاله‌ی آبی
        canvas.drawCircle(
          center,
          radius * 1.5,
          Paint()
            ..color = const Color(0xFF00BCD4).withOpacity(opacity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        // حلقه‌ی موج
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = const Color(0xFF4DD0E1).withOpacity(opacity * 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.15,
        );
        // قطره‌ی مرکزی
        canvas.drawCircle(
          center,
          cell * 0.08,
          Paint()..color = Colors.white.withOpacity(opacity * 0.9),
        );
      }
    }
  }

  // ---------- 🎨 Board Patterns ----------

  void _paintPattern(Canvas canvas, Size size, double cell) {
    final a = patternIntensity.multiplier;

    // پترن‌های پیچیده فقط روی کیفیت بالا
    final complex = PerformanceService.complexPatternsEnabled;
    if (!complex) {
      switch (pattern) {
        case BoardPattern.checkerboard:
          _paintCheckerboard(canvas, size, cell, a);
          return;
        case BoardPattern.gridPlus:
          _paintGridPlus(canvas, size, cell, a);
          return;
        default:
          return;
      }
    }

    switch (pattern) {
      case BoardPattern.none:
        return;
      case BoardPattern.galaxy:
        _paintGalaxy(canvas, size, a);
        return;
      case BoardPattern.spiral:
        _paintSpiral(canvas, size, a);
        return;
      case BoardPattern.stars:
        _paintStars(canvas, size, a);
        return;
      case BoardPattern.checkerboard:
        _paintCheckerboard(canvas, size, cell, a);
        return;
      case BoardPattern.gridPlus:
        _paintGridPlus(canvas, size, cell, a);
        return;
      case BoardPattern.waves:
        _paintWaves(canvas, size, a);
        return;
      case BoardPattern.crystal:
        _paintCrystal(canvas, size, a);
        return;
      case BoardPattern.petals:
        _paintPetals(canvas, size, a);
        return;
      case BoardPattern.legendPattern:
        _paintLegendPattern(canvas, size, a);
        return;
    }
  }

  // 🌌 کهکشان — ستاره‌های چشمک‌زن
  void _paintGalaxy(Canvas canvas, Size size, double a) {
    final baseColor = palette.accent;
    // مِه پس‌زمینه
    for (var i = 0; i < 3; i++) {
      final cx = size.width * (0.2 + i * 0.3);
      final cy = size.height * (0.3 + (i % 2) * 0.4);
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.35,
        Paint()
          ..color = baseColor.withOpacity(0.03 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    // ستاره‌ها — موقعیت ثابت با seed
    for (var i = 0; i < 40; i++) {
      final seed = i * 37 + 13;
      final x = ((seed * 7) % 100) / 100.0 * size.width;
      final y = ((seed * 13) % 100) / 100.0 * size.height;
      final twinkle = 0.5 + 0.5 * sin(timePhase * pi * 2 + i * 0.7);
      final r = (1.0 + (seed % 3)) * (0.8 + 0.6 * twinkle);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withOpacity((0.4 + 0.4 * twinkle) * 0.15 * a),
      );
    }
  }

  // 🌀 مارپیچ
  void _paintSpiral(Canvas canvas, Size size, double a) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = palette.accent.withOpacity(0.08 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var arm = 0; arm < 3; arm++) {
      final startAngle = arm * pi * 2 / 3;
      final path = Path();
      for (var i = 0; i < 200; i++) {
        final t = i / 200.0;
        final angle = startAngle + t * pi * 6;
        final r = t * size.width * 0.55;
        final x = center.dx + cos(angle) * r;
        final y = center.dy + sin(angle) * r;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  // ⭐ ستاره‌ای
  void _paintStars(Canvas canvas, Size size, double a) {
    for (var i = 0; i < 24; i++) {
      final seed = i * 53 + 7;
      final x = ((seed * 7) % 100) / 100.0 * size.width;
      final y = ((seed * 13) % 100) / 100.0 * size.height;
      final r = 2.5 + (seed % 4) * 1.2;
      _drawStar(
        canvas,
        Offset(x, y),
        r,
        palette.accent.withOpacity(0.10 * a),
      );
    }
  }

  // ▦ شطرنجی
  void _paintCheckerboard(Canvas canvas, Size size, double cell, double a) {
    final step = cell * 2;
    final paint = Paint()..color = palette.accent.withOpacity(0.04 * a);
    for (var y = 0; y * step < size.height; y++) {
      for (var x = 0; x * step < size.width; x++) {
        if ((x + y) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x * step, y * step, step, step),
            paint,
          );
        }
      }
    }
  }

  // 🔷 شبکه‌ای
  void _paintGridPlus(Canvas canvas, Size size, double cell, double a) {
    final linePaint = Paint()
      ..color = palette.accent.withOpacity(0.06 * a)
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = palette.accent.withOpacity(0.14 * a);
    final step = cell * 2;
    // خطوط عمودی
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    // خطوط افقی
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    // نقطه‌های تقاطع
    for (var x = step; x < size.width; x += step) {
      for (var y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  // 🌊 موج — با حرکت آروم
  void _paintWaves(Canvas canvas, Size size, double a) {
    final paint = Paint()
      ..color = palette.accent.withOpacity(0.07 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final waves = 5;
    for (var w = 0; w < waves; w++) {
      final baseY = size.height * (w + 1) / (waves + 1);
      final phase = timePhase * pi * 2 + w * 0.8;
      final path = Path();
      for (var i = 0; i <= 60; i++) {
        final t = i / 60.0;
        final x = t * size.width;
        final y = baseY + sin(t * pi * 4 + phase) * size.height * 0.04;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  // 💠 کریستالی — شش‌ضلعی
  void _paintCrystal(Canvas canvas, Size size, double a) {
    final paint = Paint()
      ..color = palette.accent.withOpacity(0.06 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = size.width * 0.08;
    final step = r * 1.8;
    for (var y = 0.0; y < size.height + step; y += step * 0.87) {
      for (var x = 0.0; x < size.width + step; x += step) {
        final offsetX = ((y / (step * 0.87)).round() % 2 == 0) ? 0.0 : step / 2;
        final cx = x + offsetX;
        final path = Path();
        for (var k = 0; k < 6; k++) {
          final angle = k * pi / 3 - pi / 6;
          final px = cx + cos(angle) * r;
          final py = y + sin(angle) * r;
          if (k == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  // 🌸 گلبرگ
  void _paintPetals(Canvas canvas, Size size, double a) {
    for (var i = 0; i < 20; i++) {
      final seed = i * 41 + 11;
      final x = ((seed * 7) % 100) / 100.0 * size.width;
      final y = ((seed * 11) % 100) / 100.0 * size.height;
      final rotation = (seed * 0.3) % (pi * 2);
      final petalR = 3.0 + (seed % 3) * 1.5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: petalR * 2, height: petalR),
        Paint()..color = palette.accent.withOpacity(0.09 * a),
      );
      canvas.restore();
    }
  }

  // ---------- 🥉 Bronze Trail (Stage 3) ----------
  void _paintBronzeTrail(Canvas canvas, double cell) {
    if (snake.length < 2) return;
    final path = Path();
    for (var i = 0; i < snake.length; i++) {
      final c = _interpCenter(i);
      final p = Offset(c.dx * cell, c.dy * cell);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // هاله‌ی برنزی
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCD7F32).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // هسته‌ی برنزی روشن
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8A860).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // جرقه‌های برنزی پراکنده
    for (var i = 1; i < snake.length; i += 3) {
      final c = _interpCenter(i);
      final seed = (i * 37) % 100;
      final ox = ((seed % 20) - 10) / 10.0 * cell * 0.6;
      final oy = (((seed * 7) % 20) - 10) / 10.0 * cell * 0.6;
      canvas.drawCircle(
        Offset(c.dx * cell + ox, c.dy * cell + oy),
        cell * 0.08,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.7),
      );
    }
  }

  // ---------- 🟣 Mythic Trail (Stage 3) ----------
  void _paintMythicTrail(Canvas canvas, double cell) {
    if (snake.length < 2) return;
    final path = Path();
    for (var i = 0; i < snake.length; i++) {
      final c = _interpCenter(i);
      final p = Offset(c.dx * cell, c.dy * cell);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // هاله‌ی بنفش بیرونی
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF00E5).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // هسته‌ی سرخ
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF00E5).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // هسته‌ی سفید نئونی
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // جرقه‌های ستاره‌ای
    for (var i = 1; i < snake.length; i += 2) {
      final c = _interpCenter(i);
      final t = i / snake.length;
      final opacity = (1 - t * 0.5).clamp(0.4, 1.0);
      final twinkle = 0.7 + 0.3 * sin(timePhase * pi * 4 + i * 0.6);
      final seed = (i * 53 + 17) % 100;
      final ox = ((seed % 20) - 10) / 10.0 * cell * 0.5;
      final oy = (((seed * 11) % 20) - 10) / 10.0 * cell * 0.5;
      _drawStar(
        canvas,
        Offset(c.dx * cell + ox, c.dy * cell + oy),
        cell * 0.15 * twinkle,
        const Color(0xFFFF00E5).withOpacity(opacity),
      );
    }
  }

  // ---------- 🔥 Legend Pattern (Stage 3) ----------
  void _paintLegendPattern(Canvas canvas, Size size, double a) {
    const baseColor = Color(0xFFFF6B35);
    // هاله‌های نارنجی
    for (var i = 0; i < 3; i++) {
      final cx = size.width * (0.2 + i * 0.3);
      final cy = size.height * (0.4 + (i % 2) * 0.3);
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.3,
        Paint()
          ..color = baseColor.withOpacity(0.04 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    // جرقه‌های طلایی پراکنده
    for (var i = 0; i < 30; i++) {
      final seed = i * 41 + 23;
      final x = ((seed * 7) % 100) / 100.0 * size.width;
      final y = ((seed * 11) % 100) / 100.0 * size.height;
      final twinkle = 0.5 + 0.5 * sin(timePhase * pi * 2 + i * 0.7);
      final r = (1.5 + (seed % 3)) * (0.8 + 0.4 * twinkle);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = const Color(0xFFFFD700)
              .withOpacity((0.3 + 0.4 * twinkle) * 0.15 * a),
      );
    }
    // خطوط موج آتشین
    final linePaint = Paint()
      ..color = baseColor.withOpacity(0.08 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var w = 0; w < 3; w++) {
      final baseY = size.height * (w + 1) / 4;
      final phase = timePhase * pi * 2 + w * 1.2;
      final path = Path();
      for (var i = 0; i <= 30; i++) {
        final t = i / 30.0;
        final x = t * size.width;
        final y = baseY + sin(t * pi * 6 + phase) * size.height * 0.03;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
