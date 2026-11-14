import 'package:shared_preferences/shared_preferences.dart';
import 'platform_detector.dart';

enum GraphicsQuality {
  auto('auto'),
  low('low'),
  medium('medium'),
  high('high');

  final String id;
  const GraphicsQuality(this.id);

  static GraphicsQuality fromId(String? id) =>
      GraphicsQuality.values.firstWhere(
        (g) => g.id == id,
        orElse: () => GraphicsQuality.auto,
      );
}

/// سطوح کیفیت مؤثر (بعد از تشخیص خودکار)
enum EffectiveQuality { low, medium, high }

class PerformanceService {
  static const _key = 'graphics_quality';
  static GraphicsQuality _quality = GraphicsQuality.auto;
  static GraphicsQuality get quality => _quality;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _quality = GraphicsQuality.fromId(p.getString(_key));
  }

  static Future<void> setQuality(GraphicsQuality q) async {
    _quality = q;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, q.id);
  }

  /// کیفیت مؤثر — خودکار بر اساس پلتفرم
  static EffectiveQuality get effective {
    if (_quality == GraphicsQuality.low) return EffectiveQuality.low;
    if (_quality == GraphicsQuality.medium) return EffectiveQuality.medium;
    if (_quality == GraphicsQuality.high) {
      // اگه iOS هست، high هم قابل قبول نیست → medium
      if (PlatformDetector.isIOS) return EffectiveQuality.medium;
      return EffectiveQuality.high;
    }
    // auto:
    if (PlatformDetector.isIOS) return EffectiveQuality.low;
    if (PlatformDetector.isAndroid) {
      return PlatformDetector.cores >= 4
          ? EffectiveQuality.high
          : EffectiveQuality.medium;
    }
    // ویندوز/مک
    return PlatformDetector.cores >= 4
        ? EffectiveQuality.high
        : EffectiveQuality.medium;
  }

  // ─── API برای استفاده در رندر ───

  /// آیا blur فعاله؟
  static bool get blurEnabled => effective != EffectiveQuality.low;

  /// ضریب blur (۱ = کامل، ۰.۵ = نصف، ۰ = صفر)
  static double get blurMultiplier {
    switch (effective) {
      case EffectiveQuality.high:
        return 1.0;
      case EffectiveQuality.medium:
        return 0.55;
      case EffectiveQuality.low:
        return 0.0;
    }
  }

  /// تعداد ذرات (۰ = بدون ذرات)
  static int get particleCount {
    switch (effective) {
      case EffectiveQuality.high:
        return 16;
      case EffectiveQuality.medium:
        return 8;
      case EffectiveQuality.low:
        return 0;
    }
  }

  /// هاله‌های اضافی (مثل هاله‌ی سر مار، نبض غذا)
  static bool get glowEnabled => effective != EffectiveQuality.low;

  /// پترن‌های پیچیده (کهکشان، مارپیچ، موج، کریستال، گلبرگ)
  static bool get complexPatternsEnabled => effective == EffectiveQuality.high;

  /// رد مار با ذرات (نه فقط خط ساده)
  static bool get fancyTrailEnabled => effective == EffectiveQuality.high;

  /// اسکین‌های با افکت پیچیده (شعله، نئون، سایه)
  static bool get fancySkinEnabled => effective != EffectiveQuality.low;
}
