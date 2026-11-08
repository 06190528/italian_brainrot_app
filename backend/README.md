# ランキングの仕組み(すべて無料の範囲)

```
アプリ ──(ハードのベストだけ)──▶ Firestore  scores/{端末ID}  ※ルールで保護
                                      │  毎日1回(GitHub Actions cron・読み取り専用の鍵)
                                      ▼
                         ranking.json を作る ──▶ ranking-data ブランチ
                                                      │ HTTPS (raw.githubusercontent.com)
アプリ ◀──────────── 取得して、自分の記録を、あるべき位置に差し込んで表示
```

| 部品 | 場所 | 役割 |
|---|---|---|
| Firestore ルール | `firestore.rules` | 認証なしで、自分の1件(ID=端末の乱数32桁)を作る・**上げる**だけ。読み取り・削除は全拒否 |
| 集計ジョブ | `ranking/` | `scores` から `ranking.json` を作る(上位100人+順位計算用のデータ) |
| 定期実行 | `../.github/workflows/ranking.yml` | 毎日 03:17(JST)。`ranking-data` ブランチに1コミットだけ置く(履歴は残さない) |
| 鍵の登録 | `setup_ci.sh` | 読み取り専用のサービスアカウントを作り、GitHub Secret に登録(1回だけ) |
| アプリ側 | `lib/data/ranking_service.dart` | 送信・取得・順位表の合成(`composeBoard`) |

## なぜ無料か
- **GitHub Actions**: 公開リポジトリは無料。Cloud Scheduler や Cloud Functions の定期実行は、課金設定(Blaze)が要るので使わない。
- **Firestore(Spark)**: 書き込みは「自己ベストを更新した時だけ」。読み取りは集計ジョブの1日1回だけ(1日の無料枠: 読み取り5万・書き込み2万)。
  - 5,000人まで: 全員のスコアを JSON に入れる → 順位は正確(読み取り=人数分)。
  - それ以上: 上位100人 + 集計クエリ(1,000件ごとに1読み取り)で、順位は概算(誤差は±数位)。
- **配信**: `ranking-data` ブランチの JSON を raw.githubusercontent.com から取得(キャッシュは約5分)。

## 初回セットアップ
1. `gcloud auth login`(ブラウザ)と `gh auth login`
2. `backend/setup_ci.sh`(サービスアカウント作成 → Secret `FIREBASE_SERVICE_ACCOUNT` に登録。鍵ファイルは残らない)
3. このリポジトリを push(ワークフローは、デフォルトブランチにあるものだけが動く)
4. GitHub の Actions → `ranking` → Run workflow で手動実行 → `ranking-data` ブランチに `ranking.json` ができる

## 運用上の注意
- 公開リポジトリは、60日間なにも活動が無いと、定期実行が止まる。このジョブは毎日 `ranking-data` に push するので、通常は止まらない(止まったら Actions タブから再有効化)。
- 不正なスコア: ルールで「0〜100000」「下げられない」だけを守っている。厳密な不正対策はしていない(カジュアルなゲームとして許容)。不正なスコアは、Firebase コンソールから該当のドキュメントを消せば、次の集計で消える。
- 名前の変更は、次に自己ベストを更新した時に反映される。
- ルールの変更: `cd backend && firebase deploy --only firestore:rules --project italian-brainrot-p3vkon`(反映に数十秒かかる)。
- ローカルで集計を試す: `cd backend && firebase emulators:exec --only firestore --project demo-ranking "cd ranking && node seed_emulator.mjs 300 && node build_ranking.mjs out/ranking.json"`(`RANKING_SMALL_LIMIT=100` で、概算モードを試せる)。
