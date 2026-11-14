// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../models/intro_animation.dart';

class IntroOverlay extends StatelessWidget {
  final IntroAnimation type;
  final double progress;
  final GamePalette palette;

  const IntroOverlay({
    super.key,
    required this.type,
    required this.progress,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _IntroPainter(
          type: type,
          progress: progress,
          palette: palette,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _IntroPainter extends CustomPainter {
  final IntroAnimation type;
  final double progress;
  final GamePalette palette;

  _IntroPainter({
    required this.type,
    required this.progress,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final overlayAlpha = (1 - progress * 1.3).clamp(0.0, 0.85);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = palette.bg.withOpacity(overlayAlpha),
    );

    switch (type) {
      case IntroAnimation.rocket:
        _paintRocket(canvas, size);
        break;
      case IntroAnimation.portal:
        _paintPortal(canvas, size);
        break;
      case IntroAnimation.lightning:
        _paintLightning(canvas, size);
        break;
      case IntroAnimation.sparkle:
        _paintSparkle(canvas, size);
        break;
      case IntroAnimation.comet:
        _paintComet(canvas, size);
        break;
      case IntroAnimation.tornado:
        _paintTornado(canvas, size);
        break;
      case IntroAnimation.explosion:
        _paintExplosion(canvas, size);
        break;
      case IntroAnimation.crystal:
        _paintCrystal(canvas, size);
        break;
      case IntroAnimation.none:
        break;
      case IntroAnimation.championIntro:
        _paintChampionIntro(canvas, size);
        break;
    }
  }

  // 🚀 موشک
  void _paintRocket(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    double flightT;
    double alpha;
    double scale;

    if (progress < 0.6) {
      flightT = Curves.easeOutCubic.transform(progress / 0.6);
      alpha = 1.0;
      scale = 1.0;
    } else if (progress < 0.85) {
      flightT = 1.0;
      alpha = 1.0;
      scale = 1.0 - (progress - 0.6) * 1.5;
    } else {
      flightT = 1.0;
      alpha = (1 - progress) * 6.5;
      scale = 0.6;
    }

    final startY = -size.height * 0.15;
    final endY = center.dy;
    final rocketY = startY + (endY - startY) * flightT;
    final rocketX = center.dx;

    if (alpha > 0.1) {
      for (var i = 0; i < 12; i++) {
        final t = i / 12.0;
        final trailY = rocketY + 40 + t * 180 * flightT;
        final trailX = rocketX + sin(t * pi * 4 + progress * 10) * 15;
        final trailAlpha = alpha * (1 - t) * 0.55;
        final trailRadius = (1 - t) * 22;

        canvas.drawCircle(
          Offset(trailX, trailY),
          trailRadius,
          Paint()
            ..color = Color.lerp(Colors.orange, Colors.grey, t)!
                .withOpacity(trailAlpha),
        );
      }
    }

    if (alpha < 0.05) return;

    final s = 30 * scale;
    final bodyPaint = Paint()..color = Colors.white.withOpacity(alpha);

    // بدنه
    final bodyPath = Path()
      ..moveTo(rocketX, rocketY - s * 1.2)
      ..lineTo(rocketX - s * 0.5, rocketY + s * 0.5)
      ..lineTo(rocketX + s * 0.5, rocketY + s * 0.5)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // شعله
    final flamePath = Path()
      ..moveTo(rocketX - s * 0.35, rocketY + s * 0.5)
      ..lineTo(rocketX, rocketY + s * 1.4)
      ..lineTo(rocketX + s * 0.35, rocketY + s * 0.5);
    canvas.drawPath(
        flamePath, Paint()..color = Colors.orange.withOpacity(alpha));

    // شعله‌ی مرکزی
    final centerFlamePath = Path()
      ..moveTo(rocketX - s * 0.2, rocketY + s * 0.5)
      ..lineTo(rocketX, rocketY + s * 1.1)
      ..lineTo(rocketX + s * 0.2, rocketY + s * 0.5);
    canvas.drawPath(
        centerFlamePath, Paint()..color = Colors.yellow.withOpacity(alpha));

    // پنجره
    canvas.drawCircle(
      Offset(rocketX, rocketY),
      s * 0.25,
      Paint()..color = palette.accent.withOpacity(alpha),
    );
  }

  // 🔮 پورتال
  void _paintPortal(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    double portalT;
    double alpha;

    if (progress < 0.5) {
      portalT = Curves.easeOutCubic.transform(progress / 0.5);
      alpha = 1.0;
    } else if (progress < 0.85) {
      portalT = 1.0;
      alpha = 1.0;
    } else {
      portalT = 1.0;
      alpha = (1 - progress) * 6.5;
    }

    final currentRadius = size.width * 0.35 * portalT;
    final rotation = progress * pi * 6;

    if (alpha < 0.05) return;

    // هاله‌ی بیرونی
    canvas.drawCircle(
      center,
      currentRadius * 1.2,
      Paint()
        ..color = palette.accent.withOpacity(alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // حلقه‌ی نقطه‌چین
    final ringPaint = Paint()
      ..color = palette.accent.withOpacity(alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentRadius * 0.15
      ..strokeCap = StrokeCap.round;

    const segments = 8;
    for (var i = 0; i < segments; i++) {
      final angle = i * 2 * pi / segments;
      final nextAngle = (i + 1) * 2 * pi / segments;
      final gap = (nextAngle - angle) * 0.3;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: currentRadius * 0.9),
        angle + gap,
        (nextAngle - angle) - gap * 2,
        false,
        ringPaint,
      );
    }

    // هسته‌ی سفید
    canvas.drawCircle(
      Offset.zero,
      currentRadius * 0.6,
      Paint()
        ..color = Colors.white.withOpacity(alpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.drawCircle(
      Offset.zero,
      currentRadius * 0.3,
      Paint()..color = Colors.white.withOpacity(alpha),
    );

    canvas.restore();
  }

  // ⚡ رعد
  void _paintLightning(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // فلاش‌های کوتاه
    double flashAlpha = 0;
    if (progress < 0.2) {
      flashAlpha = (1 - progress / 0.2) * 0.7;
    } else if (progress > 0.3 && progress < 0.4) {
      flashAlpha = (1 - (progress - 0.3) / 0.1) * 0.5;
    } else if (progress > 0.5 && progress < 0.6) {
      flashAlpha = (1 - (progress - 0.5) / 0.1) * 0.3;
    }
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withOpacity(flashAlpha),
      );
    }

    double boltAlpha = 1.0;
    if (progress > 0.6) {
      boltAlpha = (1 - (progress - 0.6) / 0.4).clamp(0.0, 1.0);
    }
    if (boltAlpha < 0.05) return;

    // مسیر صاعقه
    final boltPath = Path()
      ..moveTo(center.dx - 20, 0)
      ..lineTo(center.dx - 30, center.dy * 0.4)
      ..lineTo(center.dx + 15, center.dy * 0.4)
      ..lineTo(center.dx - 25, center.dy * 0.7)
      ..lineTo(center.dx + 25, center.dy * 0.7)
      ..lineTo(center.dx + 20, center.dy + 80);

    canvas.drawPath(
      boltPath,
      Paint()
        ..color = Colors.yellow.withOpacity(boltAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.drawPath(
      boltPath,
      Paint()
        ..color = Colors.white.withOpacity(boltAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ✨ جرقه
  void _paintSparkle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const starCount = 20;

    for (var i = 0; i < starCount; i++) {
      final seed = i * 73 + 17;
      final angle = (seed * 2.1) % (2 * pi);
      final radius = size.width * (0.15 + (seed % 100) / 100 * 0.35);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      final starDelay = (seed % 100) / 100 * 0.5;
      final starProgress =
          ((progress - starDelay) / (1 - starDelay)).clamp(0.0, 1.0);

      if (starProgress <= 0) continue;

      double alpha;
      double starSize;

      if (starProgress < 0.3) {
        alpha = starProgress / 0.3;
        starSize = starProgress / 0.3;
      } else if (starProgress < 0.7) {
        alpha = 1.0;
        starSize = 1.0;
      } else {
        final t = (starProgress - 0.7) / 0.3;
        alpha = 1.0 - t;
        starSize = 1.0 - t * 0.5;
      }

      final s = 8 * starSize;
      final color = i % 3 == 0
          ? palette.accent
          : (i % 3 == 1 ? palette.food : Colors.white);

      _drawStar(canvas, Offset(x, y), s, color.withOpacity(alpha));
    }

    // درخشش مرکزی
    final centerGlow = (progress * 1.2).clamp(0.0, 1.0);
    if (centerGlow > 0) {
      canvas.drawCircle(
        center,
        30 * centerGlow,
        Paint()
          ..color = palette.accent.withOpacity(centerGlow * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      canvas.drawCircle(
        center,
        15 * centerGlow,
        Paint()..color = Colors.white.withOpacity(centerGlow * 0.7),
      );
    }
  }

  // 💫 شهاب‌سنگ
  void _paintComet(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    double flightT;
    double alpha;

    if (progress < 0.85) {
      flightT = Curves.easeInCubic.transform(progress / 0.85);
      alpha = 1.0;
    } else if (progress < 0.85) {
      flightT = 1.0;
      alpha = 1.0;
    } else {
      flightT = 1.0;
      alpha = (1 - progress) * 6.5;
    }

    if (alpha < 0.05) return;

    // شروع از بالا-راست (خارج از صفحه)
    final startX = size.width * 1.3;
    final startY = -size.height * 0.3;
    final currentX = startX + (center.dx - startX) * flightT;
    final currentY = startY + (center.dy - startY) * flightT;
    final current = Offset(currentX, currentY);

    // دنباله‌ی درخشان
    final dirX = center.dx - startX;
    final dirY = center.dy - startY;
    final dirLen = sqrt(dirX * dirX + dirY * dirY);
    final ux = dirX / dirLen;
    final uy = dirY / dirLen;

    for (var i = 0; i < 15; i++) {
      final t = i / 15.0;
      final trailDist = t * 180;
      final trailX = currentX - ux * trailDist;
      final trailY = currentY - uy * trailDist;
      final trailAlpha = alpha * (1 - t) * 0.7;
      final trailRadius = (1 - t) * 18;

      final trailColor = Color.lerp(
        Colors.white,
        palette.accent,
        t,
      )!;

      canvas.drawCircle(
        Offset(trailX, trailY),
        trailRadius,
        Paint()
          ..color = trailColor.withOpacity(trailAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // هاله‌ی بزرگ دور شهاب
    canvas.drawCircle(
      current,
      45,
      Paint()
        ..color = palette.accent.withOpacity(alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // هسته‌ی سفید
    canvas.drawCircle(
      current,
      18,
      Paint()..color = Colors.white.withOpacity(alpha),
    );
    canvas.drawCircle(
      current,
      10,
      Paint()..color = palette.accent.withOpacity(alpha),
    );
  }

  // 🌀 گردباد
  void _paintTornado(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    double alpha;
    if (progress < 0.6) {
      alpha = Curves.easeOutCubic.transform(progress / 0.6);
    } else if (progress < 0.85) {
      alpha = 1.0;
    } else {
      alpha = (1 - progress) * 6.5;
    }

    if (alpha < 0.05) return;

    // ۵ حلقه‌ی چرخان که کوچیک می‌شن
    for (var ring = 0; ring < 5; ring++) {
      final ringT = ring / 5.0;
      final ringDelay = ring * 0.12;
      final ringProgress =
          ((progress - ringDelay) / (1 - ringDelay)).clamp(0.0, 1.0);

      if (ringProgress <= 0) continue;

      final startRadius = size.width * 0.5;
      final endRadius = size.width * 0.15;
      final radius = startRadius + (endRadius - startRadius) * ringProgress;

      final rotation = progress * pi * 8 + ring * pi / 3;

      // ۶ ذره روی هر حلقه
      const pointsPerRing = 6;
      for (var i = 0; i < pointsPerRing; i++) {
        final angle = rotation + i * 2 * pi / pointsPerRing + ringT * pi;
        final x = center.dx + cos(angle) * radius;
        final y = center.dy + sin(angle) * radius * 0.7;

        final pointAlpha = alpha * (1 - ringT * 0.5) * 0.85;
        final pointRadius = 6 + (1 - ringT) * 8;

        final pointColor = Color.lerp(palette.accent, Colors.white, ringT)!;

        canvas.drawCircle(
          Offset(x, y),
          pointRadius * 2,
          Paint()
            ..color = pointColor.withOpacity(pointAlpha * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(
          Offset(x, y),
          pointRadius,
          Paint()..color = pointColor.withOpacity(pointAlpha),
        );
      }
    }

    // هسته‌ی مرکزی
    if (progress > 0.5) {
      final coreT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        30 * coreT,
        Paint()
          ..color = palette.accent.withOpacity(alpha * 0.5 * coreT)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
      canvas.drawCircle(
        center,
        15 * coreT,
        Paint()..color = Colors.white.withOpacity(alpha * coreT),
      );
    }
  }

  // 💥 انفجار
  void _paintExplosion(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // فلاش اولیه
    if (progress < 0.15) {
      final flash = (1 - progress / 0.15) * 0.85;
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withOpacity(flash),
      );
    }

    // موج شوک (چند دایره که بزرگ می‌شن)
    if (progress > 0.05) {
      for (var wave = 0; wave < 3; wave++) {
        final waveDelay = wave * 0.15;
        final waveT = ((progress - 0.05 - waveDelay) / 0.5).clamp(0.0, 1.0);

        if (waveT <= 0 || waveT >= 1) continue;

        final radius = size.width * 0.6 * waveT;
        final waveAlpha = (1 - waveT) * 0.7;

        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = palette.accent.withOpacity(waveAlpha * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 + waveT * 8,
        );
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = palette.accent.withOpacity(waveAlpha * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
        );
      }
    }

    // ذرات پرتاب‌شونده
    if (progress > 0.1 && progress < 0.9) {
      final particleT = (progress - 0.1) / 0.8;
      final particleAlpha = 1.0 - particleT;

      for (var i = 0; i < 16; i++) {
        final seed = i * 73 + 17;
        final angle = (seed * 0.39) % (2 * pi);
        final speed = 0.4 + (seed % 100) / 100 * 0.6;
        final dist = size.width * 0.5 * particleT * speed;

        final x = center.dx + cos(angle) * dist;
        final y = center.dy + sin(angle) * dist;
        final particleSize = (1 - particleT) * 8;

        final color = i % 2 == 0
            ? palette.accent
            : (i % 3 == 0 ? Colors.orange : Colors.white);

        canvas.drawCircle(
          Offset(x, y),
          particleSize,
          Paint()..color = color.withOpacity(particleAlpha),
        );
      }
    }

    // هسته‌ی مرکزی نهایی
    if (progress > 0.4) {
      final coreT = ((progress - 0.4) / 0.3).clamp(0.0, 1.0);
      final coreAlpha = progress > 0.7 ? (1 - (progress - 0.7) / 0.3) : 1.0;
      canvas.drawCircle(
        center,
        25 * coreT,
        Paint()
          ..color = palette.accent.withOpacity(coreAlpha * 0.5 * coreT)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        center,
        12 * coreT,
        Paint()..color = Colors.white.withOpacity(coreAlpha * coreT),
      );
    }
  }

  // 🧊 کریستال
  void _paintCrystal(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    double alpha;
    if (progress < 0.6) {
      alpha = Curves.easeOutCubic.transform(progress / 0.6);
    } else if (progress < 0.85) {
      alpha = 1.0;
    } else {
      alpha = (1 - progress) * 6.5;
    }

    if (alpha < 0.05) return;

    // شش کریستال شش‌ضلعی که از مرکز به بیرون رشد می‌کنن
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + progress * pi * 0.5;
      final crystalDelay = i * 0.05;
      final crystalT = ((progress - crystalDelay) / 0.5).clamp(0.0, 1.0);

      if (crystalT <= 0) continue;

      final innerRadius = size.width * 0.05 * crystalT;
      final outerRadius = size.width * 0.35 * crystalT;

      final innerX = center.dx + cos(angle) * innerRadius;
      final innerY = center.dy + sin(angle) * innerRadius;
      final outerX = center.dx + cos(angle) * outerRadius;
      final outerY = center.dy + sin(angle) * outerRadius;

      // بدنه‌ی کریستال — الماس کشیده
      final perpX = cos(angle + pi / 2);
      final perpY = sin(angle + pi / 2);
      final width = size.width * 0.06 * crystalT;

      final crystalPath = Path()
        ..moveTo(innerX + perpX * width, innerY + perpY * width)
        ..lineTo(outerX, outerY)
        ..lineTo(innerX - perpX * width, innerY - perpY * width)
        ..close();

      // هاله‌ی آبی
      canvas.drawPath(
        crystalPath,
        Paint()
          ..color = const Color(0xFF81D4FA).withOpacity(alpha * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // بدنه‌ی کریستال
      canvas.drawPath(
        crystalPath,
        Paint()..color = const Color(0xFFB3E5FC).withOpacity(alpha * 0.9),
      );
      // لبه‌ی روشن
      canvas.drawPath(
        crystalPath,
        Paint()
          ..color = Colors.white.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // هسته‌ی مرکزی سفید
    final coreT = (progress / 0.4).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      35 * coreT,
      Paint()
        ..color = const Color(0xFF81D4FA).withOpacity(alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      center,
      18 * coreT,
      Paint()..color = Colors.white.withOpacity(alpha),
    );

    // جرقه‌های یخی
    if (progress > 0.5) {
      for (var i = 0; i < 8; i++) {
        final seed = i * 41 + 13;
        final angle = (seed * 0.5) % (2 * pi);
        final dist = size.width * 0.4 * progress;
        final sparkleAlpha =
            (1 - (progress - 0.5) / 0.5).clamp(0.0, 1.0) * alpha;

        canvas.drawCircle(
          Offset(
            center.dx + cos(angle) * dist,
            center.dy + sin(angle) * dist,
          ),
          3,
          Paint()..color = Colors.white.withOpacity(sparkleAlpha),
        );
      }
    }
  }

  // 🏆 Champion Intro — golden burst + expanding rings + rising particles
  void _paintChampionIntro(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide * 0.5;

    const gold = Color(0xFFFFD700);
    const goldDeep = Color(0xFFFFB300);
    const white = Color(0xFFFFFFFF);

    // ─── Phase 1 (progress 0.0–0.45): bright central burst ───
    final burstGrow = _easeOutCubic((progress / 0.35).clamp(0.0, 1.0));
    final burstFade =
        (1.0 - _easeInQuad(((progress - 0.45) / 0.55).clamp(0.0, 1.0)))
            .clamp(0.0, 1.0);

    if (burstGrow > 0 && burstFade > 0) {
      // outer halo
      canvas.drawCircle(
        Offset(cx, cy),
        maxR * 0.55 * burstGrow,
        Paint()
          ..color = gold.withOpacity(0.55 * burstFade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * burstGrow + 10),
      );
      // golden core
      canvas.drawCircle(
        Offset(cx, cy),
        maxR * 0.28 * burstGrow,
        Paint()
          ..color = goldDeep.withOpacity(0.85 * burstFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
      // white hot center
      canvas.drawCircle(
        Offset(cx, cy),
        maxR * 0.12 * burstGrow,
        Paint()..color = white.withOpacity(0.95 * burstFade),
      );
    }

    // ─── Phase 2 (progress 0.1–0.85): three staggered expanding rings ───
    for (var i = 0; i < 3; i++) {
      final delay = i * 0.12;
      final localP = ((progress - delay) / 0.65).clamp(0.0, 1.0);
      if (localP <= 0) continue;

      final ringR = maxR * (0.15 + localP * 1.15);
      final ringAlpha = ((1.0 - localP).clamp(0.0, 1.0)) * 0.75;
      if (ringAlpha <= 0.01) continue;

      // outer soft glow
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = gold.withOpacity(ringAlpha * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = maxR * 0.10 * (1.0 - localP * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      // crisp inner ring
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = gold.withOpacity(ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = maxR * 0.028 * (1.0 - localP * 0.5),
      );
    }

    // ─── Phase 3 (progress 0.15–1.0): rising glowing particles ───
    const particleCount = 26;
    final particlePhase = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    if (particlePhase > 0) {
      for (var i = 0; i < particleCount; i++) {
        final seed = i * 37 + 11;
        final angle = (seed % 360) * pi / 180.0;
        final startRadius = maxR * (0.18 + (seed % 50) / 100.0 * 0.32);
        final riseDist = maxR * (0.55 + (seed % 40) / 100.0 * 0.45);

        final px = cx + cos(angle) * startRadius;
        final py = cy + sin(angle) * startRadius - particlePhase * riseDist;

        final fadeIn = (particlePhase * 4.0).clamp(0.0, 1.0);
        final fadeOut = ((1.0 - particlePhase) * 2.0).clamp(0.0, 1.0);
        final alpha = (fadeIn * fadeOut).clamp(0.0, 1.0);
        if (alpha <= 0.01) continue;

        final r = maxR * 0.012 * (1.0 + (seed % 30) / 30.0);

        // glow
        canvas.drawCircle(
          Offset(px, py),
          r * 3.0,
          Paint()
            ..color = gold.withOpacity(alpha * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        // bright point
        canvas.drawCircle(
          Offset(px, py),
          r,
          Paint()..color = white.withOpacity(alpha),
        );
      }
    }

    // ─── Phase 4 (progress 0.7–1.0): soft golden vignette fade ───
    final vignetteAlpha = ((progress - 0.7) / 0.3).clamp(0.0, 1.0) * 0.18;
    if (vignetteAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.transparent,
              gold.withOpacity(vignetteAlpha),
            ],
            stops: const [0.4, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }
  }

  double _easeOutCubic(double t) {
    final u = 1.0 - t;
    return 1.0 - u * u * u;
  }

  double _easeInQuad(double t) => t * t;

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = i * pi / 5 - pi / 2;
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

  @override
  bool shouldRepaint(covariant _IntroPainter old) {
    return old.progress != progress || old.type != type;
  }
}
