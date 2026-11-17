import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

enum Sfx { eat, gameOver, newRecord, button }

class AudioService {
  AudioService._();
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;

  final AudioPlayer _sfx = AudioPlayer(playerId: 'marpech_sfx');
  final AudioPlayer _music = AudioPlayer(playerId: 'marpech_music');

  bool _initialized = false;
  bool _unlocked = false;
  bool _wantsMusic = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _sfx.setReleaseMode(ReleaseMode.stop);
    await _music.setReleaseMode(ReleaseMode.loop);
    await _sfx.setVolume(0.75);
    await _music.setVolume(0.25);
    try {
      final ctx = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await _sfx.setAudioContext(ctx);
      await _music.setAudioContext(ctx);
    } catch (e) {
      if (kDebugMode) debugPrint('🔊 AudioContext error: $e');
    }
  }

  /// با اولین تعامل کاربر صدا زده می‌شود (فقط روی وب لازم است)
  Future<void> unlock() async {
    if (_unlocked) return;
    _unlocked = true;
    if (_wantsMusic) await startMusic();
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!SettingsService.current.sfx) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(_assetFor(sfx)));
    } catch (e) {
      if (kDebugMode) debugPrint('🔇 SFX error (${sfx.name}): $e');
    }
  }

  Future<void> startMusic() async {
    _wantsMusic = true;
    if (!SettingsService.current.music) return;
    if (kIsWeb && !_unlocked) return;
    try {
      if (_music.state == PlayerState.playing) return;
      if (_music.state == PlayerState.paused) {
        await _music.resume();
      } else {
        await _music.play(AssetSource('audio/music.mp3'));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🎵 Music error: $e');
    }
  }

  Future<void> pauseMusic() async {
    try {
      if (_music.state == PlayerState.playing) await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() => startMusic();

  Future<void> stopMusic() async {
    _wantsMusic = false;
    try {
      await _music.stop();
    } catch (_) {}
  }

  Future<void> onSettingsChanged() async {
    if (SettingsService.current.music) {
      await startMusic();
    } else {
      await pauseMusic();
    }
  }

  String _assetFor(Sfx s) {
    switch (s) {
      case Sfx.eat:
        return 'audio/eat.mp3';
      case Sfx.gameOver:
        return 'audio/game_over.mp3';
      case Sfx.newRecord:
        return 'audio/new_record.mp3';
      case Sfx.button:
        return 'audio/button.mp3';
    }
  }
}
