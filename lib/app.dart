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
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    // گوش دادن به سرویس بررسی نسخه
    UpdateService.instance.onUpdateAvailable = (_) {
      if (mounted) setState(() => _updateAvailable = true);
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: L10n.t('app_name'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: neonPalette.bg,
          ),
          builder: (context, child) => Directionality(
            textDirection: L10n.dir,
            child: Column(
              children: [
                // بنر آپدیت (فقط وقتی نسخه جدید هست)
                if (_updateAvailable)
                  UpdateBanner(
                    onUpdate: () async {
                      await reloadWebApp();
                    },
                  ),
                // محتوای اصلی اپ
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
