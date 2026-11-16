// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/core/strings.dart';
import 'package:italian_brainrot_app/data/skill.dart';

void main() {
  setUp(() => S.forceJa = true);

  test('全キャラ(id 0〜109)に、5種類が均等に割り当たる', () {
    final count = <SkillType, int>{};
    for (var id = 0; id < 110; id++) {
      final t = Skill.of(id, 1).type;
      count[t] = (count[t] ?? 0) + 1;
    }
    expect(count.length, 5);
    expect(count.values.every((n) => n == 22), true);
  });

  test('最初のキャラ(id 0)は、見て分かるバリア', () {
    expect(Skill.of(0, 1).type, SkillType.barrier);
  });

  test('レア度が上がるほど強い(★1→★5)', () {
    for (var lv = 1; lv < 5; lv++) {
      final a = Skill(SkillType.barrier, lv), b = Skill(SkillType.barrier, lv + 1);
      expect(b.barrierRegen < a.barrierRegen, true);
      expect(b.magnetRadius > a.magnetRadius, true);
      expect(b.feverMul < a.feverMul, true);
      expect(b.itemEvery < a.itemEvery, true);
      expect(b.bodyScale < a.bodyScale, true);
    }
  });

  test('レア度が範囲外でも、★1〜5に収まる', () {
    expect(Skill.of(3, 0).level, 1);
    expect(Skill.of(3, 9).level, 5);
  });

  test('フィーバーに必要な数: ブースト以外は変わらない', () {
    expect(Skill(SkillType.barrier, 5).feverNeeded(50), 50);
    expect(Skill(SkillType.feverBoost, 1).feverNeeded(50), 46);
    expect(Skill(SkillType.feverBoost, 5).feverNeeded(50), 38);
    expect(Skill(SkillType.feverBoost, 5).feverNeeded(20), 15);
  });

  test('名前と説明が、空でない', () {
    for (final t in SkillType.values) {
      final s = Skill(t, 3);
      expect(s.name.isNotEmpty && s.description.isNotEmpty, true);
    }
  });
}
