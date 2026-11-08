import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../core/widgets.dart';
import '../../data/ranking_service.dart';

/// ランキング(ハードモード)。
/// 毎日1回作られる順位表(JSON)を取得し、自分の記録を、あるべき位置に差し込んで見せる。
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  late Future<RankingData> _future = _load();

  Future<RankingData> _load() async {
    final service = ref.read(rankingServiceProvider);
    // 送れていない自己ベストがあれば、先に送る
    await submitPendingRanking(
      user: ref.read(userDataProvider),
      service: service,
      notifier: ref.read(userDataProvider.notifier),
    );
    return service.fetch();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider);
    final myBest = user.bestScore(rankingMode);
    return Scaffold(
      body: Stack(children: [
        const CoverBackground('assets/images/bg/title.jpg'),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                RoundIconButton(key: const Key('rankingBack'), icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                OutlinedText(S.ranking, fontSize: 30),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(16)),
                child: FutureBuilder<RankingData>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snap.data ?? RankingData.empty;
                    final board = composeBoard(data,
                        myTag: user.installId.substring(28), myName: user.name, myScore: myBest);
                    return _body(data, board, myBest);
                  },
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _body(RankingData data, Board board, int myBest) {
    final offline = data.updatedAt == null && data.top.isEmpty;
    final t = data.updatedAt;
    final updated = t == null
        ? null
        : '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(children: [
          Text(S.rankingNote, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (updated != null) Text(S.rankingUpdated(updated), key: const Key('rankingUpdated'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (board.me != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(S.rankOf(board.me!.rank, board.total),
                  key: const Key('myRankText'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          if (myBest == 0) Text(S.rankingHardOnly, style: const TextStyle(fontSize: 13, color: Colors.deepOrange)),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: board.rows.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 60),
                  Center(child: Text(offline ? S.rankingOffline : S.noRecords, style: const TextStyle(fontSize: 16, color: Colors.black54))),
                ])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: board.rows.length,
                  itemBuilder: (_, i) => _row(board.rows[i]),
                ),
        ),
      ),
      if (board.me != null && !board.meInRows) _row(board.me!, pinned: true),
    ]);
  }

  Widget _row(BoardRow r, {bool pinned = false}) {
    final medal = switch (r.rank) { 1 => const Color(0xFFFFC107), 2 => const Color(0xFFB0BEC5), 3 => const Color(0xFFCD7F32), _ => null };
    return Container(
      key: r.isMe ? const Key('myRow') : null,
      color: r.isMe ? const Color(0xFFFFF3C4) : null,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: medal ?? Colors.blueGrey.shade100,
          child: Text('${r.rank}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        title: Text(r.isMe ? '${r.name} (${S.you})' : r.name, style: TextStyle(color: Colors.black, fontWeight: r.isMe ? FontWeight.w900 : FontWeight.w500)),
        trailing: Text('${r.score}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
      ),
    );
  }
}
