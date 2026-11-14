// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/game_palette.dart';
import '../../services/audio_service.dart';
import '../../services/daily_reward_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/daily_reward_dialog.dart';
import '../daily_challenges_screen.dart';

class DailyTab extends StatefulWidget {
  final GamePalette palette;
  const DailyTab({super.key, required this.palette});

  @override
  State<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {
  final _audio = AudioService();
  DailyRewardStatus? _rewardStatus;

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await DailyRewardService.getStatus();
    if (!mounted) return;
    setState(() => _rewardStatus = status);
  }

  Future<void> _openReward() async {
    await _audio.playSfx(Sfx.button);
    final status = await DailyRewardService.getStatus();
    if (!mounted) return;

    if (status.claimedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.t('menu_daily_reward_claimed_today'),
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
      return;
    }

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DailyRewardDialog(palette: p, status: status),
    );

    await _load();

    if (result != null && result > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.tf('menu_reward_toast', {'n': result}),
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // هدر
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                  color: p.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                L10n.t('nav_daily'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // کارت پاداش
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _rewardCard(),
        ),
        const SizedBox(height: 12),
        // چالش‌ها (embedded)
        Expanded(
          child: DailyChallengesScreen(palette: p, embedded: true),
        ),
      ],
    );
  }

  Widget _rewardCard() {
    final status = _rewardStatus;
    if (status == null) return const SizedBox.shrink();

    final claimed = status.claimedToday;
    const gold = Color(0xFFFFD700);

    if (claimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded,
                  color: p.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.t('reward_claimed'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    L10n.t('daily_reward_claimed_tomorrow'),
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
                ],
              ),
            ),
            if (status.streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${status.streak}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: gold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _openReward,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gold.withOpacity(0.20),
              const Color(0xFFFF8A5B).withOpacity(0.10),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gold.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.20),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.22),
                border: Border.all(
                  color: gold.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: gold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.t('menu_daily_reward_title'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    L10n.tf('menu_daily_reward_sub',
                        {'n': status.rewardAmount}),
                    style: const TextStyle(
                      fontSize: 11,
                      color: gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: p.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}