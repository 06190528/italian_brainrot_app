import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:italian_brainrot_app/app/app.dart';
import 'package:italian_brainrot_app/data/user_data.dart';

import 'fakes.dart';

/// ランキング画面: 取得した順位表に、自分の記録が、あるべき位置に入る。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ランキング: 自分が圏内に挿入される・未送信のベストを送る', (tester) async {
    final top = [for (var i = 0; i < 12; i++) {'name': 'Rival${i + 1}', 'score': 200 - i * 15, 'tag': 'r${i.toString().padLeft(3, '0')}'}];
    final fake = FakeRankingTransport(
      json: jsonEncode({
        'version': 1,
        'updatedAt': '2026-11-08T18:17:00Z',
        'total': 12,
        'top': top,
        'scores': [for (final e in top) e['score']],
      }),
    );
    final user = UserData.initial().copyWith(
      name: 'Taro',
      records: [ScoreRecord('Taro', 110, 2, DateTime(2026, 11, 8))],
    );
    await tester.pumpWidget(await buildApp(initialUser: user, overrides: [fakeRanking(fake)]));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('rankingButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // 110 より上は6人(200,185,170,155,140,125)→ 7位。Rival7 も 110 なので同点の7位
    expect(find.byKey(const Key('myRow')), findsOneWidget);
    expect(find.text('あなたの順位: 7位 / 13人'), findsOneWidget);
    expect(find.text('Rival1'), findsOneWidget);
    expect(find.byKey(const Key('rankingUpdated')), findsOneWidget);
    expect(fake.submitted.length, 1, reason: '未送信のベストを送る');
    expect(jsonDecode(fake.submitted.single)['fields']['score']['integerValue'], '110');
    await binding.takeScreenshot('20_ranking');

    await tester.tap(find.byKey(const Key('rankingBack')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('homeStart')), findsOneWidget);
  });
}
