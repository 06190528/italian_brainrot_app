# store_ops: 2026-11-20/21 のストア操作で使った、使い捨てスクリプトの保存(chrome-hub の `.venv` で動かす)

どれも `cd ~/pj/tools/chrome-hub && HUB_OWN_TAB=1 .venv/bin/python <このフォルダ>/<名前>.py [引数]`。実行前に、他のエージェントが同じブラウザを使っていないか見る(`ps -axo pid,etime,command | grep "release.py specs/"`)。パスは、書いた時点の値(アプリのID・scratchpad)なので、必要なら直す。

| ファイル | 何をするか | 書き込み |
|---|---|---|
| `sendstate.py` | Playの公開の概要の「審査に送信」ボタンが有効か、広告ID申告のラジオの状態を表示 | 読むだけ |
| `qc_status.py` | クイックチェックの残り時間・問題の有無・送信ボタンの有無を1行で表示 | 読むだけ |
| `issue.py` | 公開の概要の「問題を表示」の中身を表示 | 読むだけ |
| `withdraw.py` | 審査中の変更を「変更を削除」で取り下げる(全変更が未送信に戻る) | **書く** |
| `alpha_v4.py` | AABを直接アップロードして、Alphaの下書きを保存(ライブラリの先頭行を選ばない版)。`AAB`・`NEW`・`NOTES` を直してから使う | **書く** |
| `ds_export.py` | データセーフティのCSVをエクスポート(質問IDの確認用) | 読むだけ |
| `asc_age.py` | ASCの年齢制限の質問票を最後まで入力して、止まる質問を表示(保存せずキャンセル) | 読むだけ |
| `asc_priv2.py` | ASCのアプリのプライバシーに、データタイプ(`NEW`)を足して設定。**次回は `appstore_privacy.py` に取り込むとよい** | **書く** |
| `admob_read.py` | AdMobの任意のページの本文を表示(例: アプリ設定 `https://admob.google.com/v2/apps/<数字>/settings`) | 読むだけ |
| `alpha_v4_from_library.py` | Alphaの未公開リリース(prepare画面)に、ライブラリの versionCode 4 を追加して保存(`alpha_v4.py` が「バージョン コード 4 はすでに使用されています」で上げられない時用。引数=リリース番号) | **書く** |
| `release_v4_from_library.py` | 指定トラック(internal-testing / production など)に、ライブラリの vc4 で新しいリリースを作って保存(`--yes` で保存。内部テストは最後に別途「保存して公開」が要る) | **書く** |
