// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/game_palette.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';
import 'history_screen.dart';

class StatsScreen extends StatefulWidget {
  final GamePalette palette;
  final bool embedded;

  const StatsScreen({
    super.key,
    required this.palette,
    this.embedded = false,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final AudioService _audio = AudioService();
  AchievementStats? _stats;
  Set<String> _unlocked = {};

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AchievementsService.getStats(),
      StorageService.getUnlockedAchievements(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as AchievementStats;
      _unlocked = results[1] as Set<String>;
    });
  }

  Future<void> _reset() async {
    await _audio.playSfx(Sfx.button);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          L10n.t('stats_reset_confirm_title'),
          style: TextStyle(color: p.textPrimary),
        ),
        content: Text(
          L10n.t('stats_reset_confirm_content'),
          style: TextStyle(color: p.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              L10n.t('cancel'),
              style: TextStyle(color: p.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              L10n.t('delete'),
              style: TextStyle(color: p.food),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService.resetAllStats();
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;

    // محتوای اصلی (مشترک بین embedded و standalone)
    final content = s == null
        ? Center(child: CircularProgressIndicator(color: p.accent))
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _heroCard(s),
              const SizedBox(height: 14),
              _grid(s),
              const SizedBox(height: 14),
              _barChart(s),
              const SizedBox(height: 14),
              _achievementProgress(),
              const SizedBox(height: 14),
              _historyButton(),
              const SizedBox(height: 14),
              _resetButton(),
            ],
          );

    // حالت embedded: فقط محتوا (بدون Scaffold و بدون top bar)
    if (widget.embedded) {
      return content;
    }

    // حالت standalone: با Scaffold و top bar
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // ---------- نوار بالا (فقط standalone) ----------

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('stats_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.t('stats_sub'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.insights_rounded, color: p.accent, size: 26),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: p.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.border),
          ),
          child: Icon(Icons.arrow_back_rounded, color: p.accent, size: 22),
        ),
      ),
    );
  }

  // ---------- کارت بزرگ ----------

  Widget _heroCard(AchievementStats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.accent.withOpacity(0.18), p.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: p.accent.withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: p.accent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: p.accent.withOpacity(0.5)),
            ),
            child: Icon(Icons.analytics_rounded, color: p.accent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('stats_total_score'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.totalScore}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: p.accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  L10n.tf('stats_in_games', {'n': s.gamesPlayed}),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- شبکه ----------

  Widget _grid(AchievementStats s) {
    final avg = s.gamesPlayed == 0 ? 0 : (s.totalScore / s.gamesPlayed).round();
    final items = [
      _StatItem(
        label: L10n.t('stats_games_played'),
        value: '${s.gamesPlayed}',
        icon: Icons.sports_esports_rounded,
        color: p.accent,
      ),
      _StatItem(
        label: L10n.t('stats_avg_score'),
        value: '$avg',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF00F0FF),
      ),
      _StatItem(
        label: L10n.t('stats_longest_snake'),
        value: '${s.longestSnake}',
        icon: Icons.straighten_rounded,
        color: const Color(0xFF8A7BFF),
      ),
      _StatItem(
        label: L10n.t('stats_best_record'),
        value: '${s.bestAny}',
        icon: Icons.emoji_events_rounded,
        color: p.food,
      ),
    ];

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statCard(items[0]),
              const SizedBox(height: 10),
              _statCard(items[1]),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _statCard(items[2]),
              const SizedBox(height: 10),
              _statCard(items[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- نمودار ----------

  Widget _barChart(AchievementStats s) {
    final bars = [
      _BarData(L10n.t('diff_easy_label'), s.bestEasy, const Color(0xFF4CE0B3)),
      _BarData(
          L10n.t('diff_normal_label'), s.bestNormal, const Color(0xFFFF8A5B)),
      _BarData(L10n.t('diff_hard_label'), s.bestHard, const Color(0xFFFF5CAB)),
    ];
    final maxVal = bars.map((b) => b.value).reduce(max);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: p.accent, size: 18),
              const SizedBox(width: 6),
              Text(
                L10n.t('stats_record_by_difficulty'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bars.map((b) {
                final ratio = b.value / safeMax;
                final height = 10 + 100 * ratio;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${b.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: b.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 44,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [b.color, b.color.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: b.color.withOpacity(0.35),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b.label,
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- دستاوردها ----------

  Widget _achievementProgress() {
    final total = allAchievements.length;
    final unlocked = _unlocked.length;
    final ratio = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: p.food, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  L10n.t('stats_achievements_progress'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Text(
                '$unlocked/$total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.food,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: p.border,
              valueColor: AlwaysStoppedAnimation(p.food),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unlocked == total
                ? L10n.t('stats_achievements_all')
                : L10n.tf(
                    'stats_achievements_remaining', {'n': total - unlocked}),
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ---------- دکمه‌ها ----------

  Widget _historyButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          await _audio.playSfx(Sfx.button);
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryScreen(palette: p),
            ),
          );
        },
        icon: Icon(Icons.history_rounded, color: p.accent, size: 20),
        label: Text(
          L10n.t('stats_history_btn'),
          style: TextStyle(
            color: p.accent,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: p.accent.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _resetButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _reset,
        icon: Icon(Icons.delete_outline_rounded, color: p.food, size: 20),
        label: Text(
          L10n.t('stats_reset_btn'),
          style: TextStyle(
            color: p.food,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: p.food.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}
