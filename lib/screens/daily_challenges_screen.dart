// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/daily_challenge.dart';
import '../models/game_palette.dart';
import '../services/audio_service.dart';
import '../services/daily_challenges_service.dart';
import '../services/localization_service.dart';

class DailyChallengesScreen extends StatefulWidget {
  final GamePalette palette;
  final bool embedded;

  const DailyChallengesScreen({
    super.key,
    required this.palette,
    this.embedded = false,
  });

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  final _audio = AudioService();
  List<DailyChallenge>? _challenges;
  int _coins = 0;

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await DailyChallengesService.getChallenges();
    final coins = await DailyChallengesService.getCoins();
    if (!mounted) return;
    setState(() {
      _challenges = c;
      _coins = coins;
    });
  }

  Future<void> _claim(DailyChallenge c) async {
    await _audio.playSfx(Sfx.newRecord);
    final reward = await DailyChallengesService.claimReward(c.id);
    if (reward > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.tf('challenges_toast', {'n': reward}),
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // محتوای مشترک (بدون Scaffold)
    final content = _challenges == null
        ? Center(child: CircularProgressIndicator(color: p.accent))
        : _challenges!.isEmpty
            ? Center(
                child: Text(
                  L10n.t('challenges_empty'),
                  style: TextStyle(color: p.textMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // در حالت embedded، کارت سکه نشون داده نمی‌شه (چون DailyTab خودش کارت پاداش داره)
                  if (!widget.embedded) ...[
                    _coinsCard(),
                    const SizedBox(height: 14),
                  ],
                  ..._challenges!.map(_challengeCard),
                  const SizedBox(height: 14),
                  _resetTimer(),
                ],
              );

    // حالت embedded: فقط محتوا
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
                  L10n.t('challenges_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.t('challenges_sub'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.event_available_rounded,
              color: p.accent, size: 26),
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

  // ---------- کارت سکه (فقط standalone) ----------

  Widget _coinsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.food.withOpacity(0.20), p.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.food.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: p.food.withOpacity(0.20),
              shape: BoxShape.circle,
              border: Border.all(color: p.food.withOpacity(0.5)),
            ),
            child: Icon(Icons.monetization_on_rounded,
                color: p.food, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('challenges_coins'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                Text(
                  '$_coins',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: p.food,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- کارت چالش ----------

  Widget _challengeCard(DailyChallenge c) {
    final claimed = c.claimed;
    final canClaim = c.canClaim;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claimed
              ? p.border.withOpacity(0.5)
              : canClaim
                  ? c.color.withOpacity(0.7)
                  : p.border,
          width: canClaim ? 2 : 1,
        ),
        boxShadow: canClaim
            ? [
                BoxShadow(
                  color: c.color.withOpacity(0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.color.withOpacity(claimed ? 0.10 : 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  claimed ? Icons.check_circle_rounded : c.icon,
                  color: claimed ? p.textMuted : c.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: claimed ? p.textMuted : p.textPrimary,
                        decoration:
                            claimed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on_rounded,
                            color: p.food, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          L10n.tf('challenges_reward', {'n': c.reward}),
                          style: TextStyle(
                            fontSize: 11,
                            color: p.food,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canClaim) _claimButton(c),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.ratio,
                    minHeight: 6,
                    backgroundColor: p.border,
                    valueColor: AlwaysStoppedAnimation(
                      claimed ? p.textMuted : c.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${c.progress.clamp(0, c.target)}/${c.target}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: claimed ? p.textMuted : c.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _claimButton(DailyChallenge c) {
    return Material(
      color: c.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _claim(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            L10n.t('claim'),
            style: TextStyle(
              color: p.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- شمارش معکوس ----------

  Widget _resetTimer() {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes - hours * 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, color: p.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(
            L10n.tf('challenges_reset_time', {'h': hours, 'm': mins}),
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}