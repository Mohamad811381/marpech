import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class SettingsService {
  static const _kSmooth = 'set_smooth';
  static const _kGrid = 'set_grid';
  static const _kParticles = 'set_particles';
  static const _kHaptics = 'set_haptics';
  static const _kSfx = 'set_sfx';
  static const _kMusic = 'set_music';
  static const _kRainbow = 'set_rainbow';
  static const _kShake = 'set_shake';
  static const _kWrap = 'set_wrap';
  static const _kGhost = 'set_ghost';
  static const _kDpad = 'set_dpad';
  static const _kControlType = 'set_control_type';

  static GameSettings _current = const GameSettings();
  static GameSettings get current => _current;

  static Future<GameSettings> load() async {
    final p = await SharedPreferences.getInstance();
    _current = GameSettings(
      smoothMovement: p.getBool(_kSmooth) ?? true,
      showGrid: p.getBool(_kGrid) ?? false,
      particles: p.getBool(_kParticles) ?? true,
      haptics: p.getBool(_kHaptics) ?? true,
      sfx: p.getBool(_kSfx) ?? true,
      music: p.getBool(_kMusic) ?? true,
      rainbow: p.getBool(_kRainbow) ?? true,
      screenShake: p.getBool(_kShake) ?? true,
      wrapEffect: p.getBool(_kWrap) ?? true,
      showGhost: p.getBool(_kGhost) ?? false,
      dpadSize: DPadSize
          .values[(p.getInt(_kDpad) ?? 1).clamp(0, DPadSize.values.length - 1)],
      controlType: ControlType.values[(p.getInt(_kControlType) ?? 0)
          .clamp(0, ControlType.values.length - 1)],
    );
    return _current;
  }

  static Future<void> save(GameSettings s) async {
    _current = s;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSmooth, s.smoothMovement);
    await p.setBool(_kGrid, s.showGrid);
    await p.setBool(_kParticles, s.particles);
    await p.setBool(_kHaptics, s.haptics);
    await p.setBool(_kSfx, s.sfx);
    await p.setBool(_kMusic, s.music);
    await p.setBool(_kRainbow, s.rainbow);
    await p.setBool(_kShake, s.screenShake);
    await p.setBool(_kWrap, s.wrapEffect);
    await p.setBool(_kGhost, s.showGhost);
    await p.setInt(_kDpad, s.dpadSize.index);
    await p.setInt(_kControlType, s.controlType.index);
  }
}
