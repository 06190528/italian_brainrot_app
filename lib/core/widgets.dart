import 'package:flame/sprite.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

import '../data/character.dart';

/// 縁取りつきの文字。
class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final Color outline;
  const OutlinedText(this.text,
      {super.key,
      this.fontSize = 20,
      this.color = const Color(0xFFFFC001),
      this.outline = Colors.black});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900);
    return Stack(children: [
      Text(text,
          style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.18
                ..strokeJoin = StrokeJoin.round
                ..color = outline)),
      Text(text, style: style.copyWith(color: color)),
    ]);
  }
}

/// 大きな丸ボタン。
class BannerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double width;
  final Color color;
  const BannerButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.icon,
      this.width = 220,
      this.color = const Color(0xFFE53935)});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 6)],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  const RoundIconButton({super.key, required this.icon, required this.onPressed, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black87, width: 2),
        ),
        child: Icon(icon, color: Colors.black87, size: size * 0.55),
      ),
    );
  }
}

/// コインの残高表示。
class CoinChip extends StatelessWidget {
  final int coin;
  const CoinChip({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/images/ui/coin.png', width: 24, height: 24),
        const SizedBox(width: 6),
        Text('$coin', key: const Key('coinText'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
      ]),
    );
  }
}

/// キャラ1体のアニメーション表示。
class CharacterView extends StatefulWidget {
  final CharacterDef def;
  final double size;
  const CharacterView({super.key, required this.def, required this.size});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  SpriteAnimation? _anim;
  SpriteAnimationTicker? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CharacterView old) {
    super.didUpdateWidget(old);
    if (old.def.id != widget.def.id) {
      _anim = null;
      _load();
    }
  }

  Future<void> _load() async {
    final def = widget.def;
    final a = await def.loadAnimation();
    if (!mounted || def.id != widget.def.id) return;
    setState(() {
      _anim = a;
      _ticker = a.createTicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _anim == null
          ? null
          : SpriteAnimationWidget(
              animation: _anim!,
              animationTicker: _ticker!,
              anchor: Anchor.center,
            ),
    );
  }
}

/// 背景画像(画面いっぱいにcover)。
class CoverBackground extends StatelessWidget {
  final String asset;
  const CoverBackground(this.asset, {super.key});

  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: Image.asset(asset, fit: BoxFit.cover));
}
