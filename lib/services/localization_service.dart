import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._();
  LocalizationService._();

  static const _prefsKey = 'app_language';
  static const supported = ['fa', 'en'];

  String _lang = 'fa';
  String get lang => _lang;
  bool get isFa => _lang == 'fa';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _lang = p.getString(_prefsKey) ?? 'fa';
    if (!supported.contains(_lang)) _lang = 'fa';
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (lang == _lang) return;
    if (!supported.contains(lang)) return;
    _lang = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, lang);
    notifyListeners();
  }

  String tr(String key) {
    return translations[_lang]?[key] ??
        translations['fa']?[key] ??
        key;
  }

  TextDirection get textDirection =>
      _lang == 'fa' ? TextDirection.rtl : TextDirection.ltr;
}

// /// دسترسی راحت — همه‌جا `L10n.t('key')`
// class L10n {
//   static String t(String key) => LocalizationService.instance.tr(key);
//   static TextDirection get dir =>
//       LocalizationService.instance.textDirection;
//   static bool get isFa => LocalizationService.instance.isFa;
// }
class L10n {
  static String t(String key) => LocalizationService.instance.tr(key);

  /// جایگزینی placeholder: L10n.tf('game_score_label', {'n': 5})
  static String tf(String key, Map<String, dynamic> vars) {
    var s = LocalizationService.instance.tr(key);
    vars.forEach((k, v) {
      s = s.replaceAll('{$k}', '$v');
    });
    return s;
  }

  static TextDirection get dir =>
      LocalizationService.instance.textDirection;
  static bool get isFa => LocalizationService.instance.isFa;
}