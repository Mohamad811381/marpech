// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'models/game_palette.dart';
import 'screens/main_shell.dart';
import 'services/localization_service.dart';
import 'services/update_service.dart';
import 'utils/web_reload.dart';
import 'widgets/update_banner.dart';

class MarpechApp extends StatefulWidget {
  const MarpechApp({super.key});

  @override
  State<MarpechApp> createState() => _MarpechAppState();
}

class _MarpechAppState extends State<MarpechApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _updateAvailable = false;
  bool _autoDialogShown = false;

  @override
  void initState() {
    super.initState();
    UpdateService.instance.onUpdateAvailable = (_) {
      if (!mounted) return;
      setState(() => _updateAvailable = true);
      // باز شدن خودکار دیالوگ — فقط یک بار
      if (!_autoDialogShown) {
        _autoDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateDialog(context);
        });
      }
    };
  }

  String _bannerMessage() {
    final v = UpdateService.instance.remoteSemanticVersion;
    if (v != null && v.isNotEmpty) {
      return 'نسخه $v در دسترس است';
    }
    return 'نسخه جدید در دسترس است';
  }

  Future<void> _showUpdateDialog(BuildContext ctx) async {
    if (!mounted) return;
    final nav = _navigatorKey.currentContext;
    if (nav == null) return;

    showDialog(
      context: nav,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: neonPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPalette.border, width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonPalette.accent.withOpacity(0.15),
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                color: neonPalette.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'نسخه جدید آماده است',
                style: TextStyle(
                  color: neonPalette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          UpdateService.instance.remoteSemanticVersion != null
              ? 'نسخه ${UpdateService.instance.remoteSemanticVersion} '
                  'با امکانات و بهبودهای جدید در دسترس است.'
              : 'آخرین نسخه با امکانات و بهبودهای جدید در دسترس است.',
          style: TextStyle(
            color: neonPalette.textMuted,
            height: 1.6,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child:
                Text('بعداً', style: TextStyle(color: neonPalette.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await reloadWebApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: neonPalette.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'به‌روزرسانی',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
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
            child: Column(
              children: [
                if (_updateAvailable)
                  UpdateBanner(
                    message: _bannerMessage(),
                    onUpdate: () async {
                      await reloadWebApp();
                    },
                  ),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}
