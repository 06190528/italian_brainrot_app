#!/bin/bash
# 元アプリ(saibai_men_app)と同一のアセットが、このアプリの assets/ に無いことを確認する(md5で比較)。
# 4.3(a) スパム対策: 画像・音を共有していないことを、ゲートで保つ。
# 使い方: tools/check_shared_assets.sh   (一致が1件でもあれば終了コード1。元アプリのフォルダが無ければスキップ)
# 環境変数: SRC(既定 ~/pj/saibai_men_app/assets)
set -uo pipefail
cd "$(dirname "$0")/.."
SRC="${SRC:-$HOME/pj/saibai_men_app/assets}"
[ -d "$SRC" ] || { echo "元アプリが無いのでスキップ: $SRC"; exit 0; }
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
find "$SRC" -type f ! -name .DS_Store -exec md5 -r {} + | awk '{print $1}' | sort -u > "$tmp"
dup=0
while IFS= read -r f; do
  m=$(md5 -q "$f")
  if grep -q "^$m$" "$tmp"; then echo "共有: $f"; dup=$((dup+1)); fi
done < <(find assets -type f ! -name .DS_Store)
if [ $dup -eq 0 ]; then echo "元アプリと同一のアセットは0件"; else echo "元アプリと同一のアセットが ${dup} 件ある"; exit 1; fi
