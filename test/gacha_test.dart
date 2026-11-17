import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/data/character.dart';
import 'package:italian_brainrot_app/data/gacha.dart';

/// ガチャの抽選が、レア度ごとの確率(gatyaRarityPercent)どおりに偏ること。
void main() {
  final json = jsonDecode(File('assets/data/characters.json').readAsStringSync()) as Map<String, dynamic>;
  final defs = (json['characters'] as List).map((e) => CharacterDef.fromJson(e as Map<String, dynamic>)).toList();

  test('確率の合計が100で、実際のキャラのレア度がすべて定義にある', () {
    expect(gatyaRarityPercent.values.fold<int>(0, (a, b) => a + b), 100);
    for (final d in defs) {
      expect(gatyaRarityPercent.containsKey(d.rarity), true, reason: '${d.id}: ★${d.rarity}');
    }
  });

  test('高いレア度ほど出にくい(確率が単調に減る)', () {
    for (var r = 1; r < 5; r++) {
      expect(gatyaRarityPercent[r]!, greaterThan(gatyaRarityPercent[r + 1]!));
    }
  });

  test('10万回引くと、レア度ごとの出現率が、定義の確率に近い(±1ポイント)', () {
    final rng = Random(1);
    const n = 100000;
    final count = <int, int>{};
    for (var i = 0; i < n; i++) {
      final r = drawCharacter(defs, rng).rarity;
      count[r] = (count[r] ?? 0) + 1;
    }
    gatyaRarityPercent.forEach((r, pct) {
      expect((count[r] ?? 0) / n * 100, closeTo(pct, 1.0), reason: '★$r');
    });
  });

  test('同じレア度の中では、どのキャラも出る(均等)', () {
    final rng = Random(2);
    final seen = <int>{};
    for (var i = 0; i < 100000; i++) {
      seen.add(drawCharacter(defs, rng).id);
    }
    expect(seen.length, defs.length);
  });

  test('いないレア度は飛ばして、残りで引ける', () {
    final only1 = defs.where((d) => d.rarity == 1).toList();
    expect(drawCharacter(only1, Random(3)).rarity, 1);
  });
}
