import 'package:flutter/material.dart';

import '../data/skill.dart';

/// スキルの種類ごとのアイコン・色。
IconData skillIcon(SkillType t) => switch (t) {
      SkillType.barrier => Icons.shield,
      SkillType.magnet => Icons.radar,
      SkillType.feverBoost => Icons.bolt,
      SkillType.luckyDrop => Icons.auto_awesome,
      SkillType.miniBody => Icons.compress,
    };

Color skillColor(SkillType t) => switch (t) {
      SkillType.barrier => const Color(0xFF29B6F6),
      SkillType.magnet => const Color(0xFFAB47BC),
      SkillType.feverBoost => const Color(0xFFFF7043),
      SkillType.luckyDrop => const Color(0xFFFFCA28),
      SkillType.miniBody => const Color(0xFF66BB6A),
    };

/// ★の並び(レア度)。
class Stars extends StatelessWidget {
  final int count;
  final double size;
  const Stars(this.count, {super.key, this.size = 14});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < 5; i++) Icon(Icons.star, size: size, color: i < count ? Colors.amber : Colors.black26)],
      );
}

/// スキルの説明カード(開始前・ガチャ結果・ホームで使う)。
class SkillCard extends StatelessWidget {
  final Skill skill;
  final bool dark;
  const SkillCard({super.key, required this.skill, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : Colors.black87;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: skillColor(skill.type), width: 3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 22, backgroundColor: skillColor(skill.type), child: Icon(skillIcon(skill.type), color: Colors.white, size: 26)),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
              Text(skill.name, key: const Key('skillName'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: fg)),
              Stars(skill.level, size: 14),
            ]),
            Text(skill.description, key: const Key('skillDesc'), style: TextStyle(fontSize: 12, color: fg)),
          ]),
        ),
      ]),
    );
  }
}

/// ゲーム中のHUDに出す、小さなスキル表示。
class SkillChip extends StatelessWidget {
  final Skill skill;
  const SkillChip({super.key, required this.skill});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: skillColor(skill.type), width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(skillIcon(skill.type), color: skillColor(skill.type), size: 20),
          const SizedBox(width: 4),
          Text(skill.name, key: const Key('hudSkill'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      );
}
