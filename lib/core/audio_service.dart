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
  Future<void> gatya() => se('gatya.mp3');
  Future<void> getCharacter() => se('get_character.mp3');
  Future<void> coin() => se('get_coin.mp3');
  Future<void> item() => se('get_item.mp3');
  Future<void> special() => se('special_move.mp3');
  Future<void> hit() => se('hit_1.mp3');
  Future<void> hitSoft() => se('hit_2.mp3');

  static const bgmMain = 'bgm_main.mp3';
  static const bgmFever = 'bgm_fever.mp3';
}
