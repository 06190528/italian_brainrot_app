import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/skill_widgets.dart';
import '../../core/strings.dart';
import '../../data/character.dart';
import '../../core/widgets.dart';
import '../gatya/gatya_screen.dart';
import '../game/brainrot_game.dart';
import '../game/game_screen.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    final chars = ref.watch(charactersProvider);
    final ownedCount = chars.where((c) => user.owned.contains(c.id)).length;
    final current = chars[user.current.clamp(0, chars.length - 1)];

    return Scaffold(
      body: Stack(children: [
        const CoverBackground('assets/images/bg/title.jpg'),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                _Chip(S.collected(ownedCount, chars.length), key: const Key('collectedText')),
                const Spacer(),
                CoinChip(coin: user.coin),
                const SizedBox(width: 8),
                Column(children: [
                  RoundIconButton(key: const Key('gatyaButton'), icon: Icons.card_giftcard, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GatyaScreen()))),
                  OutlinedText(S.gatya, fontSize: 14),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 4, crossAxisSpacing: 4),
                  itemCount: chars.length, // 図鑑: 全キャラの枠を並べる(未所持は「?」と、★・スキルの種類だけ見せる)
                  itemBuilder: (_, i) {
                    final c = chars[i];
                    if (!user.owned.contains(c.id)) return _LockedSlot(key: Key('slot_${c.id}'), def: c);
                    final selected = c.id == user.current;
                    return GestureDetector(
                      key: Key('char_${c.id}'),
                      onTap: () => ref.read(userDataProvider.notifier).select(c.id),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? Colors.redAccent : Colors.transparent, width: 3),
                          color: selected ? Colors.white70 : null,
                        ),
                        child: LayoutBuilder(builder: (_, b) => CharacterView(def: c, size: b.maxWidth)),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedText(S.sortie, fontSize: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CharacterView(key: const Key('currentCharacter'), def: current, size: 96),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    OutlinedText(current.name, fontSize: 15, color: Colors.white),
                    const SizedBox(height: 4),
                    SkillCard(key: const Key('homeSkill'), skill: current.skill),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                RoundIconButton(key: const Key('settingsButton'), icon: Icons.settings, onPressed: () => showDialog(context: context, builder: (_) => const SettingsDialog())),
                const SizedBox(width: 10),
                RoundIconButton(key: const Key('rankingButton'), icon: Icons.leaderboard, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen()))),
                const Spacer(),
                BannerButton(key: const Key('homeStart'), text: S.start, icon: Icons.play_arrow, width: 170, onPressed: () => showDialog(context: context, builder: (_) => const _ModeDialog())),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// 図鑑の、まだ持っていないキャラの枠。「?」と、★(レア度)・スキルの種類だけ見せる(キャラの絵は、読み込まない)。
class _LockedSlot extends StatelessWidget {
  final CharacterDef def;
  const _LockedSlot({super.key, required this.def});

  @override
  Widget build(BuildContext context) {
    final sk = def.skill;
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
      child: LayoutBuilder(
        builder: (_, b) => Stack(alignment: Alignment.center, children: [
          Text('?', style: TextStyle(fontSize: b.maxWidth * 0.5, fontWeight: FontWeight.w900, color: Colors.black38)),
          Positioned(top: 3, left: 3, child: Icon(skillIcon(sk.type), size: b.maxWidth * 0.22, color: skillColor(sk.type))),
          Positioned(
            bottom: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.star, size: b.maxWidth * 0.17, color: Colors.amber.shade700), Text('${def.rarity}', style: TextStyle(fontSize: b.maxWidth * 0.17, fontWeight: FontWeight.w900, color: Colors.black54))],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black87, width: 2)),
        child: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
      );
}

class _ModeDialog extends ConsumerWidget {
  const _ModeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    void go(GameMode m) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(mode: m)));
    }

    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedText(S.selectMode, fontSize: 26),
          const SizedBox(height: 16),
          BannerButton(key: const Key('modeNormal'), text: S.normal, width: 240, onPressed: () => go(GameMode.normal)),
          Text(S.normalDesc(normalGoalScore), style: const TextStyle(color: Colors.black87, fontSize: 12)),
          const SizedBox(height: 14),
          BannerButton(
            key: const Key('modeHard'),
            text: user.hardUnlocked ? S.hard : '${S.hard} (${S.locked})',
            icon: user.hardUnlocked ? null : Icons.lock,
            width: 240,
            color: Colors.deepPurple,
            onPressed: user.hardUnlocked ? () => go(GameMode.hard) : null,
          ),
          Text(S.hardDesc, style: const TextStyle(color: Colors.black87, fontSize: 12)),
        ]),
      ),
    );
  }
}
