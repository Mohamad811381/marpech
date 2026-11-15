// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game_palette.dart';
import 'screens/main_shell.dart';
import 'services/localization_service.dart';
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
  static const String _forceAttemptsKeyPrefix = 'force_attempts_';
  static const int _maxForceAttempts = 2;

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

    // در ورود فقط optional یا force ارزش نمایش دارند
    if (result != UpdateCheckResult.optional &&
        result != UpdateCheckResult.force) {
      return;
    }

    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;

    final latest = UpdateService.instance.latestVersion;

    // ── ضد تکرار / ضد لوپ ──
    var skip = false;
    try {
      final prefs = await SharedPreferences.getInstance();

      if (result == UpdateCheckResult.force) {
        // ضد loop: حداکثر ۲ بار برای هر نسخه‌ی latest
        final key = '$_forceAttemptsKeyPrefix$latest';
        final attempts = prefs.getInt(key) ?? 0;
        if (attempts >= _maxForceAttempts) {
          if (kDebugMode) {
            debugPrint(
              '[App] force guard tripped for latest=$latest '
              '(attempts=$attempts)',
            );
          }
          skip = true;
        } else {
          await prefs.setInt(key, attempts + 1);
        }
      } else {
        // optional: فقط یک بار برای هر نسخه
        final lastShown = prefs.getString(_prefKey);
        if (latest != null && lastShown == latest) {
          if (kDebugMode) {
            debugPrint('[App] version $latest already shown, skipping');
          }
          skip = true;
        } else {
          await prefs.setString(_prefKey, latest ?? '');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[App] prefs error: $e');
    }

    if (skip) {
      _dialogShown = true;
      return;
    }

    if (!mounted) return;
    _dialogShown = true;

    await showUpdateDialog(
      ctx,
      showCancel: result == UpdateCheckResult.optional,
      version: latest,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: L10n.t('app_name'),
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: neonPalette.bg,
          ),
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
