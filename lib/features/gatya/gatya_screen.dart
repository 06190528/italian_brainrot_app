import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/ads/reward_ad.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../core/skill_widgets.dart';
import '../../core/strings.dart';
import '../../core/widgets.dart';
import '../../data/character.dart';

class GatyaScreen extends ConsumerStatefulWidget {
  const GatyaScreen({super.key});

  @override
  ConsumerState<GatyaScreen> createState() => _GatyaScreenState();
}

class _GatyaScreenState extends ConsumerState<GatyaScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _spinning = false;
  final _rng = Random();

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final notifier = ref.read(userDataProvider.notifier);
    if (_spinning || !notifier.spendCoins(gatyaCost)) return;
    setState(() => _spinning = true);
    AudioService.instance.gatya();
    await _shake.forward(from: 0);
    final chars = ref.read(charactersProvider);
    final got = chars[_rng.nextInt(chars.length)];
    final isNew = notifier.unlock(got.id);
    AudioService.instance.getCharacter();
    if (!mounted) return;
    setState(() => _spinning = false);
    await showDialog(context: context, builder: (_) => _GetDialog(def: got, isNew: isNew));
    if (mounted) _shake.value = 0; // 待機のコマに戻す
  }

  Future<void> _watchAd() async {
    final ok = await RewardAd.show(() => ref.read(userDataProvider.notifier).addCoins(adRewardCoins));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.adNotReady)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(userDataProvider).coin;
    final can = coin >= gatyaCost;
    return Scaffold(
      body: Stack(children: [
        const CoverBackground('assets/images/bg/title.jpg'),
        SafeArea(
          child: Stack(children: [
            Positioned(top: 12, left: 12, child: RoundIconButton(key: const Key('gatyaBack'), icon: Icons.arrow_back, onPressed: () => Navigator.pop(context))),
            Positioned(top: 12, right: 12, child: CoinChip(coin: coin)),
            // 画面の高さの半分のガチャ機を中央に置き、ボタンは下に置く
            Center(child: _GatyaMachine(anim: _shake, height: MediaQuery.of(context).size.height / 2)),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height * 0.12,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (can || _spinning)
                  BannerButton(
                    key: const Key('gatyaSpin'),
                    text: S.gatyaByCoins(gatyaCost),
                    icon: Icons.monetization_on,
                    width: 280,
                    onPressed: _spinning ? null : _spin,
                  )
                else ...[
                  OutlinedText(S.notEnoughCoins, fontSize: 24, color: Colors.white),
                  const SizedBox(height: 12),
                  BannerButton(key: const Key('gatyaAd'), text: S.watchAdForCoins, icon: Icons.ondemand_video, width: 280, color: Colors.green, onPressed: _watchAd),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// ガチャ機(コード描画)。透明のドームに、色とりどりのカプセル。回している間は、カプセルが跳ねて、つまみが回る。
class _GatyaMachine extends StatelessWidget {
  final Animation<double> anim; // 0〜1(1600ms)。回している間だけ動く
  final double height;
  const _GatyaMachine({required this.anim, required this.height});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (_, __) => CustomPaint(
          size: Size(height * 0.72, height),
          painter: _GatyaPainter(anim.value),
        ),
      );
}

class _GatyaPainter extends CustomPainter {
  final double t; // 0=待機 / 0〜1=回転中 / 1=終了
  _GatyaPainter(this.t);

  static const _colors = [
    Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFFFDD835), Color(0xFF8E24AA),
    Color(0xFFFB8C00), Color(0xFF00ACC1), Color(0xFFD81B60), Color(0xFF7CB342), Color(0xFF5E35B1),
    Color(0xFFF4511E), Color(0xFF3949AB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final spinning = t > 0 && t < 1;
    // 本体(下の箱)
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.55, w * 0.84, h * 0.42), Radius.circular(w * 0.08));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFC62828));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF7F0000)..style = PaintingStyle.stroke..strokeWidth = 4);
    // 取り出し口
    final chute = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, h * 0.82, w * 0.4, h * 0.11), Radius.circular(w * 0.04));
    canvas.drawRRect(chute, Paint()..color = const Color(0xFF3E0000));
    // つまみ
    final knobC = Offset(w * 0.5, h * 0.68);
    canvas.drawCircle(knobC, w * 0.13, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(knobC, w * 0.13, Paint()..color = const Color(0xFF8D6E00)..style = PaintingStyle.stroke..strokeWidth = 3);
    final ang = spinning ? t * 4 * pi : 0.0;
    canvas.drawLine(knobC + Offset(cos(ang), sin(ang)) * (w * 0.1), knobC - Offset(cos(ang), sin(ang)) * (w * 0.1),
        Paint()..color = const Color(0xFF8D6E00)..strokeWidth = 6..strokeCap = StrokeCap.round);
    // ドーム
    final domeC = Offset(w * 0.5, h * 0.33);
    final domeR = w * 0.46;
    canvas.drawCircle(domeC, domeR, Paint()..color = const Color(0x33B3E5FC));
    // カプセル(ドームの中)。回している間は跳ねる
    final rng = Random(11);
    for (var i = 0; i < _colors.length; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final d = sqrt(rng.nextDouble()) * (domeR * 0.68);
      var c = domeC + Offset(cos(a), sin(a)) * d;
      if (spinning) c += Offset(sin(t * 40 + i * 1.7), cos(t * 33 + i * 2.3)) * (w * 0.03);
      final r = w * 0.085;
      canvas.drawCircle(c, r, Paint()..color = _colors[i]);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi, pi, true, Paint()..color = Colors.white.withValues(alpha: 0.35));
      canvas.drawCircle(c, r, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    canvas.drawCircle(domeC, domeR, Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 5);
    // 土台との境目
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.55, w * 0.6, h * 0.03), Paint()..color = const Color(0xFF7F0000));
  }

  @override
  bool shouldRepaint(_GatyaPainter old) => old.t != t;
}

class _GetDialog extends StatelessWidget {
  final CharacterDef def;
  final bool isNew;
  const _GetDialog({required this.def, required this.isNew});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedText(isNew ? S.newCharacter : S.duplicate, key: const Key('getTitle'), fontSize: 26),
          const SizedBox(height: 8),
          CharacterView(def: def, size: 160),
          Text(def.name, key: const Key('getName'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 8),
          SkillCard(skill: def.skill),
          const SizedBox(height: 12),
          BannerButton(key: const Key('getOk'), text: S.ok, width: 160, onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
