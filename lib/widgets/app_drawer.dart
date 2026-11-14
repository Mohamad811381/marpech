// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/localization_service.dart';

class AppDrawer extends StatelessWidget {
  final GamePalette palette;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onOpenSettings;

  const AppDrawer({
    super.key,
    required this.palette,
    required this.muted,
    required this.onToggleMute,
    required this.onOpenSettings,
  });

  GamePalette get p => palette;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: p.bg,
      child: SafeArea(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 8),
            _item(
              context,
              icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              title: L10n.t('drawer_sound'),
              trailing: muted
                  ? L10n.t('drawer_sound_off')
                  : L10n.t('drawer_sound_on'),
              onTap: onToggleMute,
            ),
            _item(
              context,
              icon: Icons.settings_rounded,
              title: L10n.t('drawer_settings'),
              onTap: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
            ),
            _item(
              context,
              icon: Icons.privacy_tip_rounded,
              title: L10n.t('drawer_privacy'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrivacyPolicyScreen(palette: p),
                  ),
                );
              },
            ),
            _item(
              context,
              icon: Icons.info_outline_rounded,
              title: L10n.t('drawer_about'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AboutScreen(palette: p),
                  ),
                );
              },
            ),
            const Spacer(),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surface,
              border: Border.all(color: p.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.gesture, size: 32, color: p.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('app_name'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.t('app_tagline'),
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: p.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trailing,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: p.food, size: 14),
          const SizedBox(width: 6),
          Text(
            L10n.t('app_version'),
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
