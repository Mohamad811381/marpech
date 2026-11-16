// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_palette.dart';
import 'storage_service.dart';

class ThemeService {
  ThemeService._();

  static const _kMode = 'set_theme_mode';

  /// حالت انتخابی کاربر: system / light / dark
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// پالت تاریک انتخابی (یکی از palettes)
  static final ValueNotifier<GamePalette> darkPalette =
      ValueNotifier<GamePalette>(neonPalette);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final i = (prefs.getInt(_kMode) ?? 0)
        .clamp(0, ThemeMode.values.length - 1);
    mode.value = ThemeMode.values[i];

    final idx = await StorageService.getPaletteIndex();
    darkPalette.value = palettes[idx.clamp(0, palettes.length - 1)];
  }

  static Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMode, m.index);
  }

  static Future<void> setDarkPalette(GamePalette p) async {
    final idx = palettes.indexWhere((pp) => pp.id == p.id);
    if (idx < 0) return;
    darkPalette.value = p;
    await StorageService.setPaletteIndex(idx);
  }

  /// آیا الان باید تم روشن نمایش داده شود؟
  static bool isLight(BuildContext context) {
    if (mode.value == ThemeMode.light) return true;
    if (mode.value == ThemeMode.dark) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.light;
  }

  /// پالت نهایی که باید الان در کل اپ استفاده شود
  static GamePalette resolve(BuildContext context) {
    return isLight(context) ? lightPalette : darkPalette.value;
  }

  /// ThemeData ساده؛ فقط برای ویجت‌های Material (Dialog، SnackBar و ...)
  static ThemeData buildTheme(GamePalette p, Brightness b) {
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: p.bg,
    );
  }
}