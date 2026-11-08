import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:italian_brainrot_app/data/ranking_service.dart';
import 'package:italian_brainrot_app/data/user_data.dart';

class FakeTransport implements RankingTransport {
  String? text;
  int patchCode = 200;
  final patches = <(Uri, String)>[];

  @override
  Future<String?> getText(Uri url) async => text;

  @override
  Future<int> patchJson(Uri url, String body) async {
    patches.add((url, body));
    return patchCode;
  }
}

RankingData data({List<int>? scores, List<List<int>>? cum, int total = 0, List<RankingEntry>? top}) =>
    RankingData(
      total: total,
      top: top ?? [for (var i = 0; i < 5; i++) RankingEntry('P$i', 100 - i * 10, 'a$i')],
      scores: scores,
      cum: cum,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('composeBoard', () {
    test('圏内: 自分が、あるべき位置に入る', () {
      final b = composeBoard(data(), myTag: 'zzzz', myName: 'me', myScore: 75);
      expect(b.rows.map((r) => r.score), [100, 90, 80, 75, 70, 60]);
      expect(b.rows.map((r) => r.rank), [1, 2, 3, 4, 5, 6]);
      expect(b.rows[3].isMe, true);
      expect(b.me!.rank, 4);
      expect(b.meInRows, true);
    });

    test('同点は同じ順位', () {
      final b = composeBoard(data(), myTag: 'zzzz', myName: 'me', myScore: 90);
      expect(b.me!.rank, 2);
      expect(b.rows.where((r) => r.score == 90).map((r) => r.rank), [2, 2]);
      expect(b.rows.last.rank, 6);
    });

    test('自分の古い行(tag一致)は取り除かれる', () {
      final b = composeBoard(data(), myTag: 'a2', myName: 'me', myScore: 95);
      expect(b.rows.where((r) => r.score == 80), isEmpty);
      expect(b.rows.length, 5);
      expect(b.me!.rank, 2);
    });

    test('スコア0は載せない', () {
      final b = composeBoard(data(), myTag: 'zzzz', myName: 'me', myScore: 0);
      expect(b.me, isNull);
      expect(b.rows.length, 5);
    });

    test('100位圏外: 下に別で出し、順位は全員のスコアから数える', () {
      final top = [for (var i = 0; i < 100; i++) RankingEntry('P$i', 1000 - i, 't$i')];
      final all = [...top.map((e) => e.score), for (var i = 0; i < 400; i++) 900 - 5 * i ~/ 3 - 100];
      all.sort((a, b) => b.compareTo(a));
      final b = composeBoard(data(top: top, scores: all, total: all.length), myTag: 'zzzz', myName: 'me', myScore: 500);
      expect(b.meInRows, false);
      expect(b.rows.length, 100);
      expect(b.me!.rank, all.where((s) => s > 500).length + 1);
      expect(b.total, all.length);
    });
  });

  group('countGreater(概算)', () {
    final cum = [
      [1, 1000],
      [11, 500],
      [21, 100],
    ];
    test('しきい値ちょうど・間・範囲外', () {
      final d = data(cum: cum);
      expect(d.countGreater(0), 1000); // score >= 1
      expect(d.countGreater(10), 500); // score >= 11
      expect(d.countGreater(15), 300); // 11..21 の間を直線で
      expect(d.countGreater(999), 100);
    });
  });

  group('RankingService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('submit: Firestore REST の形で送る', () async {
      final t = FakeTransport();
      final ok = await RankingService(t, projectId: 'p', jsonUrl: 'https://x/r.json').submit('abc', 'Taro', 123);
      expect(ok, true);
      final (url, body) = t.patches.single;
      expect(url.path, '/v1/projects/p/databases/(default)/documents/scores/abc');
      expect(url.queryParametersAll['updateMask.fieldPaths'], ['name', 'score']);
      expect(jsonDecode(body)['fields']['score']['integerValue'], '123');
      expect(jsonDecode(body)['fields']['name']['stringValue'], 'Taro');
    });

    test('submit: 通信失敗は false、ルール拒否(403)は送信済み扱い', () async {
      final t = FakeTransport()..patchCode = -1;
      final s = RankingService(t, jsonUrl: 'https://x/r.json');
      expect(await s.submit('a', 'n', 1), false);
      t.patchCode = 403;
      expect(await s.submit('a', 'n', 1), true);
      t.patchCode = 500;
      expect(await s.submit('a', 'n', 1), false);
    });

    test('fetch: 取得→保存、通信できない時は保存分を使う', () async {
      final t = FakeTransport()
        ..text = jsonEncode({
          'updatedAt': '2026-11-08T18:00:00Z',
          'total': 2,
          'top': [
            {'name': 'A', 'score': 10, 'tag': 'aaaa'},
            {'name': 'B', 'score': 5, 'tag': 'bbbb'},
          ],
          'scores': [10, 5],
        });
      final s = RankingService(t, jsonUrl: 'https://x/r.json');
      final d1 = await s.fetch();
      expect(d1.top.length, 2);
      expect(d1.updatedAt, isNotNull);
      t.text = null; // オフライン
      final d2 = await s.fetch();
      expect(d2.top.length, 2);
    });

    test('fetch: 何も無ければ空', () async {
      final d = await RankingService(FakeTransport(), jsonUrl: 'https://x/r.json').fetch();
      expect(d.top, isEmpty);
      expect(d.updatedAt, isNull);
    });

    test('submitPendingRanking: 新しいベストだけ送り、成功したら記録する', () async {
      final t = FakeTransport();
      final service = RankingService(t, jsonUrl: 'https://x/r.json');
      final n = UserDataNotifier(UserDataStore(), UserData.initial(), 56);
      await submitPendingRanking(user: n.state, service: service, notifier: n);
      expect(t.patches, isEmpty); // 記録なし
      n.addRecord(1, 300); // ノーマルは対象外
      await submitPendingRanking(user: n.state, service: service, notifier: n);
      expect(t.patches, isEmpty);
      n.addRecord(2, 42);
      await submitPendingRanking(user: n.state, service: service, notifier: n);
      expect(t.patches.length, 1);
      expect(n.state.submittedBest, 42);
      await submitPendingRanking(user: n.state, service: service, notifier: n);
      expect(t.patches.length, 1); // 同じ記録は再送しない
      t.patchCode = -1;
      n.addRecord(2, 50);
      await submitPendingRanking(user: n.state, service: service, notifier: n);
      expect(n.state.submittedBest, 42); // 失敗したら未送信のまま(次に再送)
    });
  });

  test('installId: 32桁の16進で、保存形式を往復しても変わらない', () {
    final u = UserData.initial();
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(u.installId), true);
    expect(UserData.fromJson(u.toJson()).installId, u.installId);
  });
}
