// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:math';
import 'package:flutter/material.dart';
import '../services/performance_service.dart';

class _BurstParticle {
  final Offset velocity;
  final Color color;
  final double sizeFactor;

  const _BurstParticle({
    required this.velocity,
    required this.color,
    required this.sizeFactor,
  });
}

class ParticleBurst {
  final Offset origin;
  final int scoreDelta;
  final Color textColor;
  final List<_BurstParticle> particles;

  const ParticleBurst({
    required this.origin,
    required this.scoreDelta,
    required this.textColor,
    required this.particles,
  });

  factory ParticleBurst.generate({
    required Offset origin,
    required int scoreDelta,
    required Color primary,
    required Color textColor,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final list = <_BurstParticle>[];
    final count = PerformanceService.particleCount;

    for (var i = 0; i < count; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final speed = 0.10 + r.nextDouble() * 0.18;
      final color = i.isEven
          ? primary
          : Color.lerp(primary, Colors.white, 0.35 + r.nextDouble() * 0.35)!;
      list.add(_BurstParticle(
        velocity: Offset(cos(angle), sin(angle)) * speed,
        color: color,
        sizeFactor: 0.006 + r.nextDouble() * 0.010,
      ));
    }

    return ParticleBurst(
      origin: origin,
      scoreDelta: scoreDelta,
      textColor: textColor,
      particles: list,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final ParticleBurst? burst;
  final double progress;

  ParticlePainter({required this.burst, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final b = burst;
    if (b == null || progress >= 1.0) return;

    final blurEnabled = PerformanceService.blurEnabled;
    final blurMultiplier = PerformanceService.blurMultiplier;

    final originPx = Offset(
      b.origin.dx * size.width,
      b.origin.dy * size.height,
    );

    final moveEased = Curves.easeOutCubic.transform(progress);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in b.particles) {
      final pos = originPx +
          Offset(
            p.velocity.dx * size.width,
            p.velocity.dy * size.height,
          ) *
              moveEased;

      final radius = p.sizeFactor * size.width * (1.0 - progress * 0.55);
      if (radius <= 0.2) continue;

      if (blurEnabled) {
        canvas.drawCircle(
          pos,
          radius * 2.2,
          Paint()
            ..color = p.color.withOpacity(alpha * 0.35)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, 6 * blurMultiplier),
        );
      }

      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = p.color.withOpacity(alpha),
      );
    }

    final textProgress = Curves.easeOut.transform(progress);
    final textY = originPx.dy - size.height * 0.10 * textProgress;
    final textAlpha = (1.0 - progress * 1.3).clamp(0.0, 1.0);
    if (textAlpha > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${b.scoreDelta}',
          style: TextStyle(
            color: b.textColor.withOpacity(textAlpha),
            fontSize: size.width * 0.055,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5 * textAlpha),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          originPx.dx - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter old) {
    return old.progress != progress || old.burst != burst;
  }
}