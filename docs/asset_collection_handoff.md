# 引き継ぎ書: イタリアンブレインロット素材の調査・収集

あなたは素材収集担当です。コードは書かず、素材を探して所定の場所に保存し、出典を記録してください。
背景: `/Users/kitano/pj/saibai_men_app`(猫ミームのガチャ&シューティング)のイタリアンブレインロット版を、`/Users/kitano/pj/italian_brainrot_app`(Flutter)で作る。設計は同リポジトリの `docs/plan.md` を先に読むこと。

## 作業ルール
- **調査は、chrome-hub の `research` プロファイル(ログインなしの調査専用Chrome、ポート9363)で行う。** MCPではなく、Playwright(CDP接続)で操作する。使い方は `/Users/kitano/pj/tools/chrome-hub/CLAUDE.md` と `KNOWLEDGE.md`(詰まった時はまずここ)を読むこと。
  ```python
  import sys; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
  from hub import connect, get_page
  with connect("research") as ctx:      # 未起動なら隠れて起動する
      page = get_page(ctx, "google.com")  # 既存タブを使い回す(bring_to_front しない)
  ```
  実行は `/Users/kitano/pj/tools/chrome-hub/.venv/bin/python` で。`tact` `sub-job` `job` `appstore` `playstore` のプロファイルは使わない(ログイン済みの別用途のため)。使い終わったら、自分で開いたタブは閉じる。ファイルの保存だけは、ブラウザで見つけた直リンクを `curl -L -o` で取得してよい。
- **ログインが必要なページ、課金・購入・投稿・コメントなどの操作はしない。** 閲覧とダウンロードだけ。
- **権利は、ユーザーが引き受ける(問題があれば取り下げる)ので、ライセンスで取得を止めなくてよい。** ただし、ライセンスが明記された素材(CC0 / CC-BY / 自由利用可)があれば、同じ品質ならそちらを選ぶ。
- 全ファイルについて、出典URL・作者・ライセンス(分かる範囲。不明なら `不明`)・取得日を記録する(下記 `SOURCES.md`)。取り下げ依頼が来た時に、すぐ該当ファイルを特定できるようにするため。記録の無いファイルは作らない。
- 保存先は **`/Users/kitano/pj/italian_brainrot_app/asset_sources/` の下だけ**。ほかのファイル(`lib/`、`assets/`、元アプリ)は変更しない。コミット・プッシュはしない。

## 保存先と命名
```
asset_sources/
  SOURCES.md            # 1素材=1行の表: パス | 出典URL | 作者 | ライセンス | 取得日 | メモ
  characters.csv        # キャラ一覧(下記の列)
  characters/NN_slug/   # NN=進行順の2桁(00〜), slug=小文字ハイフン区切り(例 00_tung-tung-sahur)
      src.gif|webp|apng|mp4|webm|png   # 生データ。最良の1つ(複数あれば _alt1 を付ける)
      ref.png                          # 確認用の静止画1枚
  sound/bgm/            # bgm_main.*, bgm_fever.*
  sound/se/             # explosion, game_clear, gatya, get_character, get_coin, get_item, special_move, hit_1, hit_2
  bg/                   # title(横長), play(縦長スクロール)
  ui/                   # 任意(コイン、カプセル、鍵、爆発など)
```

## 1. キャラクター(最優先 / P0)
**目標51種、最低30種**。有名どころから集める(例: Tung Tung Tung Sahur, Tralalero Tralala, Bombardiro Crocodilo, Ballerina Cappuccina, Cappuccino Assassino, Chimpanzini Bananini, Lirili Larila, Brr Brr Patapim, Bombombini Gusini, Trippi Troppi, Boneca Ambalabu, Glorbo Fruttodrillo など。実在名は検索で確認すること。名前を創作しない)。
- 進行順は、序盤(弱そう・小さい・有名度が高い)→終盤(ボス級・派手)の目安で並べる。判断理由は `characters.csv` のメモに一言。
- **素材の優先順位**: ① 背景が透過のアニメ(透過GIF / APNG / WebP / WebM-alpha) → ② 背景が単色のループ動画/GIF(後でこちらで抜く) → ③ 背景が透過の静止画PNG(こちらで擬似アニメを付ける)
- 解像度は、1辺256px以上。小さすぎるもの(<128px)、透かし・文字・ロゴ入りは避ける。
- `characters.csv` の列: `id,slug,name,origin(出典作品や作者),rarity(1-5の推定),format(gif/png等),has_alpha(y/n),width,height,frames_or_duration,license,source_url,note`

## 2. 音(P1)
- BGM 2曲: 通常(ループ可、ゲーム中に流れ続けても疲れない)、フィーバー(テンポ速め)。可能なら30秒〜2分のループ素材。長さ・BPM・ループ可否をメモ。
- 効果音 9種(上のファイル名): 爆発、クリア、ガチャ回転、新キャラ獲得、コイン、アイテム、必殺技、被弾×2。短い(〜3秒)もの。**ブレインロットらしい声・ミーム音**が使えるものがあれば、被弾/獲得音の候補として別にメモ。
- 形式はmp3/wav/ogg。ライセンスがCC0かそれに準ずるサイト(例: Pixabay, Freesound(CC0フィルタ), OpenGameArt)を優先。

## 3. 背景・UI(P2、余裕があれば)
- ホーム/ガチャ用の横長背景(1500px以上)。ゲーム用の縦長スクロール背景(幅1600前後、縦に繋がる素材)。イタリア要素(街並み・石畳・カフェ・地中海)を優先。
- コイン・ガチャのカプセル・鍵のアイコンなど。見つからなければ、そのまま「無し」と報告してよい(こちらで生成や流用をする)。

## 完了条件・報告
1. `asset_sources/SOURCES.md` と `characters.csv` が、保存したファイルと1対1で対応している。
2. 以下を、短く報告する(ファイル全文は貼らない): 取れたキャラ数/目標、取れなかった区分、懸念(透過が無いキャラ、解像度が低いキャラ)。
3. 途中でも、キャラ10種ごとに `characters.csv` を保存して進める(中断しても成果が残るように)。
