// ignore_for_file: prefer_const_declarations, deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/levels_service.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';
import '../services/performance_service.dart';

class WinnerScreen extends StatefulWidget {
  final GamePalette palette;
  const WinnerScreen({super.key, required this.palette});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen>
    with TickerProviderStateMixin {
  final _audio = AudioService();
  late AnimationController _crownController;
  late AnimationController _particleController;
  late AnimationController _statsController;

  GamePalette get p => widget.palette;

  int _gamesPlayed = 0;
  int _totalScore = 0;
  int _longestSnake = 0;
  int _achievementsUnlocked = 0;
  int _levelsCompleted = 0;
  int _totalLevels = 0;

  @override
  void initState() {
    super.initState();
    _crownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadStats();
    _audio.playSfx(Sfx.newRecord);

    // شروع شمارش آمار بعد از یه تأخیر کوچیک
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _crownController.dispose();
    _particleController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final games = await StorageService.getGamesPlayed();
    final score = await StorageService.getTotalScore();
    final longest = await StorageService.getLongestSnake();
    final ach = await AchievementsService.unlockedCount();
    final completed = await LevelsService.getCompleted();
    if (!mounted) return;
    setState(() {
      _gamesPlayed = games;
      _totalScore = score;
      _longestSnake = longest;
      _achievementsUnlocked = ach;
      _levelsCompleted = completed.length;
      _totalLevels = LevelsService.all.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // 🌟 ذرات شناور در پس‌زمینه
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _ConfettiPainter(
                progress: _particleController.value,
                accent: p.accent,
                food: p.food,
                textPrimary: p.textPrimary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // محتوا
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _crownSection(),
                  const SizedBox(height: 20),
                  _titleSection(),
                  const SizedBox(height: 30),
                  _statsSection(),
                  const SizedBox(height: 24),
                  _messageSection(),
                  const SizedBox(height: 30),
                  _homeButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- تاج ----------

  Widget _crownSection() {
    // 🍎 روی کیفیت پایین → بدون انیمیشن
    if (PerformanceService.effective == EffectiveQuality.low) {
      return _buildCrown(1.0, 0.5);
    }

    return AnimatedBuilder(
      animation: _crownController,
      builder: (context, _) {
        final scale = 1.0 + 0.05 * _crownController.value;
        final glowAlpha = 0.3 + 0.3 * _crownController.value;

        return _buildCrown(scale, glowAlpha);
      },
    );
  }

  Widget _buildCrown(double scale, double glowAlpha) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              p.food.withOpacity(0.30),
              p.food.withOpacity(0.05),
            ],
          ),
          boxShadow: PerformanceService.blurEnabled
              ? [
                  BoxShadow(
                    color: p.food.withOpacity(glowAlpha),
                    blurRadius: 50,
                    spreadRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 90,
            color: p.food,
          ),
        ),
      ),
    );
  }
  // ---------- عنوان ----------

  Widget _titleSection() {
    return FadeTransition(
      opacity: _statsController,
      child: Column(
        children: [
          Text(
            L10n.t('winner_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: p.textPrimary,
              shadows: [
                Shadow(
                  color: p.food.withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            L10n.t('winner_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: p.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- آمار ----------

  Widget _statsSection() {
    final items = [
      _WinnerStat(
        icon: Icons.map_rounded,
        label: L10n.t('winner_stat_levels'),
        value: '$_levelsCompleted/$_totalLevels',
        color: p.accent,
      ),
      _WinnerStat(
        icon: Icons.sports_esports_rounded,
        label: L10n.t('winner_stat_games'),
        value: '$_gamesPlayed',
        color: const Color(0xFF00F0FF),
      ),
      _WinnerStat(
        icon: Icons.insights_rounded,
        label: L10n.t('winner_stat_total_score'),
        value: '$_totalScore',
        color: p.food,
      ),
      _WinnerStat(
        icon: Icons.straighten_rounded,
        label: L10n.t('winner_stat_longest'),
        value: '$_longestSnake',
        color: const Color(0xFF8A7BFF),
      ),
      _WinnerStat(
        icon: Icons.emoji_events_rounded,
        label: L10n.t('winner_stat_achievements'),
        value: '$_achievementsUnlocked',
        color: const Color(0xFFFF5CAB),
      ),
      _WinnerStat(
        icon: Icons.auto_awesome_rounded,
        label: L10n.t('winner_stat_chapters'),
        value:
            '${LevelsService.chapters.length}/${LevelsService.chapters.length}',
        color: p.accent,
      ),
    ];

    return FadeTransition(
      opacity: _statsController,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.food.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: p.food.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: p.food, size: 18),
                const SizedBox(width: 8),
                Text(
                  L10n.t('winner_stats_title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items.map(_statTile).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(_WinnerStat s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: s.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.color.withOpacity(0.30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(s.icon, color: s.color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              s.value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: s.color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- پیام ----------

  Widget _messageSection() {
    return FadeTransition(
      opacity: _statsController,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              p.food.withOpacity(0.15),
              p.accent.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.food.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                L10n.t('winner_message'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- دکمه‌ی بازگشت ----------

  Widget _homeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          _audio.playSfx(Sfx.button);
          // برگرد به MainShell (خانه)
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        icon: const Icon(Icons.home_rounded, size: 22),
        label: Text(
          L10n.t('winner_back_home'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: p.food,
          foregroundColor: p.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          shadowColor: p.food.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _WinnerStat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WinnerStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

// 🌟 ذرات شناور
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color food;
  final Color textPrimary;

  _ConfettiPainter({
    required this.progress,
    required this.accent,
    required this.food,
    required this.textPrimary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    // 🍎 روی کیفیت پایین → نصف ذرات
    final count =
        PerformanceService.effective == EffectiveQuality.low ? 12 : 30;

    for (var i = 0; i < count; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();
      final colorPick = rng.nextInt(3);
      final size_ = 2.0 + rng.nextDouble() * 4.0;

      // حرکت نزولی
      final y = ((seedY + progress * speed) % 1.0) * size.height;
      final x = seedX * size.width;

      // پالس
      final pulse = (sin(progress * pi * 2 + phase * pi * 2) + 1) / 2;
      final opacity = 0.3 + 0.5 * pulse;

      final color = colorPick == 0
          ? food.withOpacity(opacity)
          : colorPick == 1
              ? accent.withOpacity(opacity)
              : textPrimary.withOpacity(opacity * 0.5);

      canvas.drawCircle(
        Offset(x, y),
        size_,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
