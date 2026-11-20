// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/board_pattern.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/models/skins.dart';
import 'package:marpech/services/levels_service.dart';
import 'package:marpech/services/localization_service.dart';
import '../home_helpers.dart';
import 'board_preview.dart';
import 'chapter_dots.dart';

/// HERO: ادامه‌ی ماجرا
class LevelHero extends StatelessWidget {
  final GamePalette palette;
  final int completedLevels;
  final Set<int> completedIds;
  final int nextLevel;
  final bool showGain;
  final int gainedLevels;
  final int? freshDoneId;
  final bool animationsEnabled;

  final Animation<double> enterFade;
  final Animation<Offset> enterSlide;
  final Animation<double> numberAnim;
  final Animation<double> dotPulse;
  final Animation<double> pulse;
  final Animation<double> boardPulse;

  final SnakeSkin snakeSkin;
  final FoodSkin foodSkin;
  final TrailEffect trail;
  final BoardPattern pattern;
  final PatternIntensity intensity;

  final VoidCallback onOpenLevels;
  final VoidCallback onContinue;

  const LevelHero({
    super.key,
    required this.palette,
    required this.completedLevels,
    required this.completedIds,
    required this.nextLevel,
    required this.showGain,
    required this.gainedLevels,
    required this.freshDoneId,
    required this.animationsEnabled,
    required this.enterFade,
    required this.enterSlide,
    required this.numberAnim,
    required this.dotPulse,
    required this.pulse,
    required this.boardPulse,
    required this.snakeSkin,
    required this.foodSkin,
    required this.trail,
    required this.pattern,
    required this.intensity,
    required this.onOpenLevels,
    required this.onContinue,
  });

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    final totalLevels = LevelsService.all.length;
    final progress = totalLevels == 0
        ? 0.0
        : (completedLevels / totalLevels).clamp(0.0, 1.0);
    final allDone = completedLevels >= totalLevels;

    return FadeTransition(
      opacity: enterFade,
      child: SlideTransition(
        position: enterSlide,
        child: InkWell(
          onTap: onOpenLevels,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.accent.withOpacity(0.22),
                  p.surface,
                ],
              ),
              border: Border.all(color: p.accent.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withOpacity(0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeUpper(allDone
                            ? L10n.t('home_done')
                            : L10n.t('home_next_level')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: p.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _animatedNumber(
                        allDone ? L10n.t('home_all_done') : '$nextLevel',
                      ),
                      if (showGain)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            L10n.tf('home_gain_level', {'n': gainedLevels}),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: p.accent,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: p.border.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation(p.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        L10n.tf('home_levels_progress', {
                          'done': completedLevels,
                          'total': totalLevels,
                        }),
                        style: TextStyle(fontSize: 11, color: p.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ChapterDots(
                        palette: p,
                        completedIds: completedIds,
                        nextId: nextLevel,
                        freshDoneId: freshDoneId,
                        animationsEnabled: animationsEnabled,
                        dotPulse: dotPulse,
                        pulse: pulse,
                      ),
                      const SizedBox(height: 14),
                      _continueCta(),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 128,
                  child: BoardPreview(
                    palette: p,
                    boardPulse: boardPulse,
                    snakeSkin: snakeSkin,
                    foodSkin: foodSkin,
                    trail: trail,
                    pattern: pattern,
                    intensity: intensity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// عدد بزرگ مرحله. عدد همیشه کامل دیده می‌شه؛ انیمیشن فقط جابه‌جایی کوچیکه.
  Widget _animatedNumber(String text) {
    final number = Text(
      text,
      style: TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.w900,
        height: 1.0,
        color: p.textPrimary,
      ),
    );

    if (!animationsEnabled) return number;

    return AnimatedBuilder(
      animation: numberAnim,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(numberAnim.value);
        return Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        );
      },
      child: number,
    );
  }

  Widget _continueCta() {
    return InkWell(
      onTap: onContinue,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, child) => Transform.scale(
          scale: 1.0 + pulse.value * 0.03,
          child: child,
        ),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: p.accent.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.t('home_continue'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: p.bg,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.play_arrow_rounded, color: p.bg, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
