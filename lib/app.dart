// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game_palette.dart';
import 'screens/main_shell.dart';
import 'services/localization_service.dart';
import 'services/theme_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

class MarpechApp extends StatefulWidget {
  const MarpechApp({super.key});

  @override
  State<MarpechApp> createState() => _MarpechAppState();
}

class _MarpechAppState extends State<MarpechApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _dialogShown = false;

  static const String _prefKey = 'last_shown_update_version';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdateOnEntry();
      });
    }
  }

  Future<void> _checkForUpdateOnEntry() async {
    if (_dialogShown) return;

    final result = await UpdateService.instance.checkNow();
    if (!mounted || _dialogShown) return;

    if (result != UpdateCheckResult.optional &&
        result != UpdateCheckResult.force) {
      return;
    }

    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;

    final latest = UpdateService.instance.latestVersion;

    if (result == UpdateCheckResult.optional) {
      final alreadyShown = await _markOptionalShown(latest);
      if (alreadyShown) return;
    }

    if (!mounted) return;
    _dialogShown = true;

    await showUpdateDialog(
      ctx,
      showCancel: result == UpdateCheckResult.optional,
      version: latest,
    );
  }

  /// true برمی‌گرداند اگر برای این نسخه قبلاً نشان داده شده.
  Future<bool> _markOptionalShown(String? latest) async {
    if (latest == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefKey) == latest) return true;
      await prefs.setString(_prefKey, latest);
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[App] prefs error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService.instance,
        ThemeService.mode,
        ThemeService.darkPalette,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: L10n.t('app_name'),
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: ThemeService.buildTheme(lightPalette, Brightness.light),
          darkTheme: ThemeService.buildTheme(
            ThemeService.darkPalette.value,
            Brightness.dark,
          ),
          themeMode: ThemeService.mode.value,
          builder: (context, child) => Directionality(
            textDirection: L10n.dir,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}