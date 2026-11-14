import 'package:flutter/foundation.dart';

class PlatformDetector {
  static bool _initialized = false;
  static bool _isIOS = false;
  static bool _isAndroid = false;
  static int _cores = 4;

  static bool get isIOS {
    if (!_initialized) _detect();
    return _isIOS;
  }

  static bool get isAndroid {
    if (!_initialized) _detect();
    return _isAndroid;
  }

  static bool get isMobile => isIOS || isAndroid;

  static int get cores {
    if (!_initialized) _detect();
    return _cores;
  }

  static void _detect() {
    _initialized = true;
    _isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    _isAndroid = defaultTargetPlatform == TargetPlatform.android;
    _cores = 4;
  }
}