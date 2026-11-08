#!/bin/bash
# asset_sources/sound/ の ogg(iOSで再生できない)を、assets/sounds/ の mp3 に変換する。
# 使い方: tools/convert_sounds.sh
# 対応: bgm/bgm_main.ogg→bgm_main.mp3, bgm/bgm_fever.ogg→bgm_fever.mp3, se/<名前>.ogg→<名前>.mp3
set -e
cd "$(dirname "$0")/.."
SRC=asset_sources/sound
OUT=assets/sounds
mkdir -p "$OUT"
conv() { ffmpeg -v fatal -y -err_detect ignore_err -i "$1" -ac 2 -ar 44100 -c:a libmp3lame -b:a 128k "$2" && echo "  $2"; }
conv $SRC/bgm/bgm_main.ogg  $OUT/bgm_main.mp3
conv $SRC/bgm/bgm_fever.ogg $OUT/bgm_fever.mp3
for n in explosion game_clear gatya get_character get_coin get_item hit_1 hit_2 special_move; do
  conv $SRC/se/$n.ogg $OUT/$n.mp3
done
