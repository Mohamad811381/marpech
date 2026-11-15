// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// نتیجه‌ی بررسی دستی آپدیت
enum UpdateCheckResult { hasUpdate, upToDate, error }

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  void Function(String newVersion)? onUpdateAvailable;

  String? _currentVersion;
  bool get hasUpdate => _updateAvailable;
  bool _updateAvailable = false;

  /// نسخه‌ی معنایی remote (مثلاً "1.0.1") — از فیلد semantic می‌آید
  String? get remoteSemanticVersion => _remoteSemanticVersion;
  String? _remoteSemanticVersion;

  /// آخرین نسخه‌ی معنایی که از سرور خوانده شد (برای نمایش در UI)
  String? get semanticVersion => _remoteSemanticVersion;

  /// نسخه‌ی فعلی که اپ با آن لود شده (fallback)
  String? get currentVersion => _currentVersion;

  Timer? _timer;

  void start({Duration interval = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// بررسی دستی — نتیجه را برای UI برمی‌گرداند
  Future<UpdateCheckResult> checkNow() => _checkWithResult();

  Future<void> _check() async {
    await _checkWithResult();
  }

  Future<UpdateCheckResult> _checkWithResult() async {
    try {
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
        return UpdateCheckResult.error;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteSemantic = data['semantic']?.toString();
      if (remoteSemantic != null && remoteSemantic.isNotEmpty) {
        _remoteSemanticVersion = remoteSemantic;
      }
      final remoteVersion = data['version']?.toString();
      if (remoteVersion == null || remoteVersion.isEmpty) {
        return UpdateCheckResult.error;
      }

      if (kDebugMode) {
        debugPrint(
          '[UpdateService] current=$_currentVersion remote=$remoteVersion',
        );
      }

      if (_currentVersion == null) {
        _currentVersion = remoteVersion;
        return UpdateCheckResult.upToDate;
      }

      if (remoteVersion != _currentVersion) {
        if (!_updateAvailable) {
          _updateAvailable = true;
          onUpdateAvailable?.call(remoteVersion);
        }
        return UpdateCheckResult.hasUpdate;
      }

      return UpdateCheckResult.upToDate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateService] error: $e');
      }
      return UpdateCheckResult.error;
    }
  }
}
