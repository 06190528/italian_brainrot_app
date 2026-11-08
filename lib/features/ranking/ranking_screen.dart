import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/strings.dart';
import '../../core/widgets.dart';
import '../../data/user_data.dart';

/// いまは端末内のハイスコア一覧(ハード=エンドレスの記録)。
/// オンラインランキング(Firestore)は、Firebaseプロジェクトを用意してから差し替える。
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(userDataProvider).records;
    final hard = records.where((r) => r.mode == 2).toList();
    final normal = records.where((r) => r.mode == 1).toList();
    final list = [...hard, ...normal];
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
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16)),
                child: list.isEmpty
                    ? Center(child: Text(S.noRecords, style: const TextStyle(fontSize: 18, color: Colors.black)))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => _row(i, list[i]),
                      ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _row(int i, ScoreRecord r) => ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text(r.name, style: const TextStyle(color: Colors.black)),
        subtitle: Text(r.mode == 2 ? S.hard : S.normal),
        trailing: Text('${r.score}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
      );
}
