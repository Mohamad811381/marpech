// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/services/localization_service.dart';
import '../home_helpers.dart';

class DailyRewardBanner extends StatelessWidget {
  final GamePalette palette;
  final int rewardAmount;
  final VoidCallback onTap;

  const DailyRewardBanner({
    super.key,
    required this.palette,
    required this.rewardAmount,
    required this.onTap,
  });

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.food.withOpacity(0.08),
          border: Border.all(color: p.food.withOpacity(0.5), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.food,
                shape: BoxShape.circle,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: homeLs(1.5),
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L10n.tf('menu_daily_reward_sub', {'n': rewardAmount}),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: p.food,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: p.food, size: 16),
          ],
        ),
      ),
    );
  }
}
