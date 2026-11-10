# 引き継ぎ: Play のターゲット層を「18歳以上」以外にも対応させる(別チャットで開発)

> **2026-11-11 対応済み**: `set_target_audience_multi`(`sites/playstore_content.py`)を追加し、spec の `target_audience` をリストで指定できるようにした。13歳未満を含む時の申告は spec の `[play.family]`(法的宣言・広告の設問「はい」・教師承認「含めない」)から読む。本アプリは「5歳以下〜18歳以上」で保存済み。広告の子ども向け設定・表示名の公開の見直しは、後で対応(ユーザーの方針)。Apple は 13+ のまま(表示名の公開=ユーザー作成コンテンツのため。回答を偽って下げない)。


作成: 2026-11-09 / 対象ツール: `~/pj/tools/chrome-hub`(`release.py`・`sites/playstore_content.py`)

## 背景
- 本アプリ(イタリアンブレインロット大戦争)は、ユーザーが「年齢層を広げたい(何歳でも)」と希望した。
- `release.py` の `declarations` ステージは、Playのターゲット層を **「18 歳以上」しか入力できない**。それ以外は `NotImplementedError` で止まる。
- 今日(2026-11-09)の審査提出を優先して、**いったん「18歳以上」で提出した**。ターゲット層は、後から Play Console で変更できる。
- Play の制限ではなく、**ツールの未実装**。兄弟アプリは全部18歳以上だったので、今まで不要だった。

## 該当コード
- `sites/playstore_content.py` の `set_target_audience(app_id, age_label, *, dry_run=False)`
  - `age_label != "18 歳以上"` なら `NotImplementedError("18 歳以上以外の対象年齢層は、追加の質問(子供向けの設問)があるので未実装")`
  - 18歳以上だけを選ぶと、子ども向けのステップが省略され、概要の「保存」になる(`_wizard(app_id, "target-audience-content", ...)`)。
- `release.py` の `stage_declarations`: spec の `[play].target_audience`(例 `"18歳以上"`)を、`re.sub(r"^(\d+)(歳以上)$", r"\1 \2", ...)` で、画面の表記(`"18 歳以上"`)に直して渡している。**「13〜15歳」のような範囲や、複数の年齢層の指定の仕様は、まだ無い**(spec の書き方から決める)。
- spec: `specs/italianbrainrot.toml` の `[play] target_audience`(コメントに経緯あり)。

## やってほしいこと
1. Play Console の「ターゲット ユーザーおよびコンテンツ」(URL: `app/<play_app_id>/app-content/target-audience-content`)で、18歳以上以外を含めた時に出る**追加のステップ(質問)を、実際の画面で確認する**。
   - 想定: 対象年齢層の選択(5歳以下 / 6〜8 / 9〜12 / 13〜15 / 16〜17 / 18歳以上、複数選択)→ ストアの掲載情報の確認 → 「子どもにとって魅力的か」などの設問 → 概要 → 保存。実際の画面で確かめること。
2. 年齢層を spec で指定できるようにして(例: `target_audience = ["13〜15歳", "16〜17歳", "18歳以上"]` など)、追加の設問に、spec の値で答えるコードを書く。値は既定で埋めず、spec から読む(本人の申告は、既定値で埋めない: `KNOWLEDGE.md`)。
3. 冪等にする(すでに同じ内容なら、何もしない・保存しない)。`dry_run=True` は、入力して読み戻すだけで、保存しない。

## 画面を調べる時の注意
- **ページが開けない時がある**: ターゲット層のページは、前提(「広告」「ログインの詳細」の記入)が済んでいないと、開けない(「[広告] の記入を完了」のような表示になる)。`dry_run` は保存しないので、新規のアプリでは、前提を先に実行モードで保存する必要がある。
- 画面を見るには、`hub.connect(PROFILE)` + `get_page(ctx, "play.google.com/console")` で開き、`page.evaluate("document.body.innerText")` を読む(`sites/playstore_release.py` の `_open` と同じ)。
- 試す相手のアプリ: 本アプリの Play アプリID `4974213252958685020`(`state/italianbrainrot.json`)。**本番の申告が、実際に変わる**ので、実行モードで保存する前に、ユーザーに確認する。dry-run(入力して読み戻すだけ)を、先にする。
- ログインが切れると、ウィンドウが出る(最大600秒待つ)。ログインと2段階認証は、自動化しない。

## 年齢層を広げる前に確認すること(ユーザーに伝える)
13歳未満を含める(または、子どもにとって魅力的だと答える)と、Play の**ファミリー向けポリシー**の対象になる。本アプリでは、次の点が衝突する可能性がある。
- 広告: `tagForChildDirectedTreatment: no`(子ども向けではない)・非個人化広告で配信している。ファミリー向けは、認定された広告SDKの使用・子ども向けの設定が要る。
- ランキング: 表示名(ユーザー入力・12文字まで)・スコア・端末の乱数IDを Firestore に送り、**表示名を他のプレイヤーに公開**している。子どもの個人情報の扱いに関わる。
- ガチャ: コインのみ(課金なし)。ファミリー向けでの扱いを確認する。
- ASC(App Store)側の年齢レーティング・プライバシーの申告とも、整合させる。

## 関連する、ほかのツールの未対応(確認中・別チャットで一緒に見てよい)
- ASC の「アプリのプライバシー」で、`TYPE_LABELS`(`sites/appstore_privacy.py`)に無いデータタイプ: `OTHER_USER_CONTENT`(その他のユーザコンテンツ=表示名)・`GAMEPLAY_CONTENT`(ゲームプレイコンテンツ=スコア)。`USER_ID`(乱数ID)は、ある。
- Play のデータセーフティ(`sites/playstore_datasafety.py`)で、乱数ID・表示名・スコアの種類のID(`PSL_...`)。spec の `[declarations.play.collected.*]` に、TODOとして書いてある。
- Play の IARC(コンテンツのレーティング)の**ゲーム版の質問票**(`app_type = "ゲーム"`)は、今回が初めて。
- 詳細は `specs/italianbrainrot.toml` の `TODO` コメントと、`docs/release_handoff.md`。
