// نسخه وب: Service Worker جدید را فعال + صفحه را reload می‌کند.
// این فایل فقط برای وب کامپایل می‌شود.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// ignore_for_file: unnecessary_null_comparison, unnecessary_null_aware_operator, invalid_null_aware_operator

import 'dart:html' as html;

Future<void> reloadWebApp() async {
  try {
    // نکته مهم:
    // getRegistration() در dart:html باگ دارد: در dev mode (بدون SW) مقدار null
    // برمی‌گرداند ولی امضای تایپ non-nullable است → TypeError.
    // راه‌حل: از getRegistrations() استفاده می‌کنیم که List برمی‌گرداند (حتی خالی).
    final sw = html.window.navigator.serviceWorker;
    final regs = await sw?.getRegistrations();
    if (regs != null && regs.isNotEmpty) {
      final waiting = regs.first.waiting;
      if (waiting != null) {
        waiting.postMessage({'type': 'SKIP_WAITING'});
        // کمی صبر کن تا SW جدید activate شود
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  } catch (_) {
    // اگر SW در دسترس نبود (dev mode، incognito)، باز هم reload می‌کنیم
  }

  // reload کامل صفحه
  html.window.location.reload();
}