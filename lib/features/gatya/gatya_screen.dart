import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/ads/reward_ad.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
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
            // 元アプリと同じ: 画面の高さの半分のガチャ機を中央に置き、ボタンは下に置く
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

/// 元アプリの GatyaUi と同じ: gatya.png(5列×2行=10コマ)。待機は2コマ目、回す時は0.1秒ごとに10コマ全部。
class _GatyaMachine extends StatefulWidget {
  final Animation<double> anim; // 0〜1(1600ms)。回している間だけ動く
  final double height;
  const _GatyaMachine({required this.anim, required this.height});

  @override
  State<_GatyaMachine> createState() => _GatyaMachineState();
}

class _GatyaMachineState extends State<_GatyaMachine> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    Flame.images.load('orig/gatya.png').then((i) {
      if (mounted) setState(() => _image = i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return SizedBox(height: widget.height);
    final fw = (img.width - 3) / 5, fh = (img.height + 10) / 2; // 元アプリの切り出しと同じ
    return AnimatedBuilder(
      animation: widget.anim,
      builder: (_, __) {
        final t = widget.anim.value;
        final spinning = t > 0 && t < 1;
        final frame = spinning ? min(9, (t * 1600 / 100).floor()) : (t >= 1 ? 9 : 1);
        return CustomPaint(
          size: Size(widget.height * fw / fh, widget.height),
          painter: _GatyaPainter(img, frame, fw, fh),
        );
      },
    );
  }
}

class _GatyaPainter extends CustomPainter {
  final ui.Image image;
  final int frame;
  final double fw, fh;
  _GatyaPainter(this.image, this.frame, this.fw, this.fh);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH((frame % 5) * fw, (frame ~/ 5) * fh, fw, fh);
    canvas.drawImageRect(image, src, Offset.zero & size, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_GatyaPainter old) => old.frame != frame || old.image != image;
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
          const SizedBox(height: 12),
          BannerButton(key: const Key('getOk'), text: S.ok, width: 160, onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
