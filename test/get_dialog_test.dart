import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/core/strings.dart';
import 'package:italian_brainrot_app/data/character.dart';
import 'package:italian_brainrot_app/features/gatya/get_dialog.dart';

/// ガチャ結果の、★の演出。レア度ごとにラベル・色が変わり、小さい画面でも、はみ出さない。
void main() {
  S.forceJa = true;
  final json = jsonDecode(File('assets/data/characters.json').readAsStringSync()) as Map<String, dynamic>;
  final defs = (json['characters'] as List).map((e) => CharacterDef.fromJson(e as Map<String, dynamic>)).toList();

  for (var r = 1; r <= 5; r++) {
    testWidgets('★$r: ラベル・★・名前が出て、小さい画面(360x640)でもはみ出さない', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final def = defs.firstWhere((d) => d.rarity == r);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (ctx) {
        return TextButton(onPressed: () => showDialog(context: ctx, builder: (_) => GetDialog(def: def, isNew: true)), child: const Text('open'));
      }))));
      await t.tap(find.text('open'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('getRarity')), findsOneWidget);
      expect((t.widget(find.byKey(const Key('getRarity'))) as Text).data, S.rarityName(r));
      expect((t.widget(find.byKey(const Key('getRarity'))) as Text).style!.color, rarityColor(r));
      expect(find.byKey(const Key('getStars')), findsOneWidget);
      // ★が出きった後(約1.3秒)も、描画の例外が無い
      await t.pump(const Duration(milliseconds: 1500));
      await t.pump(const Duration(seconds: 5));
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('getOk')), findsOneWidget);
    });
  }

  test('レア度の名前・色が、すべて違う', () {
    expect({for (var r = 1; r <= 5; r++) S.rarityName(r)}.length, 5);
    expect({for (var r = 1; r <= 5; r++) rarityColor(r)}.length, 5);
  });
}
