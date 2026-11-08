/// ガチャ1回に必要なコイン
const int gatyaCost = 10;

/// 広告を見て貰えるコイン(ガチャ2回分)
const int adRewardCoins = gatyaCost * 2;

/// 初回起動時のコイン(すぐガチャを試せるように)
const int startingCoins = 20;

/// ノーマルモードのクリアスコア
const int normalGoalScore = 300;

/// ゲーム画面の下に置く広告バナーの高さ
const double bannerHeight = 50;

/// 開発中は true(テスト用の広告IDを使う)
const bool useTestAds = true;

/// ランキング(ハードモードのみ)。
/// スコアの送信: Firestore REST(認証なし。セキュリティルールで守る。backend/firestore.rules)。
/// 順位表の取得: 毎日1回、GitHub Actions が作る JSON(ranking-data ブランチ。backend/)。
const int rankingMode = 2;
const String rankingProjectId = 'italian-brainrot-p3vkon';
const String rankingJsonUrl =
    'https://raw.githubusercontent.com/06190528/italian_brainrot_app/ranking-data/ranking.json';
