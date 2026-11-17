import 'dart:math';

import 'character.dart';

/// ガチャで、レア度(★1〜5)ごとに当たる確率(%)。合計100。
/// 高いレア度ほど出にくい。★5は、1回あたり7%(キャラ1体あたりは、約0.35%)。
const Map<int, int> gatyaRarityPercent = {1: 30, 2: 28, 3: 23, 4: 12, 5: 7};

/// ガチャの1回分の抽選。先にレア度を、gatyaRarityPercent の確率で決め、そのレア度のキャラから、等しい確率で1体選ぶ。
/// (レア度ごとのキャラ数が変わっても、レア度ごとの確率は変わらない。いないレア度は、飛ばして残りで割り直す)
CharacterDef drawCharacter(List<CharacterDef> chars, Random rng) {
  final byRarity = <int, List<CharacterDef>>{};
  for (final c in chars) {
    byRarity.putIfAbsent(c.rarity, () => []).add(c);
  }
  final tiers = [for (final e in byRarity.entries) if ((gatyaRarityPercent[e.key] ?? 0) > 0) e.key];
  if (tiers.isEmpty) return chars[rng.nextInt(chars.length)]; // 重みの定義にないレア度だけの時は、均等
  final total = tiers.fold<int>(0, (s, r) => s + gatyaRarityPercent[r]!);
  var x = rng.nextInt(total);
  for (final r in tiers) {
    x -= gatyaRarityPercent[r]!;
    if (x < 0) {
      final list = byRarity[r]!;
      return list[rng.nextInt(list.length)];
    }
  }
  throw StateError('unreachable');
}
