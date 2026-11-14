// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_palette.dart';
import '../models/level_cosmetics.dart';
import '../models/level_reward.dart';
import '../models/player_title.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../services/player_progression_service.dart';
import '../services/settings_service.dart';
import 'xp_progress_bar.dart';

/// Batch aggregate از چند AddXpResult
class LevelUpBatch {
  final int oldLevel;
  final int newLevel;
  final int xpTotalAfter;
  final int totalXpGained;
  final List<LevelReward> milestones;
  final List<LevelReward> cosmetics;
  final PlayerTitle oldTitle;
  final PlayerTitle newTitle;

  const LevelUpBatch({
    required this.oldLevel,
    required this.newLevel,
    required this.xpTotalAfter,
    required this.totalXpGained,
    required this.milestones,
    required this.cosmetics,
    required this.oldTitle,
    required this.newTitle,
  });

  factory LevelUpBatch.fromResults(
    List<AddXpResult> results,
    int xpTotalAfter,
  ) {
    assert(results.isNotEmpty);
    final milestones = <LevelReward>[];
    for (final r in results) {
      milestones.addAll(r.milestonesGranted);
    }
    final oldLevel = results.first.oldLevel;
    final newLevel = results.last.newLevel;
    final totalXpGained = results.fold<int>(0, (sum, r) => sum + r.xpGained);
    return LevelUpBatch(
      oldLevel: oldLevel,
      newLevel: newLevel,
      xpTotalAfter: xpTotalAfter,
      totalXpGained: totalXpGained,
      milestones: milestones,
      cosmetics: milestones.where((m) => m.hasCosmetic).toList(),
      oldTitle: PlayerTitle.forLevel(oldLevel),
      newTitle: PlayerTitle.forLevel(newLevel),
    );
  }

  bool get titleChanged => oldTitle != newTitle;
  bool get isMaxLevel => newLevel >= PlayerProgressionService.maxLevel;
  int get totalCoins => milestones.fold<int>(0, (a, m) => a + m.coins);

  /// مسیر کامل مراحل: [oldLevel, oldLevel+1, ..., newLevel]
  List<int> get levelPath => [
        oldLevel,
        for (var l = oldLevel + 1; l <= newLevel; l++) l,
      ];

  /// عناوینی که در این batch کسب شده (بدون تکرار)
  List<PlayerTitle> get titlesEarned {
    final out = <PlayerTitle>[];
    var prev = PlayerTitle.forLevel(oldLevel);
    for (var l = oldLevel + 1; l <= newLevel; l++) {
      final t = PlayerTitle.forLevel(l);
      if (t != prev) {
        out.add(t);
        prev = t;
      }
    }
    return out;
  }
}

class LevelUpDialog extends StatefulWidget {
  final GamePalette palette;
  final LevelUpBatch batch;

  const LevelUpDialog({
    super.key,
    required this.palette,
    required this.batch,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  final _audio = AudioService();

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // ⚠️ .forward() صدا زده نمی‌شود — جلوگیری از ticker hang در تست

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audio.playSfx(Sfx.newRecord);
      if (SettingsService.current.haptics) {
        HapticFeedback.heavyImpact().catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.accent.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: p.accent.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close_rounded, color: p.textMuted, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              _levelBadge(batch),
              const SizedBox(height: 12),
              Text(
                batch.isMaxLevel
                    ? L10n.t('level_up_max_level')
                    : L10n.t('level_up_title'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: p.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                L10n.tf('level_up_from_to', {
                  'old': batch.oldLevel,
                  'new': batch.newLevel,
                }),
                style: TextStyle(fontSize: 13, color: p.textMuted),
              ),
              const SizedBox(height: 12),
              _levelPathWidget(batch),
              const SizedBox(height: 8),
              _totalXpRow(batch),
              if (batch.titlesEarned.isNotEmpty) ...[
                const SizedBox(height: 10),
                _titlesSection(batch),
              ],
              const SizedBox(height: 16),
              if (!batch.isMaxLevel)
                XpProgressBar(
                  xpTotal: batch.xpTotalAfter,
                  palette: p,
                  showLabels: true,
                  height: 10,
                ),
              if (batch.milestones.isNotEmpty) ...[
                const SizedBox(height: 18),
                _sectionHeader(
                  Icons.card_giftcard_rounded,
                  L10n.t('level_up_rewards_title'),
                ),
                const SizedBox(height: 8),
                ...batch.milestones.map(_rewardTile),
              ],
              if (batch.cosmetics.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionHeader(
                  Icons.auto_awesome_rounded,
                  L10n.t('level_up_cosmetics_title'),
                ),
                const SizedBox(height: 8),
                ...batch.cosmetics.map(_cosmeticTile),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: p.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    L10n.t('level_up_ok'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── Level Path ─────────

  Widget _levelPathWidget(LevelUpBatch batch) {
    final fullPath = batch.levelPath;
    // برای مسیرهای بلند، وسط را با "..." جمع می‌کنیم
    final displayPath = fullPath.length > 7
        ? <int>[
            fullPath.first,
            fullPath[1],
            -1, // sentinel برای "..."
            fullPath[fullPath.length - 2],
            fullPath.last,
          ]
        : fullPath;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < displayPath.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 11,
                  color: p.textMuted,
                ),
              ),
            _levelChip(
              displayPath[i],
              isLast: i == displayPath.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(int level, {required bool isLast}) {
    if (level == -1) {
      return Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: p.textMuted,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLast ? p.accent.withOpacity(0.18) : p.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLast ? p.accent.withOpacity(0.5) : p.border,
        ),
      ),
      child: Text(
        'Lv.$level',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isLast ? p.accent : p.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  // ───────── Total XP ─────────

  Widget _totalXpRow(LevelUpBatch batch) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bolt_rounded, color: p.food, size: 14),
        const SizedBox(width: 4),
        Text(
          L10n.tf('level_up_total_xp', {'n': batch.totalXpGained}),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: p.food,
          ),
        ),
      ],
    );
  }

  // ───────── Titles earned ─────────

  Widget _titlesSection(LevelUpBatch batch) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: batch.titlesEarned.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: p.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.accent.withOpacity(0.4)),
          ),
          child: Text(
            L10n.t(t.nameKey),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.accent,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────── Level badge ─────────

  Widget _levelBadge(LevelUpBatch batch) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              p.accent.withOpacity(0.35),
              p.accent.withOpacity(0.08),
            ],
          ),
          border: Border.all(color: p.accent.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: p.accent.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              color: p.accent,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              'Lv.${batch.newLevel}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: p.accent,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: p.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: p.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _rewardTile(LevelReward reward) {
    const gold = Color(0xFFFFD700);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monetization_on_rounded,
                color: gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L10n.tf('level_up_coin', {'n': reward.coins}),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: p.textMuted.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Lv.${reward.level}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: p.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cosmeticTile(LevelReward reward) {
    final cosmetic = levelCosmeticById(reward.cosmeticId!);
    final color = cosmetic?.color ?? p.accent;
    final icon = cosmetic?.icon ?? Icons.auto_awesome_rounded;
    final name = cosmetic?.nameKey ?? 'Lv.${reward.level}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cosmetic != null ? L10n.t(name) : name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
