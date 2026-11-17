import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'settings_service.dart';

class AppHaptics {
  AppHaptics._();

  static bool _hasVibrator = false;

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (_) {
      _hasVibrator = false;
    }
  }

  static Future<void> light() => _pulse(15, HapticFeedback.lightImpact);
  static Future<void> medium() => _pulse(25, HapticFeedback.mediumImpact);
  static Future<void> heavy() => _pulse(45, HapticFeedback.heavyImpact);
  static Future<void> selection() => _pulse(10, HapticFeedback.selectionClick);

  static Future<void> _pulse(int ms, Future<void> Function() fallback) async {
    if (!SettingsService.current.haptics) return;
    try {
      if (!kIsWeb && _hasVibrator) {
        await Vibration.vibrate(duration: ms);
      } else {
        await fallback();
      }
    } catch (_) {
      // لرزش اختیاری است و نباید بازی را متوقف کند
    }
  }
}
