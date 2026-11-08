import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:italian_brainrot_app/app/app.dart';
import 'package:italian_brainrot_app/data/user_data.dart';
import 'package:italian_brainrot_app/features/game/brainrot_game.dart';

import 'fakes.dart';

/// ハードモードを、敵を避けるボットで長めに遊ぶ(クラッシュ・フィーバー・ポーズの確認)。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ハード: ボットで30秒プレイ・フィーバー・ポーズ', (tester) async {
    final user = UserData.initial().copyWith(
      owned: {0, 1, 2, 3, 4, 5, 6, 7},
      current: 3,
      records: [ScoreRecord('t', 300, 1, DateTime(2026, 11, 8))],
    );
    final fake = FakeRankingTransport();
    await tester.pumpWidget(await buildApp(initialUser: user, overrides: [fakeRanking(fake)]));
    // 画像の読み込み(エンジン側の非同期処理)は、pump では進まない。実時間で待つ。
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('10_home_owned');
    for (var k = 0; k < 3; k++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await binding.takeScreenshot('10b_home_owned_later');
    debugPrint('Image widgets: ${find.byType(Image).evaluate().length}, '
        'CharacterView: ${find.byKey(const Key('currentCharacter')).evaluate().length}');

    await tester.tap(find.byKey(const Key('homeStart')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('modeHard')));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('startButton')));
    await tester.pump(const Duration(milliseconds: 500));
    final game = BrainrotGame.debugInstance!;

    // フィーバー: あと1点で発動する状態にして、画面外に出る敵を1体通す
    game.session.feverCount.value = game.feverNeeded - 1;
    game.autoSpawn = false;
    game.debugSpawnEnemy(Vector2(game.size.x - 2, 40), Dir.right);
    for (var i = 0; i < 20 && !game.session.fever.value; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.session.fever.value, true, reason: 'フィーバーが始まる');
    await tester.pump(const Duration(milliseconds: 300)); // 画面の描画を待つ
    await binding.takeScreenshot('12_fever');

    // ポーズ → 再開
    await tester.tap(find.byKey(const Key('pauseButton')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('resumeButton')), findsOneWidget);
    await binding.takeScreenshot('13_pause');
    await tester.tap(find.byKey(const Key('resumeButton')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.session.active.value, true);

    game.autoSpawn = true;

    // ボット: 一番近い敵から遠ざかる向きに動く
    var steps = 0;
    for (; steps < 60; steps++) {
      if (find.byKey(const Key('resultTitle')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
      final p = game.debugPlayerPosition;
      double best = double.infinity;
      Vector2? near;
      for (final e in game.enemies) {
        final d = e.position.distanceTo(p);
        if (d < best) {
          best = d;
          near = e.position;
        }
      }
      if (near != null && best < game.size.y / 4) {
        final dx = p.x - near.x, dy = p.y - near.y;
        game.setDirection(dx.abs() > dy.abs() ? (dx > 0 ? Dir.right : Dir.left) : (dy > 0 ? Dir.down : Dir.up));
      }
      if (steps == 20) await binding.takeScreenshot('11_hard_play');
    }
    debugPrint('ボットのスコア: ${game.session.score.value} (steps=$steps)');

  });
}
