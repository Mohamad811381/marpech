// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_palette.dart';
import 'storage_service.dart';

class ThemeService {
  ThemeService._();

  static const _kMode = 'set_theme_mode';
  static const _kLightPaletteId = 'set_light_palette_id';
  static const _kDarkPaletteId = 'set_dark_palette_id';

  /// حالت انتخابی کاربر: system / light / dark
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// id پالت روشن انتخابی
  static final ValueNotifier<String> lightPaletteId =
      ValueNotifier<String>(lightPalettes.first.id);

  /// id پالت تاریک انتخابی
  static final ValueNotifier<String> darkPaletteId =
      ValueNotifier<String>(neonPalette.id);

  /// پالت تاریک انتخابی (برای سازگاری با app.dart و settings_screen.dart)
  static final ValueNotifier<GamePalette> darkPalette =
      ValueNotifier<GamePalette>(neonPalette);

  static GamePalette lightPaletteById(String id) {
    for (final p in lightPalettes) {
      if (p.id == id) return p;
    }
    return lightPalettes.first;
  }

  static GamePalette darkPaletteById(String id) {
    for (final p in palettes) {
      if (p.id == id) return p;
    }
    return neonPalette;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final i = (prefs.getInt(_kMode) ?? 0).clamp(0, ThemeMode.values.length - 1);
    mode.value = ThemeMode.values[i];

    final savedLight = prefs.getString(_kLightPaletteId);
    lightPaletteId.value = lightPaletteById(savedLight ?? '').id;

    String? savedDark = prefs.getString(_kDarkPaletteId);
    if (savedDark == null) {
      // مهاجرت: کاربر قدیمی، از ایندکس قبلی بخوان
      final idx = await StorageService.getPaletteIndex();
      savedDark = palettes[idx.clamp(0, palettes.length - 1)].id;
    }
    final dark = darkPaletteById(savedDark);
    darkPaletteId.value = dark.id;
    darkPalette.value = dark;
  }

  static Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMode, m.index);
  }

  static Future<void> setLightPalette(GamePalette p) async {
    final resolved = lightPaletteById(p.id);
    lightPaletteId.value = resolved.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLightPaletteId, resolved.id);
  }

  static Future<void> setDarkPalette(GamePalette p) async {
    final resolved = darkPaletteById(p.id);
    darkPaletteId.value = resolved.id;
    darkPalette.value = resolved;
    final idx = palettes.indexWhere((pp) => pp.id == resolved.id);
    if (idx >= 0) await StorageService.setPaletteIndex(idx);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDarkPaletteId, resolved.id);
  }

  /// آیا الان باید تم روشن نمایش داده شود؟
  static bool isLight(BuildContext context) {
    if (mode.value == ThemeMode.light) return true;
    if (mode.value == ThemeMode.dark) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.light;
  }

  /// پالت نهایی که باید الان در کل اپ استفاده شود
  static GamePalette resolve(BuildContext context) {
    return isLight(context)
        ? lightPaletteById(lightPaletteId.value)
        : darkPalette.value;
  }

  /// ThemeData ساده؛ فقط برای ویجت‌های Material
  static ThemeData buildTheme(GamePalette p, Brightness b) {
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: p.bg,
    );
  }
}
