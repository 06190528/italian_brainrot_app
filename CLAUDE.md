# CLAUDE.md (italian_brainrot_app)

## 新しいチャットは、最初にこれを読む(最新の状況と次の作業)

- **`docs/handoff_unresolved_2026-11-21.md` の冒頭**(「今どうなっているか」「次の作業」)を、作業の前に読む。リリース作業の全体の経緯は `docs/release_handoff.md`。
- 要点(2026-11-21 13:30): Playは7件を審査送信済み(審査待ち。通ると製品版がv4に更新される)。iOS 1.0.1は配信中。AdMobのAndroid Verify appは、launchdが自動で押す。
- **未了で、ユーザーの許可待ちの作業**: ランキング集計の再生成(`gh workflow run ranking.yml` → `ranking-data` ブランチの `ranking.json` の名前が `Player xxxx` になったか確認)。実行してよいか、ユーザーに聞く。
- 状況が変わったら、この節と引き継ぎ書の冒頭を更新する(次のチャットに伝わるように)。

## 自律開発

- ユーザーの介入なしで進める時は、`docs/autonomous_dev_guide.md` に従う(決める前の批判・情報の確からしさの評価・事前調査の方法・確認が必要な操作の線引き)。

## タスク管理(Notion)

このプロジェクトのNotionページとタスク表は作成済み。

- ページ: https://notion.so/4128edda02a3812b83d6d042141308ca
- 表: ページ内のインライン表 `タスク`(1タスク=1行。列: 名前・ステータス・作成日・予定日・完了日・メモ)
- 操作: `python3 /Users/kitano/pj/report_the_results/notion_tasks.py list|add|status --project italian_brainrot_app`
- 対応は `report_the_results/projects.json` の `notion.project_task_tables` に記録済み。ページを新しく作り直さない。

## リリース後の確認(chrome-hub)

- 審査・公開の状況は `docs/release_handoff.md` 冒頭の最新の確認メモを見る。再確認は `cd ~/pj/tools/chrome-hub && .venv/bin/python review_status.py italianbrainrot`(読むだけ。AdMob欄は `-m sites.admob status イタリアン` で別に読む)。
- chrome-hub のブラウザ(appstore/playstore)は他のエージェントも使う。`pgrep -fl "review_status|release.py|sites\."` で実行中でないことを確認してから使い、実行中なら終わるまで待つ。
