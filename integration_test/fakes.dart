import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:italian_brainrot_app/app/providers.dart';
import 'package:italian_brainrot_app/data/ranking_service.dart';

/// ランキングの通信の偽物(本番のFirestoreに書き込まないため)。
class FakeRankingTransport implements RankingTransport {
  final String? json;
  final submitted = <String>[];
  FakeRankingTransport({this.json});

  @override
  Future<String?> getText(Uri url) async => json;

  @override
  Future<int> patchJson(Uri url, String body) async {
    submitted.add(body);
    return 200;
  }
}

Override fakeRanking(FakeRankingTransport t) =>
    rankingServiceProvider.overrideWithValue(RankingService(t, jsonUrl: 'https://example.invalid/r.json'));
