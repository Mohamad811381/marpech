// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/player_progression_service.dart';

/// Badge فشردهٔ سطح بازیکن — برای HomeTab
class LevelBadge extends StatelessWidget {
  final int xpTotal;
  final GamePalette palette;
  final VoidCallback? onTap;
  final bool hasPending;

  const LevelBadge({
    super.key,
    required this.xpTotal,
    required this.palette,
    this.onTap,
    this.hasPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = PlayerProgressionService.levelFromXp(xpTotal);
    final isMax = level >= PlayerProgressionService.maxLevel;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMax
                    ? Icons.workspace_premium_rounded
                    : Icons.military_tech_rounded,
                color: palette.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isMax ? 'MAX' : 'Lv.$level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                  height: 1.2,
                ),
              ),
              if (hasPending) ...[
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: palette.food,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}