import 'dart:ui';

/// 画面の文言(ja / en)。端末の言語が日本語なら日本語、それ以外は英語。
class S {
  S._();
  static bool get _ja => PlatformDispatcher.instance.locale.languageCode == 'ja';
  static bool forceJa = false; // テスト用
  static String _t(String ja, String en) => (_ja || forceJa) ? ja : en;

  static String get appTitle => _t('イタリアン・ブレインロット', 'Italian Brainrot');
  static String get start => _t('スタート', 'Start');
  static String get back => _t('もどる', 'Back');
  static String get retry => _t('もういちど', 'Retry');
  static String get home => _t('ホームへ', 'Home');
  static String get pause => _t('ポーズ', 'Pause');
  static String get resume => _t('つづける', 'Resume');
  static String get selectMode => _t('モードを選ぶ', 'Select mode');
  static String get normal => _t('ノーマル', 'Normal');
  static String get hard => _t('ハード', 'Hard');
  static String normalDesc(int goal) => _t('$goal体をかわしてクリア', 'Dodge $goal to clear');
  static String get hardDesc => _t('エンドレス(ノーマルクリアで解放)', 'Endless (unlock by clearing Normal)');
  static String get locked => _t('ロック中', 'Locked');
  static String get gatya => _t('ガチャ', 'Gacha');
  static String gatyaByCoins(int c) => _t('$cコインで回す', 'Spin for $c coins');
  static String get tapToSpin => _t('タップ!', 'Tap!');
  static String get notEnoughCoins => _t('コインがたりない', 'Not enough coins');
  static String get watchAdForCoins => _t('広告を見てコインをもらう', 'Watch ad for coins');
  static String get newCharacter => _t('NEW!', 'NEW!');
  static String get duplicate => _t('ダブり(+5コイン)', 'Duplicate (+5 coins)');
  static String get ok => _t('OK', 'OK');
  static String get yes => _t('はい', 'Yes');
  static String get no => _t('いいえ', 'No');
  static String goalScore(int n) => _t('目標スコア : $n', 'Goal : $n');
  static String get score => _t('スコア', 'Score');
  static String get bestScore => _t('ベスト', 'Best');
  static String get gameOver => _t('ゲームオーバー', 'Game Over');
  static String get gameClear => _t('ゲームクリア!', 'Game Clear!');
  static String get runAway => _t('にげろ!', 'Run away!');
  static String get swipeToMove => _t('スワイプで動かす', 'Swipe to move');
  static String get coinsEarned => _t('獲得コイン', 'Coins');
  static String get continueByAd => _t('広告を見てコンティニュー', 'Continue (watch ad)');
  static String get watchAdToContinue => _t('広告を見てコンティニューしますか?', 'Watch an ad to continue?');
  static String get ranking => _t('ランキング', 'Ranking');
  static String get rankingNote => _t('毎日1回更新(あなたの記録は、すぐ反映)', 'Updated daily (your score is shown right away)');
  static String rankingUpdated(String t) => _t('最終更新 $t', 'Updated $t');
  static String rankOf(int rank, int total) => _t('あなたの順位: $rank位 / $total人', 'Your rank: #$rank of $total');
  static String get rankingHardOnly => _t('ハードモードの記録でランキングに参加できます', 'Play Hard mode to join the ranking');
  static String get rankingOffline => _t('順位表を取得できませんでした(引っぱって更新)', 'Could not load the ranking (pull to refresh)');
  static String get you => _t('あなた', 'You');
  static String get noRecords => _t('まだ記録がありません', 'No records yet');
  static String get settings => _t('設定', 'Settings');
  static String get playerName => _t('なまえ', 'Name');
  static String get sound => _t('サウンド', 'Sound');
  static String get save => _t('保存', 'Save');
  static String get sortie => _t('出撃キャラ', 'Your character');
  static String collected(int n, int total) => _t('図鑑 $n / $total', 'Collected $n / $total');
  static String get fever => _t('フィーバー!', 'FEVER!');
  static String get tapToUse => _t('タップで必殺!', 'Tap!');
  static String get adNotReady => _t('広告を準備中です', 'Ad is not ready');

  // スキル
  static String get skill => _t('スキル', 'Skill');
  static String get skillBarrier => _t('バリア', 'Barrier');
  static String get skillMagnet => _t('マグネット', 'Magnet');
  static String get skillFeverBoost => _t('フィーバーブースト', 'Fever Boost');
  static String get skillLuckyDrop => _t('ラッキードロップ', 'Lucky Drop');
  static String get skillMiniBody => _t('ちびボディ', 'Mini Body');
  static String skillBarrierDesc(int n) => _t('はじめに泡が1枚。敵に1回触れてもOK。$n体かわすと再生', 'Starts with a bubble that blocks 1 hit. Regrows after $n dodges');
  static String skillMagnetDesc(int p) => _t('アイテムを引き寄せる(範囲 $p%)', 'Pulls items toward you (range $p%)');
  static String skillFeverBoostDesc(int p) => _t('フィーバーまでの数が$p%へる', 'Fever needs $p% fewer dodges');
  static String skillLuckyDropDesc(int n) => _t('$n体かわすごとにアイテムが出る(ふつうは15)', 'An item drops every $n dodges (normally 15)');
  static String skillMiniBodyDesc(int p) => _t('からだが$p%小さくなる', 'Your body is $p% smaller');
  static String get shieldBroken => _t('バリアがわれた!', 'Barrier broke!');
}
