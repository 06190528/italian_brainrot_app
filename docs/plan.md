# italian_brainrot_app 設計メモ

元: `/Users/kitano/pj/saibai_men_app`(Flutter + Flame のガチャ&シューティング。キャラ51種、Firebaseランキング)
目的: 世界観をイタリアンブレインロットに差し替えた別アプリとして作る。

## 方針
- 元コードは**そのままコピーしない**。機能ごとに読み直して移植する(ホーム → ガチャ → ゲーム本体 → ランキング)。
- 元の `getEnemySpriteDetails`(51個のcaseに列数・行数・速度を手書き)はやめ、**キャラ定義をデータ(JSON)に外出し**する。
- 素材が揃うまでは、元アプリの汎用素材(コイン・鍵・爆発など)と仮キャラでプレースホルダー動作させる。素材収集は開発をブロックしない。

## ディレクトリ構成(lib)
```
lib/
  main.dart
  app/            # MaterialApp, テーマ, ルーティング
  core/           # 定数, 多言語, 音(AudioService), 広告(ad_helper), 共通widget
  data/           # characters.json の読み込み(CharacterRepository), 保存(shared_preferences), Firebase
  features/
    home/
    gatya/
    game/         # Flameのコンポーネント(player/enemy/effects), ロジック, HUD
    ranking/
assets/
  data/characters.json
  images/{characters,ui,bg,effects}/
  sounds/{bgm,se}/
asset_sources/    # 素材の生データ置き場(git管理外)。加工前。SOURCES.md と manifest.json を置く
tools/            # 変換スクリプト(sprite化など)
docs/
```

## キャラ定義 `assets/data/characters.json`
```json
{ "id": 0, "slug": "tung-tung-sahur", "name": "Tung Tung Tung Sahur",
  "rarity": 1, "sheet": "characters/c000.png",
  "cols": 8, "rows": 6, "frames": 44, "stepTime": 0.05 }
```
- 並び順 = 元アプリの `enemyKinds` と同じ「進行順」(後ろほど強い/レア)。元は index 0〜50。
- **スプライトシート規格(新)**: 1フレーム256×256の透過PNG、8列、最大48フレーム(12fps相当)、`tools/make_sheet.py` が生GIF/動画/静止画から生成する。元の「50列×最大9行・約6000px幅」はメモリが重いので採用しない。
- 静止画しか手に入らないキャラは、スクリプトで上下の揺れ・拡縮の擬似アニメを付ける。

## 素材 → 元アプリでの用途(収集対象)
| 区分 | 元ファイル | 用途 | 優先度 |
|---|---|---|---|
| キャラ | characters/cats_memes_0〜50 | プレイヤー/敵/ガチャ排出 | **P0** |
| BGM | bgm.mp3, fever_bgm.mp3 | 通常/フィーバー | P1 |
| 効果音 | explosion, game_clear, gatyaSound, getCharacter, getCoinSound, getItemSound, specialMove, goat_sounds1/2 | 爆発/クリア/ガチャ/新キャラ/コイン/アイテム/必殺/被弾など | P1 |
| 背景 | titleScene.jpg(1518×1075), background.png(1600×9600縦長) | ホーム・ガチャ背景/ゲーム縦スクロール | P2 |
| UI/エフェクト | gatya.png, capsule.png, coin.png, padlock.png, saiazinn.png, energy bullet/icon, ki_sprite, explosion_sprite, icon.png | ガチャ演出/コイン/ロック/必殺技/爆発/アプリアイコン | P2(AI生成や自作でも可。当面は元素材を流用) |

## 自律開発のループ(1機能ずつ)
1. 元コードの該当部分を読み、移植方針を決める → 実装 → `fvm flutter analyze`
2. **iOSシミュレータ `italian-brainrot-dev`(UDID `4C81E0DD-3457-4012-87C3-71B18916516B`、iPhone 17 Pro / iOS 26.5。このプロジェクト専用。他のエージェントが使っている `iPhone 17` や Androidエミュレータには触らない)**で `fvm flutter run -d 4C81E0DD-3457-4012-87C3-71B18916516B` → 画面は `xcrun simctl io <UDID> screenshot x.png`、ログは `flutter run` の出力を見て不具合を直す
3. 動作に問題がなければ次の機能へ。コミット・プッシュはユーザーの指示があってから
- `simctl` は `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` を付けて使う(`xcode-select` が CommandLineTools を指しているため)。
- **操作の自動化は B に決定**: `integration_test` + `flutter drive -d <UDID>`(参考: `/Users/kitano/pj/minor-qualification-learning-apps` の `docs/development.md` `docs/troubleshooting.md` `tools/record_flow.sh`)。画面の撮影は、`simctl` ではなく、アプリが渡すバイト列をドライバが書く方式にする(`simctl` 撮影は、全部が最後の画面になる)。画面録画は `simctl io <UDID> recordVideo`。
- テストの層: 計算=ユニット / 画面の出し分け=ウィジェット(`test/`) / 流れ=`integration_test/`。

## ユーザー側で必要なもの(私ができない)
- 新しいFirebaseプロジェクトの作成と `firebase_options.dart`(ランキング着手時)
- 本番用AdMobのアプリID/広告ユニットID(開発中はテストIDで進める)
- ストア公開時のキャラ素材の権利は、ユーザーが引き受ける(指摘があれば取り下げ)。そのため、素材ごとの出典を `asset_sources/SOURCES.md` に残して、すぐ特定できるようにする
