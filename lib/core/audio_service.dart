import 'package:flame_audio/flame_audio.dart';

/// BGM・効果音の再生。端末で再生に失敗してもゲームは止めない。
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool enabled = true;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    _initialized = true;
  }

  Future<void> _safe(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {}
  }

  Future<void> playBgm(String file, {double volume = 0.6}) => _safe(() async {
        if (!enabled) return;
        await FlameAudio.bgm.stop();
        await FlameAudio.bgm.play(file, volume: volume);
      });

  Future<void> stopBgm() => _safe(() => FlameAudio.bgm.stop());
  Future<void> pauseBgm() => _safe(() => FlameAudio.bgm.pause());
  Future<void> resumeBgm() => _safe(() async {
        if (enabled) await FlameAudio.bgm.resume();
      });

  Future<void> se(String file, {double volume = 1.0}) => _safe(() async {
        if (!enabled) return;
        await FlameAudio.play(file, volume: volume);
      });

  // 名前つきの効果音(ファイル名の差し替えはここだけ)
  Future<void> explosion() => se('explosion.mp3');
  Future<void> clear() => se('game_clear.mp3');
  Future<void> gatya() => se('gatyaSound.mp3');
  Future<void> getCharacter() => se('getCharacter.mp3');
  Future<void> coin() => se('getCoinSound.mp3');
  Future<void> item() => se('getItemSound.mp3');
  Future<void> special() => se('specialMove.mp3');
  Future<void> hit() => se('goat_sounds1.mp3');
}
