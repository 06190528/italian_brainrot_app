#!/bin/bash
# 審査(App Store)に添付する、操作の録画を作る。専用シミュレータで通しのテスト(flow_test)を流しながら録画する。
# 使い方: tools/record_review_video.sh [テスト名(既定 flow)]
# 出力: store/review_demo/recording.mp4(撮ったまま) / recording_attach.mp4(720px・無音。ASCの添付用。spec の [review].video に指定する) / flow.log
# 注意: 専用シミュレータ(SIM_UDID)だけを使う。ビルド中の画面を撮らないよう、アプリにつながってから録画を始める。
set -uo pipefail
cd "$(dirname "$0")/.."
NAME="${1:-flow}"
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.35.4/bin/flutter}"
SIM_UDID="${SIM_UDID:-4C81E0DD-3457-4012-87C3-71B18916516B}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
OUT=store/review_demo; mkdir -p "$OUT"; : > "$OUT/flow.log"; rm -f "$OUT/recording.mp4" "$OUT/recording_attach.mp4"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
"$FLUTTER" drive --no-pub --dart-define=MUTE_AUDIO=true --driver=test_driver/integration_test.dart --target="integration_test/${NAME}_test.dart" -d "$SIM_UDID" > "$OUT/flow.log" 2>&1 &
DRIVE=$!
until grep -q "Isolate found" "$OUT/flow.log" 2>/dev/null || ! kill -0 $DRIVE 2>/dev/null; do sleep 0.3; done
xcrun simctl io "$SIM_UDID" recordVideo --codec=h264 --force "$OUT/recording.mp4" >/dev/null 2>&1 &
REC=$!
wait $DRIVE; RC=$?
kill -INT $REC 2>/dev/null; wait $REC 2>/dev/null
ffmpeg -loglevel error -y -i "$OUT/recording.mp4" -vf scale=720:-2 -c:v libx264 -crf 27 -pix_fmt yuv420p -an "$OUT/recording_attach.mp4"
echo "テストの終了コード: $RC / 添付用: $OUT/recording_attach.mp4($(du -h "$OUT/recording_attach.mp4" | cut -f1))"
exit $RC
