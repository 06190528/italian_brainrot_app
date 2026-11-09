import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:italian_brainrot_app/data/character.dart';

/// キャラのシート定義(characters.json)と、画像ファイルの整合性。
/// ここが崩れると、読み込み時に例外になる(コマ数 < 列数 など)。
void main() {
  final json = jsonDecode(File('assets/data/characters.json').readAsStringSync()) as Map<String, dynamic>;
  final defs = (json['characters'] as List).map((e) => CharacterDef.fromJson(e as Map<String, dynamic>)).toList();

  test('キャラが、連番のIDで揃っている', () {
    expect(defs.length, greaterThanOrEqualTo(51));
    expect([for (final d in defs) d.id], [for (var i = 0; i < defs.length; i++) i]);
  });

  test('シートの定義が、Flameの条件を満たす(コマ数 >= 列数、行数に収まる)', () {
    for (final d in defs) {
      expect(d.frames, greaterThanOrEqualTo(1), reason: '${d.id} ${d.slug}');
      expect(d.cols, greaterThanOrEqualTo(1), reason: '${d.id} ${d.slug}');
      expect(d.frames, greaterThanOrEqualTo(d.cols), reason: '${d.id} ${d.slug}: コマ数が列数より少ない');
      expect(d.frames, lessThanOrEqualTo(d.cols * d.rows), reason: '${d.id} ${d.slug}: コマがシートに収まらない');
      expect(d.stepTime, greaterThan(0));
    }
  });

  test('シートの画像ファイルがある', () {
    for (final d in defs) {
      expect(File('assets/images/${d.sheet}').existsSync(), true, reason: '${d.id} ${d.slug}: ${d.sheet}');
    }
  });

  test('名前が空でない', () {
    for (final d in defs) {
      expect(d.name.trim(), isNotEmpty, reason: '${d.id}');
    }
  });
}
