// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/widgets/level_badge.dart';

class HomeHeader extends StatelessWidget {
  final GamePalette palette;
  final int xpTotal;
  final int coins;
  final VoidCallback onMenuTap;
  final VoidCallback? onLevelBadgeTap;

  const HomeHeader({
    super.key,
    required this.palette,
    required this.xpTotal,
    required this.coins,
    required this.onMenuTap,
    this.onLevelBadgeTap,
  });

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: onMenuTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(Icons.menu_rounded, color: p.textPrimary, size: 22),
            ),
          ),
        ),
        const Spacer(),
        LevelBadge(
          xpTotal: xpTotal,
          palette: p,
          onTap: onLevelBadgeTap,
        ),
        const SizedBox(width: 14),
        _coinDisplay(),
      ],
    );
  }

  Widget _coinDisplay() {
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: p.food, size: 18),
            const SizedBox(width: 6),
            Text(
              '$coins',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.food,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
