# 素材収集 成果報告(`asset_collection_handoff.md` への回答)

作成日 2026-11-09(作業は 2026-11-08〜09)。依頼は「素材を探して `asset_sources/` に保存し、出典を記録する」まで。**スプライトシート化(`tools/make_sheet.py`)は範囲外なので行っていない。**

## 1. 結論

| 区分 | 目標 | 結果 | 評価 |
|---|---|---|---|
| キャラ | 51種(最低30) | **110種** | 数は十分。95種は動くアニメ付き(後述の欠けあり) |
| BGM | 2曲 | 2曲(通常は 24.5 秒のループ。フィーバーは破損の疑い) | 不十分。ユーザー判断で**後回し**(元アプリの音を流用する前提) |
| 効果音 | 9種 | 9種(CC0・Kenney 等) | 使えるが、ガチャ音は単発、クリア音は11秒と長い |
| 背景 | タイトル(横長)/プレイ(縦長) | 各1枚+別案(写真。タイル不可) | 使える。CC BY / CC BY-SA の出典表記が必要 |
| UI | コイン、カプセル、鍵、爆発 | 4種とも有り(低解像度のドット絵あり) | カプセル 32px・爆発 16px は拡大が必要 |

保存先は `asset_sources/`(git管理外。`SOURCES.md` と `characters.csv` だけ追跡)。出典は **全ファイルを `SOURCES.md` に1行ずつ記録済み**(キャラ213行+背景・UI・音30行)。

## 2. キャラの構成

`asset_sources/characters/NNN_slug/`(**NN は3桁**。110種のため。並びは THE BYAN 動画の紹介順=知名度順を基本に、動画に無い旧収集分を末尾に置いた)。

| ファイル | 内容 |
|---|---|
| `src.*` | そのキャラの最良の素材。多くは `src.webp`(動画から背景抜きした透過アニメ) |
| `src_alt_site.png` | THE BYAN サイトの全身の透過静止画 1024px(44種) |
| `src_alt_green.mp4` / `src_alt_green_keyed_test.webm` | YouTube 緑背景動画(旧収集。16種。背景は未抜き) |
| `src_alt_old.*` / `src_alt_still.*` | 旧収集の GIF・Roblox 由来の静止画 |
| `ref.png` | 確認用の静止画1枚 |

`characters.csv` の `note` に、tier(1=透過アニメ / 2=単色背景動画 / 3=透過静止画)・動画切り出しの品質・代替素材・日本語名・**名前の確からしさ(確認済/仮/不明)** を入れた。

### 主素材の出どころ
- **THE BYAN の動画**(YouTube `Q2nh4RdTQ6Y`、100体を1体ずつ紹介。黒背景、1080p)から、黒背景を滑らかにアルファ化して切り出した(95種)。
- 切り出しの手順は `asset_sources/_tools/byan_cutout.py`(処理内容は先頭の docstring)。統合は `final_merge.py`。実行には numpy・Pillow・opencv-python-headless が要る(scratch の venv を使った)。

## 3. 品質の評価(正直に)

- **良い点**: 絵柄が揃っている。名前が字幕で分かるので取り違えがほぼ無い。上半身は十分にきれい(黒目や暗い服も不透明で残る)。解像度は 400〜512px 級。
- **全体に共通する問題**:
  1. **足元に字幕がかかっていたため、足元に文字の形の透明な穴が残る**(動画由来 95 種のうち 90 種で字幕が重なる。きれいと判定できたのは 4 種)。囲まれた穴は補完したが、体の外形にかかる部分は復元できない。ユーザーが「足元の欠けは許容」と判断済み。
  2. **クリップが短い**(多くは 1〜2 秒。1 秒未満もある)。ループのつなぎ目は未確認。
  3. **画面の外へ出るフレームを落としたもの(16 種)**は、動きがさらに短い(Bombardiro Crocodilo など)。
  4. 暗い影の部分は半透明になるため、背景によっては縁が目立つ可能性。
- **個別の不具合**: Ballerina Cappuccina は吹き出しの文字「恋」が1文字残る。079(Egrolli Grele Frutora)は下端が切れる。Garamaraman・Nodino Dildrino・Totototo Sahur・Bombardiro Crocodilo・Ti Ti Ti Sahur は短辺 256px 未満。
- **動画の切り出しを諦め、代替素材にしたキャラ**(15 種): 067(Nuclearo Dinossauro)・097(Bambini Crostini)・099(Brr Brr Mamabim)などは、動画側に不具合があるため、サイトの静止画か旧収集の静止画を `src` にしている。34・80 は動画から取れていない。

## 4. 名前の扱い(要確認)
- 確認済み 58(名簿 `_parts/roster.csv`)/ **仮 44**(動画字幕のカタカナからの読み。例: `gangster-footera`、`sigma-boy`、`jin-jin-jin-login`)/ 不明 8(字幕が読めない: `unknown-NNN`)。
- 仮・不明の名前は、公式の綴りが分からない。**使う前に人の確認が必要。**

## 5. 権利・出典
- ユーザーが権利を引き受ける前提(引き継ぎ書どおり)。ライセンスは、ほぼ全キャラが「不明」(YouTube・サイト掲載・Roblox のゲーム画像)。
- 画像の出どころ: THE BYAN(動画・サイト)、YouTube の緑背景動画(Green Screen Memes / UltraKey など)、rblxguide 掲載の Roblox ゲーム画像、Giphy・Tenor。
- 背景: Wikimedia Commons(CC BY 4.0 / CC BY-SA 4.0 — **表記が必要。SA は同条件の公開が必要**)。音・UI: CC0(Kenney・OpenGameArt)。

## 6. 行った判断(ユーザーの指示)
1. 素材の主は THE BYAN の動画。足元の欠けは許容する。
2. 取れている素材(緑背景動画など)はそのまま代替として残す。
3. 音は後回し。不足分は元アプリの音を流用する。
4. 名簿の追加(51種を超えて)は後で行う。
5. 収集だけで止める(スプライトシートは作らない)。

## 7. 未解決・次の作業の候補
- **シート化**(`make_sheet.py`)は未着手。元の素材は 12fps・最大辺 512px のアニメ付き WebP が中心。8列・256px 規格へのリサイズ時に、足元の穴をどう扱うか(穴の位置で下端を切る、静止画で補うなど)を決める必要がある。
- THE BYAN サイトの図鑑は「もっと見る」で続きを読み込む作りで、約430件が未取得。ブラウザで全件を読み込んだ HTML があれば、全身の静止画を増やせる(48 種が 100px の低解像度のみ、6 種は未発見)。
- 動画で切り出せなかったキャラの個別直し(34・80・67・97・99)。
- 音: フィーバー BGM の差し替え(現ファイルは破損の疑い)、ガチャの連続回転音、クリア音の短縮、声のミーム音、イタリア風の BGM。
- 3D(Sketchfab のアニメ付きモデルが名簿上位 14 種にある)は、ログインが必要なため未取得。

## 8. 作業メモ(同じ失敗をしないため)
- **`research` の Chrome に Playwright 1.64 で接続できない**(`Browser.setDownloadBehavior` が非対応)。puppeteer-core(`~/pj/スクレイパー/tact/node_modules`)で、既存タブだけを使うと動く。新しいタブを開くと窓が前面に出る。
- YouTube は既定のクライアントだと 360p になる。`--extractor-args "youtube:player_client=web_embedded"` で 1080p が取れる。
- Giphy の公開 API キー・Tenor の検索は使えない。Wikimedia Commons は連続アクセスで 429(3秒あける)。
- キャラの検索は、Giphy・Tenor の名前検索ではほぼ当たらない。実在名の確認は Know Your Meme・Wikipedia・Bitrue 一覧が確実。
- Wikimedia Commons 上の画像は、不透明か、アルファが全面 255 のものが多く、使えなかった。
- 作業の一時ファイルと失敗した試行は scratch に残してある。旧56種の収集結果は `characters/_old56/` に退避してある(統合前の `characters.csv` と `SOURCES.md` はそれぞれ scratch に保存)。
