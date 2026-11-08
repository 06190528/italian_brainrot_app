import 'dart:math';

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
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, __) {
                    final t = _shake.value;
                    final angle = sin(t * pi * 12) * 0.25 * (t > 0 && t < 1 ? 1 : 0);
                    return Transform.rotate(angle: angle, child: const _Capsule(size: 200));
                  },
                ),
                const SizedBox(height: 24),
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

class _Capsule extends StatelessWidget {
  final double size;
  const _Capsule({required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CapsulePainter()),
      );
}

class _CapsulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    // イタリア国旗の三色(緑・白・赤)を縦に並べて、円で切り抜く
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final w = s.width / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, s.height), Paint()..color = const Color(0xFF2E9E4F));
    canvas.drawRect(Rect.fromLTWH(w, 0, w, s.height), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(w * 2, 0, w, s.height), Paint()..color = const Color(0xFFD83A33));
    canvas.restore();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.black87;
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c + Offset(-r * 0.45, -r * 0.5), r * 0.14, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
