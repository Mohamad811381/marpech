// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// نوار بالای اپ که وقتی نسخه جدید در دسترس است نمایش داده می‌شود.
///
/// استفاده:
/// ```dart
/// UpdateBanner(onUpdate: () async { ... })
/// ```
class UpdateBanner extends StatelessWidget {
  /// وقتی کاربر روی «به‌روزرسانی» کلیک کرد صدا زده می‌شود.
  final VoidCallback onUpdate;

  /// (اختیاری) متن قابل تنظیم. پیش‌فرض فارسی است.
  final String message;

  /// (اختیاری) متن دکمه.
  final String buttonLabel;

  const UpdateBanner({
    super.key,
    required this.onUpdate,
    this.message = 'نسخه جدید برنامه در دسترس است',
    this.buttonLabel = 'به‌روزرسانی',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.system_update_alt,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onUpdate,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}