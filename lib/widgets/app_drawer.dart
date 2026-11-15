// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/game_palette.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/localization_service.dart';
import '../services/update_service.dart';
import '../utils/web_reload.dart';

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
              icon: Icons.system_update_alt_rounded,
              title: 'بررسی به‌روزرسانی',
              onTap: () => _checkForUpdate(context),
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
          _VersionText(
            style: TextStyle(
              fontSize: 12,
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── بررسی به‌روزرسانی ───────────────

  Future<void> _checkForUpdate(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    // بستن دراور
    navigator.pop();

    // کمی صبر تا انیمیشن بسته شدن تمام شود
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final navCtx = navigator.context;
    if (!navCtx.mounted) return;

    // نمایش loading
    showDialog(
      context: navCtx,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(palette: p),
    );

    final result = await UpdateService.instance.checkNow();

    if (!navCtx.mounted) return;
    Navigator.of(navCtx).pop(); // بستن loading

    if (!navCtx.mounted) return;

    switch (result) {
      case UpdateCheckResult.hasUpdate:
        _showUpdateDialog(navCtx);
        break;
      case UpdateCheckResult.upToDate:
        ScaffoldMessenger.of(navCtx).showSnackBar(
          _buildSnack(
            'نسخه شما به‌روز است ✅',
            p.accent,
            Icons.check_circle_rounded,
          ),
        );
        break;
      case UpdateCheckResult.error:
        ScaffoldMessenger.of(navCtx).showSnackBar(
          _buildSnack(
            'اتصال برقرار نشد. اینترنت را بررسی کنید.',
            p.food,
            Icons.wifi_off_rounded,
          ),
        );
        break;
    }
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border, width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.accent.withOpacity(0.15),
              ),
              child:
                  Icon(Icons.rocket_launch_rounded, color: p.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'نسخه جدید آماده است',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          kIsWeb
              ? 'آخرین نسخه با امکانات و بهبودهای جدید در دسترس است. برای دریافت، به‌روزرسانی کنید.'
              : 'برای به‌روزرسانی، به فروشگاه اپلیکیشن مراجعه کنید.',
          style: TextStyle(color: p.textMuted, height: 1.6, fontSize: 13),
        ),
        actions: [
          if (kIsWeb) ...[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('بعداً', style: TextStyle(color: p.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await reloadWebApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: p.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'به‌روزرسانی',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('باشه', style: TextStyle(color: p.accent)),
            ),
        ],
      ),
    );
  }

  SnackBar _buildSnack(String msg, Color color, IconData icon) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionText extends StatefulWidget {
  final TextStyle? style;
  const _VersionText({this.style});

  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  String _version = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // ۱) تلاش با PackageInfo
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      final v = info.version;
      final b = info.buildNumber;
      if (v.isNotEmpty) {
        setState(() {
          _version = b.isNotEmpty ? 'v$v+$b' : 'v$v';
        });
        return;
      }
    } catch (_) {
      // بی‌صدا رد شو، به fallback برو
    }

    // ۲) fallback: از UpdateService (که از app-version.json خوانده)
    if (!mounted) return;
    final sv = UpdateService.instance.semanticVersion;
    if (sv != null && sv.isNotEmpty) {
      setState(() => _version = 'v$sv');
      return;
    }

    // ۳) fallback نهایی: اگر UpdateService هنوز لود نشده، از currentVersion
    final cv = UpdateService.instance.currentVersion;
    if (cv != null && cv.isNotEmpty) {
      setState(() => _version = cv);
    }
    // اگر هیچ‌کدام نبود، همان v1.0.0 می‌ماند
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _version,
      style: widget.style,
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final GamePalette palette;
  const _LoadingDialog({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'در حال بررسی...',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
