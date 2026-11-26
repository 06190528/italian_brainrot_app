import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:italian_brainrot_app/app/app.dart';
import 'package:italian_brainrot_app/core/ads/reward_ad.dart';
import 'package:italian_brainrot_app/core/constants.dart';
import 'package:italian_brainrot_app/data/user_data.dart';

Future<void> toGatya(WidgetTester t) async {
  await t.pumpWidget(await buildApp(initialUser: UserData.initial().copyWith(coin: 0)));
  await t.pump(const Duration(seconds: 1));
  await t.tap(find.byKey(const Key('gatyaButton')));
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
}

/// リワード広告(テスト広告)の、待ち画面・キャンセル・事前読み込みの確認。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  adsHiddenForTests = true;

  testWidgets('読み込み中は待ち画面が出て、キャンセルで閉じる', (tester) async {
    await toGatya(tester);
    await tester.tap(find.byKey(const Key('gatyaAd')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('adCancel')), findsOneWidget);
    await binding.takeScreenshot('ad_loading');
    await tester.tap(find.byKey(const Key('adCancel')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('adCancel')), findsNothing);
    expect(find.byKey(const Key('gatyaAd')), findsOneWidget);
  });

  testWidgets('事前に読み込んでおけば、待ち画面なしで広告が出る', (tester) async {
    await toGatya(tester);
    RewardAd.preload();
    final ad = await tester.runAsync(() => RewardAd.acquire());
    expect(ad, isNotNull, reason: 'テスト広告が読み込めた');
    await tester.tap(find.byKey(const Key('gatyaAd')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('adCancel')), findsNothing);
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3))); // 広告の表示(ネイティブ)を待つ
  });
}
