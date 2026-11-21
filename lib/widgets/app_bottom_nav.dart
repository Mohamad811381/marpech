// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/localization_service.dart';

class AppBottomNav extends StatelessWidget {
  final GamePalette palette;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.palette,
    required this.currentIndex,
    required this.onChanged,
  });

  static const _items = [
    (Icons.sports_esports_outlined, Icons.sports_esports_rounded, 'nav_home'),
    (Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'nav_progress'),
    (
      Icons.local_fire_department_outlined,
      Icons.local_fire_department_rounded,
      'nav_daily'
    ),
    (Icons.diamond_outlined, Icons.diamond_rounded, 'nav_shop'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final mq = MediaQuery.of(context);

    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(maxScaleFactor: 1.1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 6),
          child: Container(
            height: 54,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: p.surface.withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.border.withOpacity(0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: p.accent.withOpacity(0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final n = _items.length;
                final selW = c.maxWidth * 0.34;
                final otherW = (c.maxWidth - selW) / (n - 1);

                return Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      _NavItem(
                        palette: p,
                        icon: _items[i].$1,
                        selectedIcon: _items[i].$2,
                        label: L10n.t(_items[i].$3),
                        selected: i == currentIndex,
                        width: i == currentIndex ? selW : otherW,
                        onTap: () => onChanged(i),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final GamePalette palette;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  const _NavItem({
    required this.palette,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final color = selected ? p.accent : p.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? p.accent.withOpacity(0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? p.accent.withOpacity(0.45) : Colors.transparent,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: p.accent.withOpacity(0.25),
                  blurRadius: 14,
                ),
            ],
          ),
          child: Center(
            child: ClipRect(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? selectedIcon : icon, size: 21, color: color),
                  if (selected) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
