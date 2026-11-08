import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'user_data.dart';

/// 順位表の1行(JSON)。tag は端末IDの末尾4桁(自分の古い行を取り除くために使う)。
class RankingEntry {
  final String name;
  final int score;
  final String tag;
  const RankingEntry(this.name, this.score, this.tag);
}

/// 毎日1回作られる順位表(ranking.json)。
///  - top: 上位100人(降順)
///  - scores: 全員のスコア(降順)。人数が少ない間だけ入る(順位が正確)
///  - cum: [しきい値, そのスコア以上の人数] の列。人数が多い時の概算用
class RankingData {
  final DateTime? updatedAt;
  final int total;
  final List<RankingEntry> top;
  final List<int>? scores;
  final List<List<int>>? cum;

  const RankingData({this.updatedAt, this.total = 0, this.top = const [], this.scores, this.cum});

  static const empty = RankingData();

  factory RankingData.fromJson(Map<String, dynamic> j) => RankingData(
        updatedAt: j['updatedAt'] == null ? null : DateTime.tryParse(j['updatedAt'] as String)?.toLocal(),
        total: (j['total'] ?? 0) as int,
        top: ((j['top'] ?? []) as List)
            .map((e) => RankingEntry(
                (e['name'] ?? '') as String, (e['score'] ?? 0) as int, (e['tag'] ?? '') as String))
            .toList(),
        scores: j['scores'] == null ? null : (j['scores'] as List).cast<int>(),
        cum: j['cum'] == null
            ? null
            : (j['cum'] as List).map((e) => (e as List).cast<int>()).toList(),
      );

  /// スコア s より高い人数。
  int countGreater(int s) {
    final sc = scores;
    if (sc != null) return sc.where((v) => v > s).length;
    final c = cum;
    if (c != null && c.isNotEmpty) {
      final t = s + 1; // score >= t の人数
      if (t <= c.first[0]) return c.first[1];
      if (t >= c.last[0]) return c.last[1];
      for (var i = 0; i < c.length - 1; i++) {
        final a = c[i], b = c[i + 1];
        if (t >= a[0] && t <= b[0]) {
          if (b[0] == a[0]) return a[1];
          return (a[1] + (b[1] - a[1]) * (t - a[0]) / (b[0] - a[0])).round();
        }
      }
    }
    return top.where((e) => e.score > s).length;
  }
}

class BoardRow {
  final int rank;
  final String name;
  final int score;
  final bool isMe;
  const BoardRow(this.rank, this.name, this.score, this.isMe);
}

class Board {
  /// 表示する行(上位+自分。自分が圏内ならその位置に入る)
  final List<BoardRow> rows;

  /// 自分の行(スコアが無ければ null)
  final BoardRow? me;

  /// 自分が rows の中に入っているか(false なら、画面の下に別で出す)
  final bool meInRows;
  final int total;
  const Board(this.rows, this.me, this.meInRows, this.total);
}

/// 取得した順位表に、自分の記録を、あるべき位置に差し込む。
/// 昨日までの順位表に入っている自分の古い行(tag が一致)は取り除く。
Board composeBoard(RankingData data, {required String myTag, required String myName, required int myScore}) {
  final others = data.top.where((e) => e.tag != myTag).toList()..sort((a, b) => b.score.compareTo(a.score));
  final hasMe = myScore > 0;
  BoardRow? me;
  var meInRows = false;
  final rows = <BoardRow>[];

  int rankOf(int score) => 1 + others.where((e) => e.score > score).length + (hasMe && myScore > score ? 1 : 0);

  var meIndex = -1;
  if (hasMe) {
    final higher = others.where((e) => e.score > myScore).length;
    final globalRank = data.countGreater(myScore) + 1;
    final inTop = higher < others.length || others.length < 100;
    me = BoardRow(inTop ? higher + 1 : globalRank, myName, myScore, true);
    if (inTop) {
      meIndex = higher;
      meInRows = true;
    }
  }
  for (var i = 0; i <= others.length; i++) {
    if (i == meIndex) rows.add(me!);
    if (i < others.length) {
      final e = others[i];
      rows.add(BoardRow(rankOf(e.score), e.name, e.score, false));
    }
  }
  final total = [data.total, me?.rank ?? 0, rows.length].reduce((a, b) => a > b ? a : b);
  return Board(rows, me, meInRows, total);
}

/// 通信の差し替え口(テストで偽物を入れる)。
abstract class RankingTransport {
  Future<String?> getText(Uri url);

  /// PATCH して、HTTPステータスを返す(通信できなければ -1)。
  Future<int> patchJson(Uri url, String body);
}

class HttpRankingTransport implements RankingTransport {
  static const _timeout = Duration(seconds: 8);

  @override
  Future<String?> getText(Uri url) async {
    final c = HttpClient()..connectionTimeout = _timeout;
    try {
      final req = await c.getUrl(url).timeout(_timeout);
      final res = await req.close().timeout(_timeout);
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join().timeout(_timeout);
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  @override
  Future<int> patchJson(Uri url, String body) async {
    final c = HttpClient()..connectionTimeout = _timeout;
    try {
      final req = await c.patchUrl(url).timeout(_timeout);
      req.headers.contentType = ContentType.json;
      req.write(body);
      final res = await req.close().timeout(_timeout);
      await res.drain<void>();
      return res.statusCode;
    } catch (_) {
      return -1;
    } finally {
      c.close(force: true);
    }
  }
}

class RankingService {
  final RankingTransport transport;
  final String projectId;
  final String jsonUrl;
  static const _cacheKey = 'ranking_cache_v1';

  RankingService(this.transport, {this.projectId = rankingProjectId, this.jsonUrl = rankingJsonUrl});

  /// スコアを送る(自分の1件を作る/ベストを更新する)。送れた(または、サーバーのほうが高くて不要だった)なら true。
  Future<bool> submit(String installId, String name, int score) async {
    final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/scores/$installId'
        '?updateMask.fieldPaths=name&updateMask.fieldPaths=score');
    final body = jsonEncode({
      'fields': {
        'name': {'stringValue': name},
        'score': {'integerValue': '$score'},
      }
    });
    final code = await transport.patchJson(url, body);
    // 403: ルールが拒否 = サーバーのほうが高いスコアを持っている。再送しても無駄なので、送信済みとして扱う。
    return code == 200 || code == 403;
  }

  /// 順位表を取る。通信できなければ、前回の保存分(なければ空)。
  Future<RankingData> fetch({bool useCache = true}) async {
    final text = await transport.getText(Uri.parse(jsonUrl));
    if (text != null) {
      try {
        final data = RankingData.fromJson(jsonDecode(text) as Map<String, dynamic>);
        try {
          (await SharedPreferences.getInstance()).setString(_cacheKey, text);
        } catch (_) {}
        return data;
      } catch (_) {}
    }
    if (useCache) {
      try {
        final cached = (await SharedPreferences.getInstance()).getString(_cacheKey);
        if (cached != null) return RankingData.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {}
    }
    return RankingData.empty;
  }
}

/// まだ送っていないハードモードのベストがあれば送る。
Future<void> submitPendingRanking({
  required UserData user,
  required RankingService service,
  required UserDataNotifier notifier,
}) async {
  final best = user.bestScore(rankingMode);
  if (best <= 0 || best <= user.submittedBest) return;
  if (await service.submit(user.installId, user.name, best)) {
    notifier.markSubmitted(best);
  }
}
