// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marpech/services/theme_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/game_palette.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../services/shop_service.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

class AppDrawer extends StatefulWidget {
  final GamePalette palette;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onOpenSettings;
  final VoidCallback? onPaletteChanged;

  const AppDrawer({
    super.key,
    required this.palette,
    required this.muted,
    required this.onToggleMute,
    required this.onOpenSettings,
    this.onPaletteChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _checking = false;
  UpdateCheckResult? _lastResult;
  String? _latestVersion;

  final _audio = AudioService();

  GamePalette get p => widget.palette;
  bool get muted => widget.muted;

  // ── Helpers برای i18n (همان الگوی home_tab) ──
  double _ls(double english) => L10n.isFa ? 0 : english;
  FontStyle get _italic => L10n.isFa ? FontStyle.normal : FontStyle.italic;
  String _upper(String s) => L10n.isFa ? s : s.toUpperCase();

  @override
  void initState() {
    super.initState();
    // چک خودکار (فقط وب)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          _themeRow(),
          const SizedBox(height: 6),
          _themeModeSelector(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _item(
                  context,
                  icon: muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
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
                  icon: Icons.privacy_tip_outlined,
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
              ],
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  // ─────────────── هدر ───────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 36, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 1, color: p.accent.withOpacity(0.6)),
          const SizedBox(height: 14),
          Text(
            L10n.t('app_name'),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w300,
              height: 1.1,
              letterSpacing: _ls(2),
              color: p.textPrimary,
              fontStyle: _italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _upper(L10n.t('app_tagline')),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: _ls(3),
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── ردیف تم (همان صفحه‌ی اصلی) ───────────────

  Widget _themeRow() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 8),
      child: InkWell(
        onTap: _cyclePalette,
        child: Row(
          children: [
            Text(
              _upper(L10n.t('menu_theme')),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: _ls(2),
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
                  fontStyle: _italic,
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

  Future<void> _cyclePalette() async {
    await _audio.playSfx(Sfx.button);
    final isLight = ThemeService.isLight(context);

    if (isLight) {
      // چرخش بین پالت‌های روشن (همه‌ی پالت‌های روشن رایگان‌اند)
      final currentId = ThemeService.lightPaletteId.value;
      final currentIdx = lightPalettes.indexWhere((e) => e.id == currentId);
      final next = lightPalettes[(currentIdx + 1) % lightPalettes.length];
      await ThemeService.setLightPalette(next);
    } else {
      // چرخش بین پالت‌های تاریک باز شده
      final unlocked = await ShopService.getUnlockedThemes();
      final currentId = ThemeService.darkPalette.value.id;
      final currentIdx = palettes.indexWhere((e) => e.id == currentId);
      var nextIdx = currentIdx;
      for (var i = 1; i <= palettes.length; i++) {
        final idx = (currentIdx + i) % palettes.length;
        if (unlocked.contains(palettes[idx].id)) {
          nextIdx = idx;
          break;
        }
      }
      await ThemeService.setDarkPalette(palettes[nextIdx]);
    }

    widget.onPaletteChanged?.call();
    if (mounted) setState(() {});
  }

  // ─────────────── انتخاب حالت تم ───────────────

  Widget _themeModeSelector() {
    final options = <ThemeMode, String>{
      ThemeMode.system: L10n.t('settings_theme_system'),
      ThemeMode.light: L10n.t('settings_theme_light'),
      ThemeMode.dark: L10n.t('settings_theme_dark'),
    };
    final entries = options.entries.toList();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.mode,
        builder: (context, mode, _) {
          return Row(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _themeCell(
                    label: entries[i].value,
                    selected: entries[i].key == mode,
                    onTap: () => ThemeService.setMode(entries[i].key),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _themeCell({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? p.accent.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: selected ? p.accent : p.border,
            width: selected ? 1.2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _upper(label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: _ls(1),
            color: selected ? p.accent : p.textMuted,
          ),
        ),
      ),
    );
  }

  // ─────────────── آیتم منو ───────────────

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: p.accent.withOpacity(0.08),
      highlightColor: p.accent.withOpacity(0.03),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 15, 24, 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.border.withOpacity(0.5), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: p.accent, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailing != null)
              Text(
                _upper(trailing),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: _ls(1.5),
                  color: p.textMuted,
                ),
              ),
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
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 1.8, color: p.accent),
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

  // ─────────────── فوتر ───────────────

  Widget _footer() {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: p.food, size: 12),
          const SizedBox(width: 8),
          _VersionText(
            style: TextStyle(
              fontSize: 10,
              color: p.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: _ls(1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
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
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: palette.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
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
