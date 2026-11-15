// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// نتیجه‌ی بررسی آپدیت.
/// - [upToDate]: کاربر آخرین نسخه را دارد.
/// - [optional]: نسخه‌ی جدیدتر هست ولی اجباری نیست (می‌تواند «بعداً» بزند).
/// - [force]: نسخه‌ی کاربر پایین‌تر از حداقل مجاز است → اجبار به آپدیت.
/// - [error]: اتصال برقرار نشد یا پاسخ معتبر نبود.
enum UpdateCheckResult { upToDate, optional, force, error }

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// نسخه‌ی تزریق‌شده در build.
  /// CI: `flutter build web --dart-define=APP_VERSION=$SEMVER`
  /// Dev: `flutter run -d chrome --dart-define=APP_VERSION=1.0.4`
  /// اگر در dev تزریق نکنی، خالی است و چک انجام نمی‌شود (بی‌خطر).
  static const String buildVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '');

  // ───── state (پس از آخرین چک) ─────

  String? _localVersion;
  String? _latestVersion;
  String? _minVersion;
  bool _isChecking = false;

  String? get localVersion => _localVersion;
  String? get latestVersion => _latestVersion;
  String? get minVersion => _minVersion;

  // ───── public API ─────

  /// بررسی آپدیت. تنها متد عمومی است.
  /// روی موبایل همیشه [UpdateCheckResult.upToDate] برمی‌گرداند.
  Future<UpdateCheckResult> checkNow() async {
    if (!kIsWeb) return UpdateCheckResult.upToDate;
    if (_isChecking) return UpdateCheckResult.upToDate;
    _isChecking = true;

    try {
      // ۱) نسخه‌ی local را بگیر
      // ۱) نسخه‌ی local را بگیر
      const local = buildVersion;
      if (local.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[UpdateService] APP_VERSION not set; skipping check. '
            'Use --dart-define=APP_VERSION=x.y.z',
          );
        }
        return UpdateCheckResult.upToDate;
      }
      _localVersion = local;

      // ۲) پاسخ سرور را بگیر
      final data = await _fetchRemote();
      if (data == null) return UpdateCheckResult.error;

      final latest = data['latest']?.toString();
      final minVersion = data['min_version']?.toString();
      if (latest == null || latest.isEmpty) {
        if (kDebugMode) {
          debugPrint('[UpdateService] response missing "latest" field');
        }
        return UpdateCheckResult.error;
      }

      _latestVersion = latest;
      _minVersion = minVersion;

      if (kDebugMode) {
        debugPrint(
          '[UpdateService] local=$local latest=$latest min=$minVersion',
        );
      }

      // ۳) تصمیم بر اساس min_version
      final effectiveMin = (minVersion != null && minVersion.isNotEmpty)
          ? minVersion
          : latest; // اگر min_version نبود، پیش‌فرض «آخرین» است (یعنی هیچ‌وقت force نمی‌شود)

      final cmpLatest = compareSemver(local, latest);
      final cmpMin = compareSemver(local, effectiveMin);

      if (cmpLatest >= 0) {
        return UpdateCheckResult.upToDate;
      }
      if (cmpMin < 0) {
        return UpdateCheckResult.force;
      }
      return UpdateCheckResult.optional;
    } catch (e) {
      if (kDebugMode) debugPrint('[UpdateService] error: $e');
      return UpdateCheckResult.error;
    } finally {
      _isChecking = false;
    }
  }

  // ───── helpers ─────

  Future<Map<String, dynamic>?> _fetchRemote() async {
    if (!kIsWeb) return null;
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

  /// مقایسه‌ی SemVer عددی.
  /// خروجی > 0 یعنی [a] جدیدتر از [b].
  /// پشتیبانی: `x.y.z` و `x.y.z+build`. پیش‌نسخه‌ها (`-beta`) پشتیبانی نمی‌شوند.
  static int compareSemver(String a, String b) {
    List<int> parse(String v) {
      final core = v.split('+').first;
      return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    }

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
