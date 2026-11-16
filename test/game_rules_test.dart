// ignore_for_file: invalid_use_of_visible_for_testing_member
// ゲームのルール(スキルの効果)のテスト。BrainrotGame を、画面を描かずに1/60秒ずつ進める。
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/core/audio_service.dart';
import 'package:italian_brainrot_app/data/character.dart';
import 'package:italian_brainrot_app/features/game/brainrot_game.dart';

class _Run {
  final BrainrotGame game;
  final List<int> over;
  _Run(this.game, this.over);
}

Future<_Run> _boot(WidgetTester tester, List<CharacterDef> chars, int playerId, {GameMode mode = GameMode.hard}) async {
  final over = <int>[];
  final game = BrainrotGame(
    mode: mode,
    characters: chars,
    playerId: playerId,
    session: GameSession(),
    onGameOver: over.add,
    onClear: over.add,
  )..autoSpawn = false;
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(width: 393, height: 760, child: GameWidget(game: game)),
  ));
  for (var i = 0; i < 300 && !game.isLoaded; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 16));
  expect(game.isLoaded, true);
  game.start();
  // 自機の読み込み(スプライト)を待つ
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  return _Run(game, over);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioService.instance.enabled = false;
  late List<CharacterDef> chars;

  setUpAll(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async => chars = await CharacterRepository.load());
  });

  /// 自機の真上に敵を出して、1コマ進める(触れる)。
  Future<void> touch(WidgetTester tester, BrainrotGame g) async {
    g.debugSpawnEnemy(g.debugPlayerPosition, Dir.right, kind: 1);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200))); // 敵の読み込み
    g.debugTick(0.05);
  }

  testWidgets('バリア: 1回かばい、割れた直後の1秒は無敵で、そのあとの接触で終わる', (tester) async {
    final r = await _boot(tester, chars, 0);
    final g = r.game;
    expect(g.session.barrier.value, true, reason: 'id0 はバリアで始まる');
    await touch(tester, g);
    expect(r.over, isEmpty, reason: '1回目はかばう');
    expect(g.session.barrier.value, false);
    expect(g.invulnerable, true);
    await touch(tester, g);
    expect(r.over, isEmpty, reason: '無敵の間は、触れても終わらない');
    g.debugTick(1.2);
    expect(g.invulnerable, false);
    await touch(tester, g);
    expect(r.over.length, 1, reason: '無敵が切れたあとの接触で終わる');
  });

  testWidgets('バリア: 規定数かわすと再生する(★1は110体)', (tester) async {
    final r = await _boot(tester, chars, 0);
    final g = r.game;
    await touch(tester, g);
    expect(g.session.barrier.value, false);
    g.debugAdvanceBarrier(109);
    expect(g.session.barrier.value, false);
    expect(g.session.barrierProgress.value, closeTo(109 / 110, 1e-9));
    g.debugAdvanceBarrier(1);
    expect(g.session.barrier.value, true);
  });

  testWidgets('スキルなし(useSkill=false)なら、1回触れて終わる', (tester) async {
    final over = <int>[];
    final game = BrainrotGame(
      mode: GameMode.hard, characters: chars, playerId: 0, session: GameSession(),
      onGameOver: over.add, onClear: over.add, useSkill: false,
    )..autoSpawn = false;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 393, height: 760, child: GameWidget(game: game)),
    ));
    for (var i = 0; i < 300 && !game.isLoaded; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    game.start();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    expect(game.session.barrier.value, false);
    await touch(tester, game);
    expect(over.length, 1);
  });

  testWidgets('フィーバーブースト: ★1でハード46・ノーマル18(id 2)、他のスキルは50・20', (tester) async {
    final fb = await _boot(tester, chars, 2);
    expect(fb.game.feverNeeded, 46);
    final fbN = await _boot(tester, chars, 2, mode: GameMode.normal);
    expect(fbN.game.feverNeeded, 18);
    final other = await _boot(tester, chars, 0);
    expect(other.game.feverNeeded, 50);
  });

  testWidgets('ラッキードロップ: アイテムの間隔(id 3 は14、それ以外は標準15)', (tester) async {
    expect((await _boot(tester, chars, 3)).game.itemEvery, 14);
    expect((await _boot(tester, chars, 0)).game.itemEvery, 15);
  });

  testWidgets('ちびボディ: 自機が小さくなる(id 4 は ★1で92%)', (tester) async {
    final small = await _boot(tester, chars, 4);
    final base = await _boot(tester, chars, 0);
    expect(small.game.player.size.x / base.game.player.size.x, closeTo(0.92, 0.001));
  });

  testWidgets('マグネット: 範囲内のアイテムだけが、自機へ寄る(id 1)', (tester) async {
    final r = await _boot(tester, chars, 1);
    final g = r.game;
    expect(g.magnetRadiusPx, closeTo(0.22 * g.size.x, 0.5));
    // 範囲の内側(半径の半分)
    final inside = g.debugAddItem(g.debugPlayerPosition + Vector2(g.magnetRadiusPx / 2, 0));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    g.debugTick(0.1);
    expect(g.debugItemDistance(), lessThan(inside - 5), reason: '範囲内は、横に引き寄せられる(落下だけでは縮まらない)');
    // マグネットなしのキャラ(id 0)は、同じ位置でも、横へは寄らない
    final base = await _boot(tester, chars, 0);
    final d0 = base.game.debugAddItem(base.game.debugPlayerPosition + Vector2(base.game.size.x * 0.11, 0));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    base.game.debugTick(0.1);
    expect(base.game.debugItemDistance(), greaterThanOrEqualTo(d0 - 1));
  });
}
