// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../utils/web_reload.dart';

/// دیالوگ به‌روزرسانی
/// [showCancel] = true  → دو دکمه (بعداً + به‌روزرسانی)
/// [showCancel] = false → فقط دکمه به‌روزرسانی (اجباری)
Future<void> showUpdateDialog(
  BuildContext context, {
  required bool showCancel,
  String? version,
}) {
  return showDialog(
    context: context,
    barrierDismissible: showCancel,
    useRootNavigator: true,
    builder: (dialogCtx) => PopScope(
      canPop: showCancel,
      child: _UpdateDialog(
        showCancel: showCancel,
        version: version,
      ),
    ),
  );
}

/// دیالوگ «نسخه شما به‌روز است»
/// خودکار بعد ۲ ثانیه بسته می‌شود + دکمه باشه
Future<void> showUpToDateDialog(
  BuildContext context, {
  String? version,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (_) => _UpToDateDialog(version: version),
  );
}

// ────────── دیالوگ آپدیت (stateful برای حالت در حال بارگذاری) ──────────

class _UpdateDialog extends StatefulWidget {
  final bool showCancel;
  final String? version;
  const _UpdateDialog({required this.showCancel, this.version});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;

  Future<void> _onUpdate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await reloadWebApp(widget.version);
      // در وب صفحه جایگزین می‌شود و این خط دیگر اجرا نمی‌شود.
    } catch (_) {
      // اگر باز کردن آدرس شکست خورد، کاربر دوباره می‌تواند تلاش کند.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCancel = widget.showCancel;
    final version = widget.version;

    return Dialog(
      backgroundColor: neonPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: neonPalette.accent.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowIcon(
              icon: Icons.rocket_launch_rounded,
              color: neonPalette.accent,
            ),
            const SizedBox(height: 22),
            Text(
              showCancel ? 'نسخه جدید آماده است' : 'به‌روزرسانی الزامی',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: neonPalette.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              version != null
                  ? (showCancel
                      ? 'نسخه‌ی $version با بهبودهای جدید در دسترس است.'
                      : 'نسخه‌ی $version با تغییرات مهم منتشر شده است.\nبرای ادامه، لطفاً به‌روزرسانی کنید.')
                  : 'نسخه جدید در دسترس است.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.7,
                color: neonPalette.textMuted,
              ),
            ),
            const SizedBox(height: 26),
            if (showCancel)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'بعداً',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: neonPalette.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _PrimaryButton(
                      label: 'به‌روزرسانی',
                      busy: _busy,
                      onPressed: _busy ? null : _onUpdate,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: _PrimaryButton(
                  label: 'به‌روزرسانی',
                  busy: _busy,
                  onPressed: _busy ? null : _onUpdate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────── دیالوگ «به‌روز است» ──────────

class _UpToDateDialog extends StatefulWidget {
  final String? version;
  const _UpToDateDialog({this.version});

  @override
  State<_UpToDateDialog> createState() => _UpToDateDialogState();
}

class _UpToDateDialogState extends State<_UpToDateDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: neonPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: neonPalette.accent.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowIcon(
              icon: Icons.check_rounded,
              color: neonPalette.accent,
            ),
            const SizedBox(height: 22),
            Text(
              'نسخه شما به‌روز است',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: neonPalette.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.version != null
                  ? 'شما از آخرین نسخه (${widget.version}) استفاده می‌کنید.'
                  : 'شما از آخرین نسخه استفاده می‌کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.7,
                color: neonPalette.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'باشه',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: neonPalette.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────── اجزای مشترک ──────────

class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _GlowIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.42)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.55),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 42),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPalette.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: neonPalette.accent.withOpacity(0.6),
        disabledForegroundColor: Colors.white70,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
