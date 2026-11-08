// ignore_for_file: invalid_use_of_visible_for_testing_member
// 難易度の目安をとる、ボットによる高速シミュレーション(実機の操作感の代わりではない)。
// 使い方: flutter test tool/balance_sim_test.dart   (結果は print される。アサートは「動くこと」だけ)
// 実際のゲームのコード(BrainrotGame)をそのまま使い、画面を描かずに 1/60 秒ずつ進める。
// ボット: 反応の遅れ(既定0.25秒)ごとに、0.5秒先を予測して、敵から一番遠くなる向きを選ぶ。
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/core/audio_service.dart';
import 'package:italian_brainrot_app/data/character.dart';
import 'package:italian_brainrot_app/features/game/brainrot_game.dart';

final reaction = double.parse(const String.fromEnvironment('REACTION', defaultValue: '0.25')); // ボットの反応の遅れ(秒)。--dart-define=REACTION=0.6 で変える
const maxSeconds = 600.0;
const trials = 8;

class Result {
  final int score;
  final double seconds;
  final bool cleared;
  Result(this.score, this.seconds, this.cleared);
}

Future<Result> play(WidgetTester tester, List<CharacterDef> chars, GameMode mode, int seed) async {
  final session = GameSession();
  int? finalScore;
  var cleared = false;
  final game = BrainrotGame(
    mode: mode,
    characters: chars,
    playerId: 0,
    session: session,
    onGameOver: (s) => finalScore = s,
    onClear: (s) {
      finalScore = s;
      cleared = true;
    },
  );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(width: 393, height: 760, child: GameWidget(game: game)),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
  await tester.pump(const Duration(milliseconds: 16));
  game.start();

  const dt = 1 / 60;
  var t = 0.0, sinceDecision = reaction;
  final rng = Random(seed);
  await tester.runAsync(() async {
    while (finalScore == null && t < maxSeconds) {
      sinceDecision += dt;
      if (sinceDecision >= reaction) {
        sinceDecision = 0;
        _decide(game, rng);
        if (session.deathblows.value > 0 && game.enemies.length >= 4) game.specialMove();
      }
      game.update(dt);
      t += dt;
      if (finalScore == null && session.active.value == false) break;
      // 画像の読み込み(非同期)が進むように、たまに譲る
      if ((t * 60).round() % 6 == 0) await Future<void>.delayed(Duration.zero);
    }
  });
  final r = Result(finalScore ?? session.score.value, t, cleared);
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  return r;
}

void _decide(BrainrotGame g, Random rng) {
  const horizon = 0.5;
  final p = g.debugPlayerPosition;
  final speed = g.enemySpeed * 1.3;
  final size = g.size;
  var best = Dir.none;
  var bestScore = -1e9;
  for (final d in Dir.values) {
    final v = switch (d) {
      Dir.up => Vector2(0, -1),
      Dir.down => Vector2(0, 1),
      Dir.left => Vector2(-1, 0),
      Dir.right => Vector2(1, 0),
      Dir.none => Vector2.zero(),
    } * (speed * horizon);
    final np = (p + v)..clamp(Vector2.all(10), size - Vector2.all(10));
    var minDist = 1e9;
    for (final e in g.enemies) {
      final ev = switch (_dirOf(e)) {
        Dir.up => Vector2(0, -1),
        Dir.down => Vector2(0, 1),
        Dir.left => Vector2(-1, 0),
        Dir.right => Vector2(1, 0),
        Dir.none => Vector2.zero(),
      } * (g.enemySpeed * horizon);
      // 途中の距離も見る(0.5秒の間に近づく)
      for (final f in [0.25, 0.5, 1.0]) {
        final pp = p + (np - p) * f;
        final ee = e.position + ev * f;
        minDist = min(minDist, pp.distanceTo(ee));
      }
    }
    final wall = min(min(np.x, size.x - np.x), min(np.y, size.y - np.y));
    final score = minDist + (wall < 30 ? -40 : 0) + (d == Dir.none ? 3 : 0) + rng.nextDouble();
    if (score > bestScore) {
      bestScore = score;
      best = d;
    }
  }
  g.setDirection(best);
}

Dir _dirOf(dynamic e) => (e as dynamic).dir as Dir;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioService.instance.enabled = false; // テスト環境には音のプラグインが無い

  for (final mode in [GameMode.normal, GameMode.hard]) {
    testWidgets('難易度の目安: ${mode.name}', (tester) async {
      late List<CharacterDef> chars;
      await tester.runAsync(() async => chars = await CharacterRepository.load());
      final results = <Result>[];
      for (var i = 0; i < trials; i++) {
        results.add(await play(tester, chars, mode, i));
      }
      final scores = results.map((r) => r.score).toList()..sort();
      final avgT = results.map((r) => r.seconds).reduce((a, b) => a + b) / results.length;
      final cleared = results.where((r) => r.cleared).length;
      // ignore: avoid_print
      print('[${mode.name}] 反応${reaction}s のボット $trials回: スコア $scores / 平均 ${avgT.toStringAsFixed(0)}秒 / クリア $cleared回');
      expect(scores.isNotEmpty, true);
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
