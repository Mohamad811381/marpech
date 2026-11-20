// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:marpech/models/board_pattern.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/models/skins.dart';
import 'package:marpech/widgets/board_painter.dart';

/// تخته‌ی پیش‌نمایش: حتماً مربعی تا شبکه و مار درست کشیده بشن.
class BoardPreview extends StatelessWidget {
  final GamePalette palette;
  final Animation<double> boardPulse;
  final SnakeSkin snakeSkin;
  final FoodSkin foodSkin;
  final TrailEffect trail;
  final BoardPattern pattern;
  final PatternIntensity intensity;

  const BoardPreview({
    super.key,
    required this.palette,
    required this.boardPulse,
    required this.snakeSkin,
    required this.foodSkin,
    required this.trail,
    required this.pattern,
    required this.intensity,
  });

  GamePalette get p => palette;

  static const _previewSnake = [
    math.Point(2, 3),
    math.Point(3, 3),
    math.Point(4, 3),
    math.Point(5, 3),
    math.Point(5, 4),
    math.Point(5, 5),
    math.Point(4, 5),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.board,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border.withOpacity(0.6), width: 0.5),
        ),
        child: AnimatedBuilder(
          animation: boardPulse,
          builder: (_, __) => CustomPaint(
            painter: BoardPainter(
              snake: _previewSnake,
              prevSnake: _previewSnake,
              moveProgress: 1.0,
              food: const math.Point(8, 2),
              dir: const math.Point(1, 0),
              palette: p,
              pulse: boardPulse.value,
              cols: 10,
              rows: 10,
              snakeSkin: snakeSkin,
              foodSkin: foodSkin,
              trail: trail,
              pattern: pattern,
              patternIntensity: intensity,
              ghostSkin: GhostSkin.basic,
              timePhase: boardPulse.value,
              showGrid: true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
