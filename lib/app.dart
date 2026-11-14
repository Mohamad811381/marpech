// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'models/game_palette.dart';
import 'screens/main_shell.dart';
import 'services/localization_service.dart';

class MarpechApp extends StatelessWidget {
  const MarpechApp({super.key});

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
            child: child ?? const SizedBox.shrink(),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}