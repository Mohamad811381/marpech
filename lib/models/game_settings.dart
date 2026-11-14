enum DPadSize { small, medium, large }

extension DPadSizeExt on DPadSize {
  String get label {
    switch (this) {
      case DPadSize.small:
        return 'کوچک';
      case DPadSize.medium:
        return 'متوسط';
      case DPadSize.large:
        return 'بزرگ';
    }
  }

  double get pixels {
    switch (this) {
      case DPadSize.small:
        return 170;
      case DPadSize.medium:
        return 210;
      case DPadSize.large:
        return 260;
    }
  }
}

/// نوع کنترل بازی
enum ControlType { dpad, joystick }

class GameSettings {
  final bool smoothMovement;
  final bool showGrid;
  final bool particles;
  final bool haptics;
  final bool sfx;
  final bool music;
  final bool rainbow;
  final bool screenShake;
  final bool wrapEffect;
  final bool showGhost;
  final DPadSize dpadSize;
  final ControlType controlType; // ← جدید

  const GameSettings({
    this.smoothMovement = true,
    this.showGrid = true,
    this.particles = true,
    this.haptics = true,
    this.sfx = true,
    this.music = true,
    this.rainbow = false,
    this.screenShake = true,
    this.wrapEffect = true,
    this.showGhost = true,
    this.dpadSize = DPadSize.medium,
    this.controlType = ControlType.dpad, // ← پیش‌فرض
  });

  GameSettings copyWith({
    bool? smoothMovement,
    bool? showGrid,
    bool? particles,
    bool? haptics,
    bool? sfx,
    bool? music,
    bool? rainbow,
    bool? screenShake,
    bool? wrapEffect,
    bool? showGhost,
    DPadSize? dpadSize,
    ControlType? controlType,
  }) {
    return GameSettings(
      smoothMovement: smoothMovement ?? this.smoothMovement,
      showGrid: showGrid ?? this.showGrid,
      particles: particles ?? this.particles,
      haptics: haptics ?? this.haptics,
      sfx: sfx ?? this.sfx,
      music: music ?? this.music,
      rainbow: rainbow ?? this.rainbow,
      screenShake: screenShake ?? this.screenShake,
      wrapEffect: wrapEffect ?? this.wrapEffect,
      showGhost: showGhost ?? this.showGhost,
      dpadSize: dpadSize ?? this.dpadSize,
      controlType: controlType ?? this.controlType,
    );
  }
}
