// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../services/localization_service.dart';
import '../services/performance_service.dart';

class DailyRewardDialog extends StatefulWidget {
  final GamePalette palette;
  final DailyRewardStatus status;

  const DailyRewardDialog({
    super.key,
    required this.palette,
    required this.status,
  });

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  final _audio = AudioService();
  late DailyRewardStatus _status;
  bool _claiming = false;

  static const _gold = Color(0xFFFFD700);

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
  }

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    await _audio.playSfx(Sfx.newRecord);
    final amount = await DailyRewardService.claim();
    if (!mounted) return;
    final newStatus = await DailyRewardService.getStatus();
    if (!mounted) return;
    setState(() => _status = newStatus);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
          boxShadow: PerformanceService.blurEnabled
              ? [
                  BoxShadow(
                    color: _gold.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close_rounded,
                    color: p.textMuted, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withOpacity(0.35),
                    _gold.withOpacity(0.10),
                  ],
                ),
                border: Border.all(color: _gold.withOpacity(0.5), width: 2),
                boxShadow: PerformanceService.blurEnabled
                    ? [
                        BoxShadow(
                          color: _gold.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: _gold, size: 42),
            ),
            const SizedBox(height: 12),
            Text(
              L10n.t('reward_title'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (_status.streak > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    L10n.tf('reward_streak', {'n': _status.streak}),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _gold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(7, (i) => Expanded(child: _dayBox(i))),
            ),
            const SizedBox(height: 20),
            _status.claimedToday ? _claimedIndicator() : _claimButton(),
          ],
        ),
      ),
    );
  }

  Widget _dayBox(int index) {
    final day = index + 1;
    final claimed = _status.claimedInCycle[index];
    final isToday = day == _status.cycleDay && !_status.claimedToday;
    final isClaimedToday =
        day == _status.cycleDay && _status.claimedToday;

    Color bg, border, textColor;
    IconData icon;
    Color iconColor;

    if (claimed || isClaimedToday) {
      bg = p.accent.withOpacity(0.15);
      border = p.accent.withOpacity(0.5);
      textColor = p.accent;
      icon = Icons.check_rounded;
      iconColor = p.accent;
    } else if (isToday) {
      bg = _gold.withOpacity(0.18);
      border = _gold;
      textColor = _gold;
      icon = Icons.star_rounded;
      iconColor = _gold;
    } else {
      bg = p.surfaceAlt;
      border = p.border;
      textColor = p.textMuted;
      icon = Icons.lock_rounded;
      iconColor = p.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
            width: (isToday || isClaimedToday) ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.tf('reward_day', {'n': day}),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: textColor.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 3),
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(height: 3),
            Text(
              '${DailyRewardService.rewards[index]}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _claiming ? null : _claim,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _claiming
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black54,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    L10n.tf('reward_claim',
                        {'n': _status.rewardAmount}),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _claimedIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: p.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: p.accent, size: 22),
          const SizedBox(width: 8),
          Text(
            L10n.t('reward_claimed'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: p.accent,
            ),
          ),
        ],
      ),
    );
  }
}