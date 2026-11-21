# 引き継ぎ: 最新の状況と次の作業(2026-11-21 13:30 更新。**まずここを読む**)

## 今どうなっているか
- **Play**: 送信ブロックは解決。原因は、内部テスト(vc3)・製品版(vc1)に、AD_ID付きの古い版が残っていたこと。両トラックを v4(vc4)で置き換え、**7件(製品版1.0.0(4)・Alpha 1.0.0(4)ほか)を13:15ごろ審査へ送信済み**(クイックチェック約14分→審査。通常7日以内)。内部テストは v4 を公開済み(13:08)。製品版は、通ると**公開中のアプリが v4 に更新される**(完全公開)。
- **iOS 1.0.1**: 「Ready for Distribution」(配信中。メール受信済み)。
- **AdMob**: iOSは Verify app 済み(確認済み)で、承認状況は「審査中」。Androidは Play 掲載に紐づけ済み(パッケージ名の完全一致で選ぶよう `link_store` を直した)。**Androidの Verify app は、自動で押す仕組みを入れた**(launchd `com.kitano.admob-verify-watch` が3時間おきに `admob_verify_watch.py` を実行。ログ: `~/pj/tools/chrome-hub/state/admob_verify_watch.log`。押せたら記録 `state/admob_verify_watch.json`)。
- **push**: アプリのリポジトリは 11/21 に `origin/master` へ push 済み(`2079937`まで)。その後の docs のコミットは未push。

## 次の作業(上から)
1. **Playの審査結果を待つ**: `cd ~/pj/tools/chrome-hub && HUB_OWN_TAB=1 .venv/bin/python closed_testing.py italianbrainrot overview`(「審査中の変更」→公開済み)。通ったら:
   - `prelaunch_report.py italianbrainrot` でリリース前レポート(クラッシュの原因)を読む。
   - 製品版の公開を確認(Playの掲載が v4 に更新されたか)。
   - Androidの Verify app が押されたか: `tail ~/pj/tools/chrome-hub/state/admob_verify_watch.log`、`python -m sites.admob status イタリアン`。
   - 否承認なら、`REJECTION_PLAYBOOK.md` を見て、理由を `docs/` に書く。
2. **ランキング集計の名前**: `gh workflow run ranking.yml`(または03:17 JST の定時)で再生成し、`ranking-data` ブランチの `ranking.json` の名前が `Player xxxx` になったか確認する(実行は、ユーザーの許可を取ってから。前回、聞いたまま未回答)。
5. **AdMobの承認状況**: 両OSとも「要審査/審査中・広告配信を制限」。広告リクエストが出てから数日。2〜3日変わらなければ、AdMobのポリシーセンターへ問い合わせる。
3. **iOS 1.0.1 の配信後の確認**: `curl "https://itunes.apple.com/lookup?id=6832495202&country=jp"` が `version: 1.0.1` か。
4. 古いFirestoreの名前は「消さない」と決定済み。

## 今回(11/21)で分かったこと・道具
- Playの「広告IDの申告が不完全」は、**Alpha以外のトラックの古い版**が原因だった。全トラックは `.../releases/overview` で見る。メモリ: `play-publish-overview-adid-block`。
- サポートチケット: `chrome-hub/play_support_ticket.py`(入力まで自動。`--send` で送信を押す→まず「AIによる提案」が出て、チケットはまだ作られない。作るなら `--create-ticket`)。送信後の録画・通信監視・最前面表示つき。今回はチケットを作っていない。
- 道具: `tools/store_ops/release_v4_from_library.py <track> --yes`(ライブラリのvc4で新リリースを保存。内部テストは最後に「保存して公開」が別に要る)、`alpha_v4_from_library.py`。バージョンコード4はライブラリにあり、再アップロードは不可。
- 注意: Playの下書きの破棄・申告の一時保存は、自動の安全確認で止まることがある(迂回しない。ユーザーに許可を取る)。chrome-hubの共有ブラウザは、他のエージェントも使う。

---
以下は、解決前の記録(経緯)。

# 引き継ぎ: 未解決の3件を解決する(2026-11-21 時点)

新しいチャットは、まずこのファイルを読む。次に `docs/release_handoff.md` の冒頭、メモリ(`~/.claude/projects/-Users-kitano-pj-italian-brainrot-app/memory/`。特に `kids-ads-families-policy`・`play-publish-overview-adid-block`・`asc-update-flow-gotchas`・`chrome-hub-shared-browser`・`dev-process-lessons`)、`~/pj/tools/chrome-hub/REJECTION_PLAYBOOK.md` の §6・§7。

## 0. これまでの経緯(要点)
- Playで v2 が「アプリの安定性」(ファミリー ポリシー要件)により否承認。v3(1.0.0+3)をAlphaから審査に送ったが、**対象年齢に13歳未満を含む申告**が、広告・名前・権限の実装と食い違っていた。
- ユーザーの決定: **子供を含めたまま、広告・実装を子供向けにそろえる(案b)**。年齢確認の画面は足さない(工数を増やしたくない)→ **全員を子供として扱う**。ランキングの名前は自動生成(`Player xxxx`)。
- 実装・コミット済み: `30028df`(名前)・`0688e25`(広告・権限・1.0.0+4)・`60f469d`(開発中の音を消す)・`140ab3f`(iOS用 1.0.1+4)ほか。ゲート全通過(`WITH_BUILD=1 tools/release_gate.sh`)。AABの権限は `check_aab.py` OK。Android 14 エミュレータで monkey 4000回クラッシュなし。
- iOS 1.0.1(4)を**審査に提出済み**(2026-11-21 2:45。審査待ち。リリース方法は自動)。年齢制限は 9+、プライバシーはユーザーID・ゲームプレイコンテンツを追加、プライバシーポリシーのページ(apps-pages)はpush済み。

## 1. 解決済みA(2026-11-21 13:20): Playの送信ブロック
**解決**: 原因は、内部テスト(vc3)と製品版(vc1)に、AD_ID付きの古い版が残っていたこと。両トラックをv4(`tools/store_ops/release_v4_from_library.py`)で置き換えたら、エラーが消え、7件を審査に送信した(製品版・Alpha)。**今は審査待ち**。以下は、解決前の記録。

**症状**: 公開の概要の「審査にまだ送信されていない変更」(6件: Alpha v4=1.0.0(4)・トラック再開・テスター・フィードバック先・対象年齢・データセーフティ)に、「1件の問題がすべての変更に影響しています: **広告IDの申告が不完全です**」と出て、「審査に送信」が無効。

**確認済みの事実**
- 広告ID(アプリのコンテンツ → 広告ID)は「いいえ」で保存済み(開き直して確認。保存/破棄ボタンは無効=未保存の変更なし)。
- アプリのコンテンツ一覧の「要注意」は0件(「対応済み」タブにある)。
- v4のAABは、`AD_ID`・`ACCESS_ADSERVICES_*` 4つの権限を外してある。
- `closed_testing.py ... send --yes` は、ボタンが無効で30秒待って失敗する。

**試して効かなかったこと**: ①「はい」→「いいえ」と保存し直し ②審査中のv3を「変更を削除」して、全変更を未送信にまとめ直し(v3は取り下げ済み。v4で置き換わる) ③クイックチェック(約14分)の完了待ち ④v3のAD_ID権限との食い違いという仮説は、取り下げ後も解消しなかったので外れ。

**次に試す候補(上から)**
1. v4の下書きを破棄して作り直す(`closed_testing.py italianbrainrot discard <track_id> <release_no>`、`tools/store_ops/alpha_v4.py`)。クイックチェックは、下書きの保存で再実行される可能性がある。**破棄の前に `overview` で中身を読む**。トラックIDは `closed_testing.py italianbrainrot track`(Alpha: `4701203365123825249`)。
2. 広告IDの宣言を、公開の概要の「申告を更新」のリンク(`?source=publishing-overview`)から開いて保存し直す(試したのは、リンクを開くところまで)。
3. 「広告」の宣言(アプリのコンテンツ → 広告)や、ターゲットユーザーを保存し直して、再評価されるか。
4. Playのヘルプ・サポートに問い合わせる。**文面は `docs/play_support_inquiry_adid.md`**(ユーザーが送る)。
5. 上のどれも効かない場合の別案: AD_ID権限を戻して、広告ID宣言を「はい」(目的=広告・不正防止)にして送る。ただし、13歳未満を含むアプリで広告ID権限が残るのは、ファミリー ポリシー上は弱い(広告は子供向けフラグで、広告IDは使われない想定)。**これはユーザーの判断が要る**(事前の質問では、問い合わせの文面まで作って止まる、と決めた)。

**状況の読み方(読むだけ)**: `cd ~/pj/tools/chrome-hub && HUB_OWN_TAB=1 .venv/bin/python <repo>/tools/store_ops/sendstate.py`(送信ボタンの有効/無効・広告IDのラジオ)、`qc_status.py`、`issue.py`。`closed_testing.py italianbrainrot overview` で中身。

**解決したら**: `closed_testing.py italianbrainrot overview` で、6件が揃っているか確認 → `send --yes`(Play/AdMobの送信は、ユーザーが事前に「確認なしでよい」と許可済み。2026-11-20)。送信後に `overview` で「審査中」へ移ったことを確認。通ったら、`prelaunch_report.py italianbrainrot` でリリース前レポート(クラッシュの原因)を読む。

## 2. 未解決B: AdMob
- **iOSの「Verify app」**: App Storeの掲載に紐づけ済み(11/21)。ボタンは、紐づけ直後は無効(反映待ち。最大24時間)。`python -m sites.admob verify "イタリアンブレインロット大戦争" iOS`(押せるまで再実行。ツールは文字でも探す版に直した)。前提の `app-ads.txt` は検査OK。iOS 1.0.1が通って配信されてから確認するのが確実。
- **Androidの紐づけ**: `python -m sites.admob link "イタリアンブレインロット大戦争" Android com.okinnnikudekao.italianbrainrot --dry-run` が「検索結果が2件」で止まる。**原因は未調査**。2件が何か(同じアプリの重複か、別のアプリか)を、検索結果の画面で確認する(`tools/store_ops/admob_read.py` か、`admob.py` の `link_store` の検索部分を読む)。1件になる検索語(開発者名を足す等)を探す。
- 両OSとも、AdMobの承認状況は「要審査・広告配信を制限しています」のまま。紐づけ・Verify・初回の広告リクエストのあとで変わるか見る(`python -m sites.admob status イタリアン`)。ユーザーの希望は「iOSにも広告を出す」。広告が出ない間は、審査には影響しない(テスト広告は、デバッグビルド)。

## 3. 未解決C: プッシュの判断(ユーザーに聞く)
- `git log --oneline origin/master..HEAD` が **63件**。うち今回の作業は約10件。残りは、以前からの未プッシュ分(素材・キャラの履歴を含む)。
- ユーザーの許可は「**このタスクに関わるpush**は確認なしでよい」。以前の分まで含めて公開してよいかは、聞いていない → **止めている**。
- **pushしないと、ランキング集計(GitHub Actions)の名前の自動生成が反映されない**。それまで、v1〜v3で入力された名前が、公開の `ranking.json`(`ranking-data` ブランチ)に出続ける。ユーザーに「62〜63件まとめてpushしてよいか」を聞く。OKなら `git push origin master`(強制pushはしない)。pushしたら、`gh workflow run ranking.yml`(または次の定時 03:17 JST)で再生成し、`ranking-data` の `ranking.json` の名前が `Player xxxx` になったか確認する。
- 古いFirestoreの名前の削除は、今回は「消さない」と決定済み。

## 4. 待ちの項目
- **iOS 1.0.1の審査結果**: `cd ~/pj/tools/chrome-hub && .venv/bin/python review_status.py italianbrainrot`(iOS欄)。通ったら自動でリリース。配信確認は `curl "https://itunes.apple.com/lookup?id=6832495202&country=jp"` が `version: 1.0.1`。却下(4.3など)なら `review_thread.py`(返信は `reply --send`、再提出は `resubmit`)。却下文は `state/review_thread_italianbrainrot.txt` に保存する。
- **Playの審査結果**(Aの解決後)。通ったらリリース前レポートと、製品版への出し方(v4を製品版の新しい下書きへ)を決める。

## 5. 現在の状態(2026-11-21 のスナップショット)
- アプリのリポジトリ: master、未コミットなし(未追跡は、ユーザーのファイル `backend/ranking/fake_users.json`・`import_scores.mjs` のみ。**触らない**)。pubspec は `1.0.1+4`(iOS用。Androidの v4 AAB は versionName 1.0.0 のまま Play の下書きにある)。
- chrome-hub のコミット: `e9c3beb`(spec・ASC年齢制限の新質問・プライバシーの型・`HUB_OWN_TAB`・`set_age_rating(update=True)`)、`09d92b4`(手順書)。chrome-hub には他のエージェントの未コミットの変更が多い。**自分が触ったファイルだけを `git add` する**。
- spec: `specs/italianbrainrot.toml` は `uses_ad_id=false`・`[release] version="1.0.1"`・`update_platforms=["ios"]`・`expected_rating="9+"`。
- 使い捨てスクリプトの保存先: `tools/store_ops/`(README に使い方)。

## 6. 注意(必ず守る)
- chrome-hub のブラウザは他のエージェントと共有。**操作前に、`ps -axo pid,etime,command | grep "release.py specs/"` で、他のアプリの `release.py` が動いていないか見る。`HUB_OWN_TAB=1` を付ける。**
- `tools/release_gate.sh` の実行中は、スクリプトも `lib/` も書き換えない。
- macOS の `sed -i` は `sed -i '' ...`。
- 開発中のアプリの音は消す(`--dart-define=MUTE_AUDIO=true`。ゲートと録画には入れてある)。
- コミットは区切りごとに。`Co-Authored-By` は書かない。コミットのたびに日報(`report_the_results/personal/<年>/<月>/<日>/daily_report.md`。**書く前に `date` で日付を確認**)も更新する。
- Play・AdMobの送信は、ユーザーが事前に許可済み(値は日報・引き継ぎ書に記録)。それ以外の外に出る操作(プッシュの範囲を超えるもの、Notion公開など)は、聞いてから。
