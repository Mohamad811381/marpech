// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/game_palette.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/localization_service.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

class AppDrawer extends StatefulWidget {
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

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _checking = false;
  UpdateCheckResult? _lastResult;
  String? _latestVersion;

  GamePalette get p => widget.palette;
  bool get muted => widget.muted;

  @override
  void initState() {
    super.initState();
    // چک خودکار موقع باز شدن Drawer (فقط وب)
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoCheck());
    }
  }

  Future<void> _autoCheck() async {
    if (!mounted) return;
    setState(() => _checking = true);
    try {
      final result = await UpdateService.instance.checkNow();
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _latestVersion = UpdateService.instance.latestVersion;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

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
              onTap: widget.onToggleMute,
            ),
            _item(
              context,
              icon: Icons.settings_rounded,
              title: L10n.t('drawer_settings'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onOpenSettings();
              },
            ),
            _item(
              context,
              icon: Icons.system_update_alt_rounded,
              title: L10n.t('update_check_menu'),
              trailingWidget: _updateBadge(),
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

  // ─────────────── بج وضعیت آپدیت ───────────────
  Widget _updateBadge() {
    if (!kIsWeb) {
      return _Badge(
        text: L10n.t('update_badge_store'),
        color: p.textMuted,
        bgColor: p.surfaceAlt,
      );
    }
    if (_checking) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
      );
    }
    switch (_lastResult) {
      case UpdateCheckResult.optional:
        return _Badge(
          text: _latestVersion != null
              ? 'v$_latestVersion'
              : L10n.t('update_badge_new'),
          color: Colors.white,
          bgColor: p.accent,
        );
      case UpdateCheckResult.force:
        return _Badge(
          text: _latestVersion != null
              ? L10n.tf('update_badge_forced', {'version': _latestVersion})
              : L10n.t('update_badge_forced_plain'),
          color: Colors.white,
          bgColor: p.food,
        );
      case UpdateCheckResult.upToDate:
        return _Badge(
          text: L10n.t('update_badge_uptodate'),
          color: Colors.white,
          bgColor: Colors.green.shade600,
        );
      case UpdateCheckResult.error:
      case null:
        return _Badge(
          text: L10n.t('update_badge_unknown'),
          color: p.textMuted,
          bgColor: p.surfaceAlt,
        );
    }
  }
  // ─────────────── header / item / footer ───────────────

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
    Widget? trailingWidget,
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
                if (trailingWidget != null)
                  trailingWidget
                else if (trailing != null)
                  _Badge(
                    text: trailing,
                    color: p.textMuted,
                    bgColor: p.surfaceAlt,
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

  // ─────────────── بررسی دستی ───────────────

  Future<void> _checkForUpdate(BuildContext context) async {
    if (!kIsWeb) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(L10n.t('update_store_only')),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final nav = Navigator.of(context, rootNavigator: true);
    final navCtx = nav.context;

    // بستن دراور
    Navigator.of(context).pop();

    // کمی صبر برای انیمیشن
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!navCtx.mounted) return;

    // loading
    showDialog(
      context: navCtx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => _LoadingDialog(palette: p),
    );

    // اگر چک خودکار در جریان باشد، checkNow همان Future را برمی‌گرداند
    // و کاربر منتظر نتیجه‌ی واقعی می‌ماند (نه پاسخ ساختگی «به‌روز است»).
    final result = await UpdateService.instance.checkNow();

    if (!navCtx.mounted) return;
    Navigator.of(navCtx, rootNavigator: true).pop(); // بستن loading
    if (!navCtx.mounted) return;

    switch (result) {
      case UpdateCheckResult.optional:
        await showUpdateDialog(
          navCtx,
          showCancel: true,
          version: UpdateService.instance.latestVersion,
        );
        break;

      case UpdateCheckResult.force:
        await showUpdateDialog(
          navCtx,
          showCancel: false,
          version: UpdateService.instance.latestVersion,
        );
        break;

      case UpdateCheckResult.upToDate:
        await showUpToDateDialog(
          navCtx,
          version: UpdateService.instance.latestVersion,
        );
        break;

      case UpdateCheckResult.error:
        ScaffoldMessenger.of(navCtx).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: p.food,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    L10n.t('update_no_connection'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }
  }
}

// ─────────────── بج کوچک ───────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────── لودینگ ───────────────

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
              L10n.t('update_checking'),
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

// ─────────────── ویجت نسخه ───────────────
class _VersionText extends StatefulWidget {
  final TextStyle? style;
  const _VersionText({this.style});

  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  late String _version;

  @override
  void initState() {
    super.initState();
    _version = L10n.t('version_loading');
    _load();
  }

  Future<void> _load() async {
    // ۱) نسخه‌ی تزریق‌شده در build (CI و دیباگ با dart-define)
    if (UpdateService.buildVersion.isNotEmpty) {
      const b = UpdateService.buildNumber;
      if (!mounted) return;
      setState(() {
        _version = b.isNotEmpty
            ? 'v${UpdateService.buildVersion}+$b'
            : 'v${UpdateService.buildVersion}';
      });
      return;
    }

    // ۲) PackageInfo — فقط وقتی dart-define نباشد
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
    } catch (_) {}

    // ۳) هیچ‌کدام نبود
    if (!mounted) return;
    setState(() => _version = L10n.t('version_unknown'));
  }

  @override
  Widget build(BuildContext context) {
    return Text(_version, style: widget.style);
  }
}
