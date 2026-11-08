import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart';

/// assets/data/characters.json の1件。並び順(id)が、敵の出現順=強さの順。
class CharacterDef {
  final int id;
  final String slug;
  final String name;
  final int rarity;
  final String sheet; // assets/images/ からの相対パス
  final int cols;
  final int rows;
  final int frames;
  final double stepTime;

  const CharacterDef({
    required this.id,
    required this.slug,
    required this.name,
    required this.rarity,
    required this.sheet,
    required this.cols,
    required this.rows,
    required this.frames,
    required this.stepTime,
  });

  factory CharacterDef.fromJson(Map<String, dynamic> j) => CharacterDef(
        id: j['id'] as int,
        slug: j['slug'] as String,
        name: j['name'] as String,
        rarity: (j['rarity'] ?? 1) as int,
        sheet: j['sheet'] as String,
        cols: (j['cols'] ?? 1) as int,
        rows: (j['rows'] ?? 1) as int,
        frames: (j['frames'] ?? 1) as int,
        stepTime: ((j['stepTime'] ?? 0.1) as num).toDouble(),
      );

  /// スプライトシートからアニメーションを作る(画像はFlameのキャッシュ)。
  Future<SpriteAnimation> loadAnimation() async {
    final image = await Flame.images.load(sheet);
    final frameSize = Vector2(image.width / cols, image.height / rows);
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        amountPerRow: cols,
        stepTime: stepTime,
        textureSize: frameSize,
      ),
    );
  }
}

class CharacterRepository {
  static Future<List<CharacterDef>> load() async {
    final raw = await rootBundle.loadString('assets/data/characters.json');
    final list = (jsonDecode(raw)['characters'] as List)
        .map((e) => CharacterDef.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }
}
