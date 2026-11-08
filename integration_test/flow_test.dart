import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:italian_brainrot_app/app/app.dart';
import 'package:italian_brainrot_app/data/user_data.dart';
import 'package:italian_brainrot_app/features/game/brainrot_game.dart';

/// 画面にアニメーション(キャラ・Flame)が常にあるので、pumpAndSettle の代わりに時間で待つ。
Future<void> settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
}

/// ホーム → ガチャ → ノーマルをプレイ(スワイプ・必殺技・結果) の通し確認。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('通し: ガチャ→プレイ→結果', (tester) async {
    await tester.pumpWidget(await buildApp(initialUser: UserData.initial()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('homeStart')), findsOneWidget);

    // ガチャ: 20コイン → 2回回せる
    await tester.tap(find.byKey(const Key('gatyaButton')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('gatyaSpin')));
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('getTitle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('getOk')));
    await settle(tester);
    expect(find.text('10'), findsWidgets); // 残りコイン
    await tester.tap(find.byKey(const Key('gatyaBack')));
    await settle(tester);

    // ノーマル開始
    await tester.tap(find.byKey(const Key('homeStart')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('modeNormal')));
    // ゲーム画面はFlameが動き続けるので pumpAndSettle は使わない
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('startButton')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('scoreText')), findsOneWidget);

    final game = BrainrotGame.debugInstance!;
    game.autoSpawn = false; // 敵は、このテストが決めた位置にだけ出す

    // スワイプで右に動く
    final before = game.debugPlayerPosition;
    await tester.drag(find.byType(GameWidget<BrainrotGame>), const Offset(120, 0));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.debugPlayerPosition.x, greaterThan(before.x), reason: 'スワイプで右に動く');

    // 画面外に出た敵 → スコア+1
    game.debugSpawnEnemy(Vector2(game.size.x - 2, 40), Dir.right);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.session.score.value, 1);

    // 必殺技で、画面の敵を全部消してスコアに足す
    game.debugSpawnEnemy(Vector2(10, 100), Dir.right);
    game.debugSpawnEnemy(Vector2(10, 140), Dir.right);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('specialButton')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.session.score.value, 3);
    expect(game.enemies, isEmpty);

    // 敵に触れてゲームオーバー
    game.debugSpawnEnemy(game.debugPlayerPosition, Dir.down);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('resultTitle')), findsOneWidget);
    expect(find.byKey(const Key('resultScore')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resultHome')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('homeStart')), findsOneWidget);
  });
}
