// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/difficulty.dart';
import 'package:marpech/models/game_palette.dart';
import '../home_helpers.dart';

class DifficultySelector extends StatelessWidget {
  final GamePalette palette;
  final Difficulty difficulty;
  final ValueChanged<Difficulty> onSelected;

  const DifficultySelector({
    super.key,
    required this.palette,
    required this.difficulty,
    required this.onSelected,
  });

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withOpacity(0.6), width: 0.5),
      ),
      child: Row(
        children: Difficulty.values.map((d) {
          final selected = d == difficulty;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(d),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  homeUpper(d.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: homeLs(1.5),
                    color: selected ? p.bg : p.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
