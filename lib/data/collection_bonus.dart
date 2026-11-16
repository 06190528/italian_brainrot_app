/// 図鑑ボーナス: 持っているキャラの数に応じて、ゲームで貰えるコインが増える(スコアは変わらない)。
/// 10体 +10% / 25体 +20% / 50体 +30% / 80体 +40% / 110体 +50%
const List<(int owned, int percent)> collectionBonusTiers = [
  (10, 10),
  (25, 20),
  (50, 30),
  (80, 40),
  (110, 50),
];

/// 持っている数から、コインの増加率(%)。
int collectionBonusPercent(int owned) {
  var p = 0;
  for (final (n, pct) in collectionBonusTiers) {
    if (owned >= n) p = pct;
  }
  return p;
}

/// 次のボーナスまで、あと何体か(最大なら null)と、そのときの増加率。
({int remaining, int percent})? nextCollectionBonus(int owned) {
  for (final (n, pct) in collectionBonusTiers) {
    if (owned < n) return (remaining: n - owned, percent: pct);
  }
  return null;
}

/// ゲーム終了時に貰うコイン: スコアの1/10(切り捨て)に、図鑑ボーナスを掛ける(切り捨て)。
int coinsForScore(int score, int owned) => (score ~/ 10) * (100 + collectionBonusPercent(owned)) ~/ 100;
