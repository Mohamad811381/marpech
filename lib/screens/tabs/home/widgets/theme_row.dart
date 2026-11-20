// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/services/localization_service.dart';
import '../home_helpers.dart';

class ThemeRow extends StatelessWidget {
  final GamePalette palette;
  final VoidCallback onTap;

  const ThemeRow({super.key, required this.palette, required this.onTap});

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              homeUpper(L10n.t('menu_theme')),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: homeLs(2),
                color: p.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 0.5,
                color: p.border.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                  fontStyle: homeItalic,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.refresh_rounded, color: p.textMuted, size: 13),
          ],
        ),
      ),
    );
  }
}
