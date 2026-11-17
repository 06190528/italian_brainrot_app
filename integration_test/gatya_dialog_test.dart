import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:italian_brainrot_app/core/strings.dart';
import 'package:italian_brainrot_app/data/character.dart';
import 'package:italian_brainrot_app/features/gatya/get_dialog.dart';

/// ガチャ結果の演出を、レア度ごとに撮影する(build/shots/gatya_dialog_r<レア度>_<秒>.png)。目視確認用。
/// 使い方: flutter drive --no-pub --driver=test_driver/integration_test.dart --target=integration_test/gatya_dialog_test.dart -d <UDID>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  S.forceJa = true;

  testWidgets('レア度ごとの結果ダイアログ', (tester) async {
    final json = jsonDecode(await rootBundle.loadString('assets/data/characters.json')) as Map<String, dynamic>;
    final defs = (json['characters'] as List).map((e) => CharacterDef.fromJson(e as Map<String, dynamic>)).toList();
    for (final r in [1, 3, 4, 5]) {
      final def = defs.firstWhere((d) => d.rarity == r);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (ctx) {
        return Center(child: TextButton(onPressed: () => showDialog(context: ctx, builder: (_) => GetDialog(def: def, isNew: true, startSeconds: 3)), child: const Text('open')));
      }))));
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await Future<void>.delayed(const Duration(milliseconds: 500)); // ★が出ている途中
      await tester.pump(const Duration(milliseconds: 16));
      await binding.takeScreenshot('gatya_dialog_r${r}_a');
      await Future<void>.delayed(const Duration(seconds: 3)); // 実時間で待つ(★が出きったあと)
      await tester.pump(const Duration(milliseconds: 16));
      await binding.takeScreenshot('gatya_dialog_r${r}_b');
      await tester.tap(find.byKey(const Key('getOk')));
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
