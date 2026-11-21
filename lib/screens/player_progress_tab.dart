// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../models/level_cosmetics.dart';
import '../models/level_reward.dart';
import '../models/player_profile.dart';
import '../services/localization_service.dart';
import '../services/player_progression_service.dart';
import '../services/storage_service.dart';
import '../widgets/xp_progress_bar.dart';

class PlayerProgressTab extends StatefulWidget {
  final GamePalette palette;
  const PlayerProgressTab({super.key, required this.palette});

  @override
  State<PlayerProgressTab> createState() => _PlayerProgressTabState();
}

class _PlayerProgressTabState extends State<PlayerProgressTab> {
  PlayerProfile? _profile;
  Set<String> _ownedCosmetics = {};
  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PlayerProgressionService.loadProfile(),
      StorageService.getLevelOwnedCosmetics(),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as PlayerProfile;
      _ownedCosmetics = results[1] as Set<String>;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return Center(child: CircularProgressIndicator(color: p.accent));
    }
    final level = PlayerProgressionService.levelFromXp(profile.xpTotal);
    final atMax = level >= PlayerProgressionService.maxLevel;

    return RefreshIndicator(
      onRefresh: _load,
      color: p.accent,
      backgroundColor: p.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _heroCard(profile, level, atMax),
          const SizedBox(height: 14),
          _bySourceSection(profile),
          const SizedBox(height: 14),
          _upcomingRewardsSection(profile, level),
          const SizedBox(height: 14),
          _upcomingCosmeticsSection(level),
        ],
      ),
    );
  }

  // ───────── Hero ─────────

  Widget _heroCard(PlayerProfile profile, int level, bool atMax) {
    final title = PlayerProgressionService.titleFor(profile.xpTotal);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: p.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: p.accent.withOpacity(0.5), width: 2),
                ),
                child: Icon(
                  atMax
                      ? Icons.workspace_premium_rounded
                      : Icons.military_tech_rounded,
                  color: p.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.t('level_badge_level'),
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                    Text(
                      atMax ? 'MAX' : 'Lv. $level',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: p.accent,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      L10n.t(title.nameKey),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: p.textMuted, size: 20),
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 16),
          XpProgressBar(
            xpTotal: profile.xpTotal,
            palette: p,
            showLabels: true,
            height: 10,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: p.food, size: 14),
              const SizedBox(width: 4),
              Text(
                L10n.tf('player_progress_total_xp', {'n': profile.xpTotal}),
                style: TextStyle(
                  fontSize: 12,
                  color: p.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────── By Source ─────────

  Widget _bySourceSection(PlayerProfile profile) {
    final entries = profile.xpBySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();
    final maxVal = entries.first.value.toDouble();

    return _section(
      icon: Icons.pie_chart_rounded,
      title: L10n.t('player_progress_by_source'),
      child: Column(
        children: entries.map((e) {
          final ratio = maxVal <= 0 ? 0.0 : e.value / maxVal;
          final label = _sourceLabel(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: p.border,
                      valueColor: AlwaysStoppedAnimation(p.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${e.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _sourceLabel(String key) {
    final translationKey = 'player_progress_source_$key';
    final label = L10n.t(translationKey);
    return label == translationKey ? key : label;
  }

  // ───────── Upcoming Rewards ─────────

  Widget _upcomingRewardsSection(PlayerProfile profile, int level) {
    final upcoming = allLevelRewards
        .where((r) =>
            r.level > level && !profile.levelRewardsGranted.contains(r.level))
        .take(5)
        .toList();

    if (upcoming.isEmpty) {
      return _section(
        icon: Icons.card_giftcard_rounded,
        title: L10n.t('player_progress_upcoming_rewards'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            L10n.t('player_progress_no_upcoming'),
            style: TextStyle(
              fontSize: 12,
              color: p.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return _section(
      icon: Icons.card_giftcard_rounded,
      title: L10n.t('player_progress_upcoming_rewards'),
      child: Column(
        children: upcoming.map((r) => _upcomingRewardTile(r)).toList(),
      ),
    );
  }

  Widget _upcomingRewardTile(LevelReward reward) {
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_rounded, color: gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L10n.tf('level_up_coin', {'n': reward.coins}),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.textMuted.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              L10n.tf('player_progress_locked_at', {'n': reward.level}),
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

  // ───────── Upcoming Cosmetics ─────────

  Widget _upcomingCosmeticsSection(int level) {
    final upcoming = allLevelCosmetics
        .where((c) => !_ownedCosmetics.contains(c.id))
        .take(5)
        .toList();

    if (upcoming.isEmpty) {
      return _section(
        icon: Icons.auto_awesome_rounded,
        title: L10n.t('player_progress_upcoming_cosmetics'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            L10n.t('player_progress_no_upcoming'),
            style: TextStyle(
              fontSize: 12,
              color: p.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return _section(
      icon: Icons.auto_awesome_rounded,
      title: L10n.t('player_progress_upcoming_cosmetics'),
      child: Column(
        children: upcoming.map((c) => _upcomingCosmeticTile(c)).toList(),
      ),
    );
  }

  Widget _upcomingCosmeticTile(LevelCosmetic cosmetic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cosmetic.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cosmetic.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cosmetic.icon, color: cosmetic.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L10n.t(cosmetic.nameKey),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.textMuted.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              L10n.tf(
                  'player_progress_locked_at', {'n': cosmetic.requiredLevel}),
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

  // ───────── Helpers ─────────

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
              Icon(icon, color: p.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
