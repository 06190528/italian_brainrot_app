# Google Play の配信国: EEA・英国は対象にしない

**方針(ユーザーの指示、2026-11-09): Android(Google Play)は、EEA(EU27+ノルウェー・アイスランド・リヒテンシュタイン)と英国を、配信の対象にしない。**

## 理由
- イギリスなどを配信対象にすると、デベロッパーが「取引業者(トレーダー)」として扱われ、**住所などの連絡先がストアのページに公開される**。これを避けたい。
- Play の「非取引業者」の宣言は、EEA・英国に配信しないことが条件(Play ヘルプ answer/17594752)。
- App Store 側は、アカウント側で「ノントレーダー」と宣言済み(アプリ側では操作しない。`spec` の `[declarations.asc] trader = "inherit"`)。

## 実施方法(`release.py` の `submit` ステージ)
1. `set_countries_all`: 本番トラックの「国 / 地域」を、すべて選択する(国が0だと、提出前のプレビューでエラーになる)。
2. `sites.playstore_countries.exclude_eea_uk`: EEA と英国のチェックを外して保存する(冪等)。保存後に「ターゲット設定済み(N)」と、対象国がすべて外れたかを読み戻して表示する。
- 単独で実行する時: `cd ~/pj/tools/chrome-hub && .venv/bin/python -m sites.playstore_countries italianbrainrot [--dry-run]`
- **提出のあとに、「国 / 地域」タブを開いて、EEA・英国が外れていることを、もう一度確認する**(外れていないまま公開すると、住所が公開される)。

## 注意
- アプリの広告の同意(UMP)は、EEA・英国向けの仕組み。配信しない地域でも、旅行中のユーザーなどのために残してある(害はない)。
- 後から配信国を増やす時は、この方針を確認する(EEA・英国を入れない)。
- 同じ方針は、兄弟アプリ(`minor-qualification-learning-apps`)の全アプリにも適用している。
