import '../core/strings.dart';

/// キャラごとのスキルの種類。並びの先頭がバリア = id 0(最初から持っているキャラ)は、必ずバリアになる。
enum SkillType { barrier, magnet, feverBoost, luckyDrop, miniBody }

/// スキル = 種類(id % 5)+ 強さ(レア度 1〜5)。全キャラが1つ持つ。強さの差は小さく抑える(ランキングの公平性のため)。
class Skill {
  final SkillType type;
  final int level; // 1〜5(= レア度)
  const Skill(this.type, this.level);

  static const int typeCount = 5;

  factory Skill.of(int id, int rarity) =>
      Skill(SkillType.values[id % typeCount], rarity.clamp(1, 5));

  int get _i => level - 1;

  /// バリア: 何体かわすと再生するか。
  int get barrierRegen => const [320, 295, 270, 245, 220][_i];

  /// マグネット: アイテムを引き寄せる半径(画面の幅に対する割合)。
  double get magnetRadius => const [0.22, 0.26, 0.30, 0.34, 0.38][_i];

  /// フィーバーブースト: フィーバーに必要な数にかける倍率。
  double get feverMul => const [0.92, 0.88, 0.84, 0.80, 0.76][_i];

  /// ラッキードロップ: 何体かわすごとにアイテムが出るか(標準は15)。
  int get itemEvery => const [14, 13, 12, 11, 10][_i];

  /// ちびボディ: キャラの大きさにかける倍率。
  double get bodyScale => const [0.92, 0.89, 0.86, 0.83, 0.80][_i];

  /// フィーバーに必要な数(スキルがフィーバーブーストなら、少なくなる)。
  int feverNeeded(int base) => type == SkillType.feverBoost ? (base * feverMul).round() : base;

  static const int defaultItemEvery = 15;

  String get name => switch (type) {
        SkillType.barrier => S.skillBarrier,
        SkillType.magnet => S.skillMagnet,
        SkillType.feverBoost => S.skillFeverBoost,
        SkillType.luckyDrop => S.skillLuckyDrop,
        SkillType.miniBody => S.skillMiniBody,
      };

  String get description => switch (type) {
        SkillType.barrier => S.skillBarrierDesc(barrierRegen),
        SkillType.magnet => S.skillMagnetDesc((magnetRadius * 100).round()),
        SkillType.feverBoost => S.skillFeverBoostDesc(((1 - feverMul) * 100).round()),
        SkillType.luckyDrop => S.skillLuckyDropDesc(itemEvery),
        SkillType.miniBody => S.skillMiniBodyDesc(((1 - bodyScale) * 100).round()),
      };
}
