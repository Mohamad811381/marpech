// نسخه وب: صفحه را با آدرس یکتای جدید باز می‌کند تا index.html و
// فایل‌های بوت از شبکه گرفته شوند، نه از کش.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<void> reloadWebApp(String? version) async {
  final current = Uri.base;
  final query = Map<String, String>.from(current.queryParameters)
    ..['v'] = version ?? 'latest'
    ..['t'] = DateTime.now().millisecondsSinceEpoch.toString();

  html.window.location.replace(
    current.replace(queryParameters: query).toString(),
  );
}