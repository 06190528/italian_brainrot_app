# リリース作業の引き継ぎ(2026-11-09 時点)

> **2026-11-16: iOSが 4.3(a)/4.2.6 で却下(11/14)→ 修正して再提出済み(11/16 19:34)**。Androidも同じ 1.0.0+2 をPlayに提出(審査中)。却下文: `~/pj/tools/chrome-hub/state/review_thread_italianbrainrot.txt`。
> - 原因: 公開済みの `saibai_men_app` と、ルール・素材が同じ(リスキンに見えた)。
> - 対応(コミット `c1ffecd`〜): 元アプリと同一の素材(画像6・音4)を全部置き換え(コード描画・CC0の音。`tools/check_shared_assets.sh` でmd5一致0件をゲートで保つ)/ 全110キャラのスキル5種(`lib/data/skill.dart`。id%5で種類、レア度で強さ)/ 敵の動き(蛇行・追尾)/ ホームの図鑑化+図鑑ボーナス(コイン+10〜50%)/ クレジット画面(CC BY表記)。バランスの基準と結果は `docs/balance_baseline.md`。
> - 提出物: ビルド 1.0.0+2(IPA差し替え済み)・掲載文・スクショ5枚・審査メモ・動画(`store/review_demo/recording_attach.mp4`)・英語の返信(`store/appeal_reply.txt`。返信済み)。
> - 次: 審査結果の確認(`review_status.py italianbrainrot`)。再度却下されたら、質問6が示す「既存アプリ(猫ミーム大戦争)への統合」も選択肢。通ったら、AdMobの `link`・`admob_verify`。
> - 教訓: ゲートのAABビルドを、統合テストと並列にすると、`GeneratedPluginRegistrant.java` を書き換え合って落ちる(直した)。chrome-hub の `release.py --stage listing` は、Playのカテゴリ入力で止まるので、却下後の更新は関数を直接呼んだ(ASC: `fill_app_info`/`fill_version`/`upload_screenshots(replace=True)`/`replace_build`/`set_review_info`(古い添付は「削除」ボタンで消してから)。返信・再提出: `review_thread.py reply --send` / `resubmit`。Play: `fill_store_listing`/`upload_listing_assets`/`create_release(version_code=2)`/`publish_release`)。

> **2026-11-10 更新: ASC・Play とも審査に提出済み**(ビルド 1.0.0+1、ゲート通過コミット `97819d7`)。残りは、審査結果の確認・公開後の AdMob `link`/`admob_verify`・ターゲット層とデータ申告の追加(`docs/play_target_audience_handoff.md`)。以下は、提出前の記録。

> **2026-11-12 14:20 の確認(読むだけ)**: iOS 1.0.0 は **審査待ち**(提出 11/10 火 10:28)。Android は **公開済み**(最新リリース24時間前)。Play の配信国は、EEA・英国が外れていることを確認(`sites.playstore_countries italianbrainrot --dry-run` → 変更なし)。AdMob は両OSとも「要審査・広告配信を制限」。**AdMob の Android 紐づけは、ストア検索が0件で未実施**(公開直後は、検索に出るまで時間がかかる)。再試行: `cd ~/pj/tools/chrome-hub && .venv/bin/python -m sites.admob link "イタリアンブレインロット大戦争" Android com.okinnnikudekao.italianbrainrot --dry-run`(通ったら `--dry-run` を外す)。iOS は、承認後に `https://apps.apple.com/jp/app/id6832495202` で紐づけ。
> **状況の確認方法**: `review_status.py` は、このアプリのAdMob欄が「app_config.json を読めない」になる(兄弟リポジトリの `apps/<slug>/assets/app_config.json` を探すため。chrome-hub 側の修正は、他のエージェントが編集中だったので未対応)。ASC・Play 欄は正しく出る。AdMob は `.venv/bin/python -m sites.admob status イタリアン` で読む。ブラウザのプロファイル(appstore/playstore)は、他のエージェントも使うので、`pgrep -fl review_status` で実行中でないか見てから使う。

新しいチャットは、**まずこのファイルを読む**。あわせて `docs/plan.md`(設計)・`backend/README.md`(ランキング)・`docs/asset_collection_report.md`(素材)・`~/pj/tools/chrome-hub/CLAUDE.md`(リリースツール)。
メモリ(`~/.claude/projects/-Users-kitano-pj-italian-brainrot-app/memory/`)にも方針が入っている。

## 1. 現状
- **アプリは遊べる状態**。ホーム・ガチャ(10コイン)・ゲーム(ノーマル300点クリア/ハード=エンドレス)・ランキング・設定・広告(バナー/リワード)。キャラ110体(WebPのシート)、BGM・SE(CC0)。
- **ランキングは本番稼働中**。Firestore(`italian-brainrot-p3vkon`)+ GitHub Actions(毎日 03:17 JST)→ `ranking-data` ブランチの `ranking.json`。Secret `FIREBASE_SERVICE_ACCOUNT` 登録済み。
- **広告の本番IDは反映済み**(AdMob「イタリアンブレインロット大戦争」のAndroid/iOSアプリと広告ユニットが既に存在)。デバッグビルドはテスト広告、リリースビルドだけ本番。
- **リリース前のゲート**: `tools/release_gate.sh` が **全部通っている**(analyze / unit 19件 / node 4件 / drive flow・play・ranking / balance_sim)。
- **未プッシュのコミットがある**(`git log origin/master..HEAD`)。プッシュはユーザーの指示があってから。
- リリース作業は、**調査の途中**(下の「3」)。ストア側の操作は、まだ何も実行していない。

## 2. 方針(ユーザーの指示)
- 検証は**エミュレータ/シミュレータだけ**(実機は使わない)。検証は、私がテストコードにして貯め、**リリース前に全部通ってから**リリースする(`tools/release_gate.sh`)。
- リリースは **chrome-hub の `release.py`** で行う(`~/pj/tools/chrome-hub`。他アプリのspec: `specs/*.toml`、ドキュメント: `CLAUDE.md`・`LISTING.md`・`KNOWLEDGE.md`)。リリース設定で困ったら、`/Users/kitano/pj/minor-qualification-learning-apps` を見る(同じ手順で、すでにリリース済み)。
- ユーザーは基本的に介入しない。**取り消せない操作は、最後に1回、値を全部並べてまとめて確認**する(下の「5」)。それ以外は、確認なしで進めてよい。
- コミットは小さく・タスクごと。`Co-Authored-By` は書かない。プッシュは、指示があってから。日報(`/Users/kitano/pj/report_the_results/personal/<年>/<月>/<日>/daily_report.md`)は、`date` で日付を確認して、コミットごとに更新する(11/09 の日報は、まだ作っていない)。
- **Playの配信国は、EEA・英国を対象にしない**(取引業者になって住所が公開されるのを避ける)。詳細: `docs/play_distribution_countries.md`。提出のあとに、必ず外れていることを確認する。
- 他のエージェントのシミュレータ・エミュレータは使わない。専用: iOSシミュレータ `italian-brainrot-dev`(UDID `4C81E0DD-3457-4012-87C3-71B18916516B`)。

## 3. リリース手順(進捗)
順序: ローカルで取り消せる作業 → ゲート → 確認(1回) → ストア操作。

### A. アプリ側の設定(未着手。調査は済み)
- [ ] **Bundle ID / パッケージ名**: iOS・Androidとも `com.okinnnikudekao.italianbrainrot`(`com.example.*` はPlayで使えない。release.py は、iOSとAndroidを同じ文字列として扱う)。
  - iOS: `ios/Runner.xcodeproj/project.pbxproj` の `PRODUCT_BUNDLE_IDENTIFIER`(`com.example.italianBrainrotApp` と `.RunnerTests`)。
  - Android: **プロジェクトが古い**(Gradle 7.6・Kotlin 1.7.10。Flutter 3.35 向けではない)。新しいテンプレートで作り直す: 一時ディレクトリで `flutter create --no-pub --org com.okinnnikudekao --project-name italianbrainrot --platforms android .` → できた `android/` で置き換え(Gradle 8.12・AGP 8.9.1・Kotlin 2.1.0・`build.gradle.kts`・パッケージ `com.okinnnikudekao.italianbrainrot`)。置き換えたあとに戻すもの: マニフェストの `android:label="Italian Brainrot"`、AdMobの `APPLICATION_ID` メタデータ(`ca-app-pub-2847746899486154~6665031290`)、**`<uses-permission android:name="android.permission.INTERNET"/>`**(メインのマニフェストに無いと、リリースで広告・ランキングが通信できない)、アイコン(`dart run flutter_launcher_icons`。**`ios/Runner.xcodeproj/project.pbxproj` の `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` を `AppIcon` に書き換えられるので、`YES` に戻す**)。
- [ ] **Androidのリリース署名**: `~/.private_keys/play-upload.properties`(全アプリ共通のアップロードキー。キーは `~/.private_keys/play-upload.jks`)があれば、それで署名するブロックを `app/build.gradle.kts` に入れる。参考: `minor-qualification-learning-apps/apps/shakaifukushishi/android/app/build.gradle`(`signingConfigs.upload`)。`minSdk=24`・`targetSdk` は Flutter 既定(35以上)。
- [ ] **iOS**: `ITSAppUsesNonExemptEncryption=false` を `Info.plist` に。**iPhoneのみ**にする(`TARGETED_DEVICE_FAMILY = 1`。iPadのスクショと画面確認を避けるため)。向きは縦のみ。
- [ ] **広告の同意(UMP)と非個人化広告**: 今は `AdRequest()` で、同意なしに `MobileAds.initialize()` している。兄弟アプリの `packages/exam_core/lib/ads/ads.dart` を参考に、(1) UMP の同意を取ってから初期化、(2) バナー・リワードを `AdRequest(nonPersonalizedAds: true)`、(3) `tagForChildDirectedTreatment: no`。ストア申告(ATTなし・個人に合わせない広告)と一致させる。
- [ ] **クレジット(出典の表記)画面**: 背景は Wikimedia Commons の CC BY 4.0 / CC BY-SA 4.0(`asset_sources/SOURCES.md` に、作者・URLあり)。**表記が必須**。設定画面に「クレジット」を作り、背景の作者・ライセンスを載せる。BGM・SEは CC0(Kenney・OpenGameArt。表記は不要だが、載せてよい)。CC BY-SA の素材(背景)の扱い(同条件での公開が要るか)は、使う背景がどちらのライセンスかを確認して、BY-SA なら BY の背景に替えるか検討する。
- [ ] **ビルドの確認**: `flutter build appbundle --release --no-pub`(Flutter 3.35.4)→ `python3 ~/pj/minor-qualification-learning-apps/tools/release/check_aab.py <spec> <aab>`。`flutter build ios --release --no-codesign --no-pub`。
- [ ] **IPA**: `~/pj/minor-qualification-learning-apps/tools/release/build_ipa.py` は **Flutter 3.24.5 を決め打ち**(`FVM_FLUTTER`)。この版ではこのアプリをビルドできない(flame 1.23)。**このリポジトリの `tools/release/` にコピーして、3.35.4 に直す**(兄弟アプリは変えない)。署名は ASC のAPIキー(`~/.private_keys/AuthKey_39GJ5UUS4A.p8`。spec の `[build.ios_upload]` を参照)。

### B. ストア用の素材(未着手)
- [ ] アイコン: `assets/icon/icon.png`(1024、透過なし)がある。Play用は 512×512 を別に作る(縮小ではなく、用意したファイルをそのまま使う方針)。
- [ ] スクリーンショット: 統合テストで、シミュレータ(1206×2622 = App Store の6.3インチ)から撮る(`binding.takeScreenshot`、`test_driver/integration_test.dart` が `build/shots/` に保存)。**広告バナー(テスト広告)が写らないようにする**(テスト用に広告を無効にする口を作る)。キャラを多く持った状態のホーム・ガチャ結果・敵が多いプレイ・フィーバー・ランキングの5枚くらい。
  - `~/pj/minor-qualification-learning-apps/tools/store_assets/make_store_assets.py <store_copy.json>` で、見出し付きのストア画像(iPhone 6.3インチ・Play phone 1080×1920・フィーチャーグラフィック 1024×500)にする。例: `content/shakaifukushishi/store_copy.json`。
- [ ] プライバシーポリシー・サポートのページ: `06190528/apps-pages`(GitHub Pages)に `italianbrainrot/privacy/index.html` と `italianbrainrot/support/index.html` を追加する(既存: `shakaifukushishi/privacy/index.html` を雛形に)。**このアプリの実際のデータの流れを書く**: ①AdMob(個人に合わせない広告) ②表示名(ユーザーが入力・12文字まで)・スコア・端末ごとの乱数IDを Firestore(Google)に送り、**表示名はランキングで他のプレイヤーに公開される** ③Firebase Analytics は使っていない ④コイン・図鑑・設定は端末内のみ。プッシュは確認のあと。`app-ads.txt` は `06190528.github.io` に既にある(`google.com, pub-2847746899486154, DIRECT, f08c47fec0942fa0`)。
- [ ] 掲載文(説明・サブタイトル・キーワード・短い説明(Play 80字以内))。

### C. spec とステージ
- [ ] `~/pj/tools/chrome-hub/specs/italianbrainrot.toml` を書く(`shakaifukushishi.toml` を雛形に、**全項目を、このアプリの値で書き直す**。兄弟の `[declarations.*]` の回答は、Firebase Analytics があった前提なので、そのまま使わない)。
  - 収集するデータ: ASC・Play とも、AdMob(デバイスID・広告データ等)+ **ユーザーID(端末の乱数ID)・その他のユーザー作成コンテンツ(表示名)・ゲームのスコア(ゲームプレイ)**。Analytics 系(アプリ操作の計測)は、無い。
  - `[admob] enabled = true`。ただし **`admob` ステージは実行しない**(アプリを重複作成する。AdMobのアプリは削除できない)。`state/italianbrainrot.json` に、完了済みとして、次を先に書く: `"admob": {"done": true, "iOS_app_id": "ca-app-pub-2847746899486154~5568352293", "Android_app_id": "ca-app-pub-2847746899486154~6665031290"}`(`state/shakaifukushishi.json` と同じ形)。dry-run で、スキップされることを確認する。
  - 広告ユニットは作成済み(バナー・リワード・インタースティシャル)。ID は `lib/core/ads/ad_helper.dart` にある。
- [ ] ステージ順(`release.py`): `bundle_id → asc_app → play_app → (admob はスキップ) → build → testflight → listing → declarations → submit`。すべて、まず dry-run(既定)。実行は `--stage <名> --execute`。**ログイン切れで、最大600秒待つ**ので、`run_in_background` + Monitor で動かす。ASCのログインと2段階認証・Googleのログインは、自動化しない(ウィンドウが出るので、ユーザーに伝える)。

### D. ゲート → 確認 → 実行
1. `WITH_BUILD=1 tools/release_gate.sh`(AAB・iOSビルドも含む)が全部通る。通ったコミットのSHAから、ビルドする。
2. **まとめて確認(1回)**。下の「5」の値を、全部並べて、ユーザーに見せる。
3. 返答のあと、確認なしで、`bundle_id → asc_app → play_app → build → listing → declarations → submit` を実行。ゴール = **両ストアで審査提出まで**(公開は、審査後)。
4. 公開後: `admob link`(iOSは、App StoreのURL形式)・`admob_verify`。

## 4. 環境メモ(つまずき)
- Flutter は **`~/fvm/versions/3.35.4/bin/flutter` を直接**使う(`.fvm` は追跡から外した。`fvm flutter` は使わない)。3.24.5 では、flame が合わずビルドできない。
- `simctl` は `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` が要る。
- 統合テスト: `flutter drive --no-pub --driver=test_driver/integration_test.dart --target=integration_test/<名>_test.dart -d <UDID>`(`--no-pub` が無いと、pub.dev に繋がらない時にタイムアウト)。画像の読み込みは実時間で待つ(`tester.runAsync`)。`pumpAndSettle` は、Flame・キャラのアニメで終わらない。
- **`pkill -f flutter_tools` は、他のエージェントを巻き込むので、拒否される**。使わない。
- **GitHub Secret の書き込みは、権限で拒否される**(`backend/setup_ci.sh` は、ユーザーが `!` で実行した)。同様のものは、ユーザーに実行を頼む。
- macOS標準の bash は 3.2(配列の負の添字が使えない)。
- Flame 1.23: `GameWidget` は、再描画の組み立て中に `game.update(0)` を呼ぶ。`dt == 0` では、ゲームを進めない実装にしてある(状態を変えると例外になる)。
- キャラのシートは `tools/make_sheet.py`(使い方は先頭のdocstring)。音は `tools/convert_sounds.sh`。素材の出典は `asset_sources/SOURCES.md`。

## 5. 最後にまとめて確認する項目(案。取り消せない・本人の申告)
| 項目 | 案 | メモ |
|---|---|---|
| ストア表示名 | イタリアンブレインロット大戦争 | AdMob上の名前と同じ。ASCの名前は全体で重複不可。予備を用意(使用済みなら) |
| バンドルID / パッケージ名 | `com.okinnnikudekao.italianbrainrot` | **後から変更不可** |
| SKU | `italianbrainrot-001` | 後から変更不可 |
| カテゴリ | ゲーム(アクション) | |
| 年齢レーティング | 質問票で算出(軽いファンタジーの暴力のみの想定) | 本人の申告 |
| リリース方法 | 自動(審査通過後) or 手動 | 本人が決める |
| 著作権表記 | `2026 北野 篤輝` | 兄弟アプリと同じ |
| **コンテンツの権利(ASC)** | 「必要な権利を保有している」の宣言 | **法的な宣言。キャラは、ミーム由来のファン素材(ライセンス不明)。ユーザーは「指摘があれば取り下げる」と言っているが、宣言の文言は、ユーザー本人が決める** |
| AIアセットの申告(Play) | ストア画像・アイコンにAI生成が含まれるか | アイコンは、既存のキャラ画像から作った |
| Playのポリシー・米国輸出法への同意 | `--agree-play` | 本人の明示が要る |
| 審査提出 | `--stage submit --execute` | 取り消しにくい |
| 収集するデータの申告 | 上の「C」のとおり | 本人が最終確認 |

## 6. 参考(場所)
- 兄弟アプリ(リリース済み): `~/pj/minor-qualification-learning-apps/`(`tools/release/`・`tools/store_assets/`・`apps/shakaifukushishi/`・`docs/release.md`・`docs/troubleshooting.md`)。
- chrome-hub の状態: `~/pj/tools/chrome-hub/state/<アプリ>.json`(完了したステージとID)。ストアの画面の操作メモは `LISTING.md`(提出前チェック・AAB登録・審査提出の節)。
- AdMob の状態の確認(読むだけ): `cd ~/pj/tools/chrome-hub && .venv/bin/python -m sites.admob status`。
