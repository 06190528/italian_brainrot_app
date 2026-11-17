import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/skill_widgets.dart';
import '../../core/strings.dart';
import '../../core/widgets.dart';
import '../../data/character.dart';

/// レア度ごとの色(★1 灰 / ★2 緑 / ★3 青 / ★4 紫 / ★5 金)。
Color rarityColor(int r) => switch (r) {
      1 => const Color(0xFF9E9E9E),
      2 => const Color(0xFF43A047),
      3 => const Color(0xFF1E88E5),
      4 => const Color(0xFF8E24AA),
      _ => const Color(0xFFFFB300),
    };

/// ガチャの結果。★を1つずつ弾ませて出し、レア度が高いほど、色・光の放射・きらめき・ラベルが派手になる。
/// (★1・2は控えめ / ★3は光の放射 / ★4はきらめき / ★5は金色の縁と、強い光)
class GetDialog extends StatefulWidget {
  final CharacterDef def;
  final bool isNew;
  /// 演出の開始位置(秒)。撮影用(テストの時計は実時間より遅いので、★が出きった状態を撮るのに使う)。ふだんは0
  final double startSeconds;
  const GetDialog({super.key, required this.def, required this.isNew, this.startSeconds = 0});

  @override
  State<GetDialog> createState() => _GetDialogState();
}

class _GetDialogState extends State<GetDialog> with SingleTickerProviderStateMixin {
  // 0〜1。★が順に出る(約1.4秒)あと、光の放射が回り続ける(止まる処理を持たない長い1本。画面を閉じれば終わる)
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30), value: widget.startSeconds / 30)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int get _r => widget.def.rarity;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(_r);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final sec = _c.value * 30; // 経過秒
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: _r >= 4 ? 7 : (_r >= 3 ? 5 : 3)),
              boxShadow: [if (_r >= 3) BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 12.0 + _r * 6, spreadRadius: _r.toDouble())],
            ),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              OutlinedText(widget.isNew ? S.newCharacter : S.duplicate, key: const Key('getTitle'), fontSize: 26),
              const SizedBox(height: 4),
              _StarsReveal(rarity: _r, sec: sec, color: color),
              const SizedBox(height: 2),
              Text(S.rarityName(_r),
                  key: const Key('getRarity'),
                  style: TextStyle(fontSize: 16.0 + _r * 2, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              const SizedBox(height: 6),
              SizedBox(
                width: 176,
                height: 176,
                child: Stack(alignment: Alignment.center, children: [
                  if (_r >= 3) Positioned.fill(child: CustomPaint(painter: _RaysPainter(color: color, rotation: sec * 0.35, strength: _r))),
                  if (_r >= 4) Positioned.fill(child: CustomPaint(painter: _SparklePainter(color: color, sec: sec, count: _r == 5 ? 18 : 10))),
                  CharacterView(def: widget.def, size: 140),
                ]),
              ),
              Text(widget.def.name, key: const Key('getName'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 8),
              SkillCard(skill: widget.def.skill),
              const SizedBox(height: 12),
              BannerButton(key: const Key('getOk'), text: S.ok, width: 160, onPressed: () => Navigator.pop(context)),
            ])),
          );
        },
      ),
    );
  }
}

/// ★を左から順に、拡大しながら弾ませて出す。取れていない★(5つまでの残り)は、薄く出す。
class _StarsReveal extends StatelessWidget {
  final int rarity;
  final double sec;
  final Color color;
  const _StarsReveal({required this.rarity, required this.sec, required this.color});

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    const stagger = 0.22; // ★ひとつずつの出現の間隔(秒)
    return SizedBox(
      key: const Key('getStars'),
      height: size + 8,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 5; i++)
          Builder(builder: (_) {
            final got = i < rarity;
            final p = ((sec - 0.15 - i * stagger) / 0.45).clamp(0.0, 1.0); // この★の出現の進み
            final scale = got ? Curves.elasticOut.transform(p) : p;
            return Transform.scale(
              scale: scale,
              child: Icon(Icons.star,
                  size: size,
                  color: got ? (rarity == 5 ? const Color(0xFFFFC107) : Colors.amber) : Colors.black12,
                  shadows: got ? [Shadow(color: color.withValues(alpha: 0.9), blurRadius: 8 + rarity * 2.0)] : null),
            );
          }),
      ]),
    );
  }
}

/// キャラの後ろの、放射状の光。ゆっくり回る。
class _RaysPainter extends CustomPainter {
  final Color color;
  final double rotation;
  final int strength; // 3〜5。大きいほど、光の筋が多く濃い
  _RaysPainter({required this.color, required this.rotation, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final n = 6 + strength * 2; // 光の筋の数
    final paint = Paint()..color = color.withValues(alpha: 0.18 + strength * 0.05);
    for (var i = 0; i < n; i++) {
      final a = rotation + i * 2 * pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), a, pi / n, false)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(c, r * 0.55, Paint()..color = color.withValues(alpha: 0.14)); // 中心の光
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.rotation != rotation;
}

/// ★4・5の、キャラのまわりのきらめき(小さな星が、ふくらんで消えるのをくり返す)。
class _SparklePainter extends CustomPainter {
  final Color color;
  final double sec;
  final int count;
  _SparklePainter({required this.color, required this.sec, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(5);
    for (var i = 0; i < count; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final d = 0.35 + rng.nextDouble() * 0.6; // 中心からの距離(半径に対する割合)
      final period = 0.9 + rng.nextDouble() * 0.8;
      final phase = rng.nextDouble() * period;
      final t = ((sec + phase) % period) / period; // 0〜1
      final s = sin(t * pi); // ふくらんで消える
      final pos = size.center(Offset.zero) + Offset(cos(a), sin(a)) * (size.width / 2 * d);
      _star(canvas, pos, 4 + 9 * s, Paint()..color = Color.lerp(Colors.white, color, 0.3)!.withValues(alpha: s));
    }
  }

  /// 4つの角を持つ、きらめきの形
  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.sec != sec;
}
