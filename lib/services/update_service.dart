// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// سرویس بررسی نسخه جدید اپ (مخصوص Flutter Web).
///
/// نحوه کار:
/// 1. در شروع، نسخه فعلی را از version.json می‌خواند و ذخیره می‌کند.
/// 2. سپس هر [interval] یک بار، دوباره version.json را می‌خواند.
/// 3. اگر مقدار تغییر کرده بود، [onUpdateAvailable] را صدا می‌زند.
///
/// نکته: از query string یکتا استفاده می‌شود تا کش مرورگر/شبکه دور زده شود.
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Callback وقتی نسخه جدید پیدا شد.
  /// پارامتر: نسخه جدید (مثلاً "1712345678").
  void Function(String newVersion)? onUpdateAvailable;

  /// نسخه‌ای که اپ با آن لود شده (اولین بار ذخیره می‌شود).
  String? _currentVersion;

  /// آیا نسخه جدید در دسترس است؟
  bool get hasUpdate => _updateAvailable;
  bool _updateAvailable = false;

  Timer? _timer;

  /// شروع بررسی دوره‌ای.
  void start({Duration interval = const Duration(minutes: 2)}) {
    _timer?.cancel();
    // اولین بررسی فوری
    _check();
    // سپس دوره‌ای
    _timer = Timer.periodic(interval, (_) => _check());
  }

  /// توقف بررسی دوره‌ای.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// بررسی دستی (مثلاً از دکمه «بررسی آپدیت»).
  Future<void> checkNow() => _check();

  Future<void> _check() async {
    try {
      // query string یکتا برای دور زدن کش مرورگر/شبکه
      final uri = Uri.parse(
        'app-version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await http.get(
        uri,
        headers: const {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[UpdateService] status=${response.statusCode}');
        }
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersion = data['version']?.toString();
      if (remoteVersion == null || remoteVersion.isEmpty) return;

      if (kDebugMode) {
        debugPrint(
          '[UpdateService] current=$_currentVersion remote=$remoteVersion',
        );
      }

      // اولین بار → ذخیره نسخه فعلی، آپدیت نیست
      if (_currentVersion == null) {
        _currentVersion = remoteVersion;
        return;
      }

      // اگر نسخه جدیدتر دید → آپدیت موجود است
      if (remoteVersion != _currentVersion && !_updateAvailable) {
        _updateAvailable = true;
        onUpdateAvailable?.call(remoteVersion);
      }
    } catch (e) {
      // خطای شبکه/تایم‌اوت را نادیده بگیر (بررسی بعدی)
      if (kDebugMode) {
        debugPrint('[UpdateService] error: $e');
      }
    }
  }
}
