// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// نتیجه‌ی بررسی آپدیت.
/// - [upToDate]: کاربر آخرین نسخه را دارد (یا چک روی موبایل/بدون نسخه).
/// - [optional]: نسخه‌ی جدیدتر هست ولی اجباری نیست.
/// - [force]: نسخه‌ی کاربر پایین‌تر از min_version است.
/// - [error]: اتصال برقرار نشد یا پاسخ معتبر نبود.
enum UpdateCheckResult { upToDate, optional, force, error }

final RegExp _semverPattern = RegExp(r'^\d+\.\d+\.\d+$');

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// نسخه‌ی semver تزریق‌شده در build (CI از pubspec می‌خواند).
  static const String buildVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '');

  /// شماره‌ی build (بخش بعد از +) که از pubspec می‌آید.
  static const String buildNumber =
      String.fromEnvironment('APP_BUILD', defaultValue: '');

  String? _localVersion;
  String? _latestVersion;
  String? _minVersion;
  Future<UpdateCheckResult>? _inFlight;

  String? get localVersion => _localVersion;
  String? get latestVersion => _latestVersion;
  String? get minVersion => _minVersion;

  /// بررسی آپدیت. اگر چکی در جریان باشد، همان Future برگردانده می‌شود
  /// (نه نتیجه‌ی ساختگی «به‌روز است»).
  Future<UpdateCheckResult> checkNow() {
    if (!kIsWeb) return Future.value(UpdateCheckResult.upToDate);
    return _inFlight ??= _check().whenComplete(() => _inFlight = null);
  }

  Future<UpdateCheckResult> _check() async {
    try {
      const local = buildVersion;
      if (!_semverPattern.hasMatch(local)) {
        if (kDebugMode) {
          debugPrint(
            '[UpdateService] APP_VERSION not set or invalid; skipping check.',
          );
        }
        return UpdateCheckResult.upToDate;
      }
      _localVersion = local;

      final data = await _fetchRemote();
      if (data == null) return UpdateCheckResult.error;

      final latest = (data['latest'] ?? '').toString();
      final minRaw = (data['min_version'] ?? '').toString();
      if (!_semverPattern.hasMatch(latest)) {
        if (kDebugMode) {
          debugPrint('[UpdateService] invalid or missing "latest"');
        }
        return UpdateCheckResult.error;
      }

      _latestVersion = latest;
      // اگر min_version نامعتبر یا خالی باشد، اجباری وجود ندارد.
      final min = _semverPattern.hasMatch(minRaw) ? minRaw : null;
      _minVersion = min;

      if (kDebugMode) {
        debugPrint('[UpdateService] local=$local latest=$latest min=$min');
      }

      if (compareSemver(local, latest) >= 0) return UpdateCheckResult.upToDate;
      if (min != null && compareSemver(local, min) < 0) {
        return UpdateCheckResult.force;
      }
      return UpdateCheckResult.optional;
    } catch (e) {
      if (kDebugMode) debugPrint('[UpdateService] error: $e');
      return UpdateCheckResult.error;
    }
  }

  Future<Map<String, dynamic>?> _fetchRemote() async {
    try {
      final uri = Uri.parse(
        'app-version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final r = await http.get(
        uri,
        headers: const {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final decoded = jsonDecode(r.body);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (e) {
      if (kDebugMode) debugPrint('[UpdateService] fetch error: $e');
      return null;
    }
  }

  /// مقایسه‌ی semver عددی. خروجی > 0 یعنی [a] جدیدتر است.
  static int compareSemver(String a, String b) {
    List<int> parse(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final pa = parse(a);
    final pb = parse(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
