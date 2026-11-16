// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/audio_service.dart';
import 'services/localization_service.dart';
import 'services/performance_service.dart';
import 'services/player_progression_service.dart';
import 'services/settings_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── پایه: زبان + کیفیت گرافیک + تنظیمات + تم ──
  await LocalizationService.instance.load();
  await PerformanceService.load();
  await SettingsService.load();
  await ThemeService.load();

  // ── صدا ──
  try {
    await AudioService().init();
  } catch (e, st) {
    if (kDebugMode) debugPrint('[BOOT] Audio init error: $e\n$st');
  }

  // ── پیشرفت بازیکن ──
  try {
    await PlayerProgressionService.ensureSchema();
    await PlayerProgressionService.recoverPending();
  } catch (e, st) {
    if (kDebugMode) debugPrint('[BOOT] Progression init error: $e\n$st');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MarpechApp());
}
