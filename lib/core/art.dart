import 'dart:math';
import 'package:flutter/material.dart';

/// コードで描く図形(画像素材を使わない)。ゲームの部品と、画面のアイコンで共有する。

/// 金色の星(アイテム・必殺ボタン)。[rot] はラジアン。
void paintStar(Canvas canvas, Offset c, double r, {double rot = 0}) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rad = i.isEven ? r : r * 0.45;
    final a = rot - pi / 2 + i * pi / 5;
    final p = Offset(c.dx + cos(a) * rad, c.dy + sin(a) * rad);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  path.close();
  canvas.drawCircle(c, r * 1.15, Paint()..color = const Color(0x55FFD54F)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  canvas.drawPath(path, Paint()..color = const Color(0xFFFFC107));
  canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF8F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeJoin = StrokeJoin.round);
  canvas.drawCircle(c, r * 0.18, Paint()..color = const Color(0xFFFFF8E1));
}

/// フィーバー中のオーラ。[c] はオーラの中心、[t] は経過秒(脈動)。
void paintAura(Canvas canvas, Offset c, double r, double t) {
  for (var i = 0; i < 3; i++) {
    final k = (t * 0.9 + i / 3) % 1.0;
    final rad = r * (0.5 + k * 0.7);
    canvas.drawCircle(
        c,
        rad,
        Paint()
          ..color = Color.fromARGB(((1 - k) * 150).toInt(), 255, 167, 38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12 * (1 - k * 0.5));
  }
  canvas.drawCircle(c, r * 0.55, Paint()..color = const Color(0x44FFEB3B)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
}

/// バリア(泡)。自機を包む水色の球。
void paintBarrier(Canvas canvas, Offset c, double r, double t) {
  final pulse = 1 + sin(t * 4) * 0.04;
  canvas.drawCircle(c, r * pulse, Paint()..color = const Color(0x3329B6F6));
  canvas.drawCircle(
      c,
      r * pulse,
      Paint()
        ..color = const Color(0xCC4FC3F7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  canvas.drawArc(Rect.fromCircle(center: c, radius: r * pulse * 0.78), pi * 1.1, pi * 0.35, false,
      Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
}

/// マグネットの範囲(点線の輪)。
void paintMagnetRing(Canvas canvas, Offset c, double r, double t) {
  const n = 36;
  final paint = Paint()
    ..color = const Color(0x66E040FB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  for (var i = 0; i < n; i += 2) {
    final a0 = t * 0.6 + i * 2 * pi / n;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, 2 * pi / n, false, paint);
  }
}

/// 敵の種類の目印(回る点線の輪)。
void paintEnemyRing(Canvas canvas, Offset c, double r, Color color, double t) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 8; i++) {
    final a0 = t * 2 + i * pi / 4;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, pi / 6, false, paint);
  }
}

/// 「!」(追尾の敵が出た合図)。
void paintBang(Canvas canvas, Offset c, double h) {
  final paint = Paint()
    ..color = const Color(0xFFE53935)
    ..strokeWidth = h * 0.22
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(c.dx, c.dy - h / 2), Offset(c.dx, c.dy + h * 0.1), paint);
  canvas.drawCircle(Offset(c.dx, c.dy + h * 0.4), h * 0.12, paint);
}

/// 星だけを描くアイコン(ボタン用)。
class StarIcon extends StatelessWidget {
  final double size;
  const StarIcon({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) => paintStar(canvas, s.center(Offset.zero), s.width * 0.42);
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
