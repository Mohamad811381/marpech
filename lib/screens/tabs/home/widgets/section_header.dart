// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/game_palette.dart';
import '../home_helpers.dart';

class SectionHeader extends StatelessWidget {
  final GamePalette palette;
  final String label;

  const SectionHeader({super.key, required this.palette, required this.label});

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 16, height: 0.5, color: p.textMuted),
          const SizedBox(width: 10),
          Text(
            homeUpper(label),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: homeLs(3),
              color: p.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 0.5, color: p.textMuted.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
