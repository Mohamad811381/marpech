// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/chapter.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/services/levels_service.dart';

/// ردیف نقطه‌های مراحل فصل فعلی
class ChapterDots extends StatelessWidget {
  final GamePalette palette;
  final Set<int> completedIds;
  final int nextId;
  final int? freshDoneId;
  final bool animationsEnabled;
  final Animation<double> dotPulse;
  final Animation<double> pulse;

  const ChapterDots({
    super.key,
    required this.palette,
    required this.completedIds,
    required this.nextId,
    required this.freshDoneId,
    required this.animationsEnabled,
    required this.dotPulse,
    required this.pulse,
  });

  GamePalette get p => palette;

  /// فصلی که مرحله‌ی بعدی در آن قرار دارد
  Chapter _currentChapter(int nextId) {
    const chapters = LevelsService.chapters;
    return chapters.firstWhere(
      (c) => nextId >= c.startLevelId && nextId <= c.endLevelId,
      orElse: () => chapters.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _currentChapter(nextId);
    final ids = [
      for (var i = chapter.startLevelId; i <= chapter.endLevelId; i++) i,
    ];

    return Row(
      children: [
        for (var k = 0; k < ids.length; k++) ...[
          _levelDot(
            id: ids[k],
            done: completedIds.contains(ids[k]),
            isNext: ids[k] == nextId,
          ),
          if (k < ids.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: completedIds.contains(ids[k])
                    ? p.accent
                    : p.border.withOpacity(0.6),
              ),
            ),
        ],
      ],
    );
  }

  Widget _levelDot({
    required int id,
    required bool done,
    required bool isNext,
  }) {
    const double size = 8;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? p.accent : Colors.transparent,
        border: Border.all(
          color: (done || isNext) ? p.accent : p.border,
          width: 1.2,
        ),
      ),
    );

    // نقطه‌ی تازه‌تمام‌شده: یک پالس کوتاه
    if (id == freshDoneId && animationsEnabled) {
      return SizedBox(
        width: 14,
        height: 14,
        child: Center(
          child: AnimatedBuilder(
            animation: dotPulse,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + (1 - dotPulse.value) * 0.5,
              child: child,
            ),
            child: dot,
          ),
        ),
      );
    }

    if (!isNext) {
      return SizedBox(width: 12, height: 12, child: Center(child: dot));
    }

    // مرحله‌ی بعدی: کمی بزرگ‌تر و با نبض آرام
    return SizedBox(
      width: 14,
      height: 14,
      child: Center(
        child: AnimatedBuilder(
          animation: pulse,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + pulse.value * 0.35,
            child: child,
          ),
          child: dot,
        ),
      ),
    );
  }
}
