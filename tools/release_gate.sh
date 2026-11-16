#!/bin/bash
# リリース前のゲート: 貯めたテストを全部流し、1つでも落ちたら終了コード1。全部通ったらリリースする(メモリ: tests-gate-release)。
#
# 使い方:
#   tools/release_gate.sh              # 解析・単体・Node・iOSシミュレータの統合テスト・ボットのシミュレーション
#   WITH_BUILD=1 tools/release_gate.sh # さらに Android の AAB と iOS のリリースビルドを作って検査する(時間がかかる)
# 環境変数: FLUTTER(既定 ~/fvm/versions/3.35.4/bin/flutter) / SIM_UDID(専用シミュレータ。既定 italian-brainrot-dev)
# ログ: build/gate/<名前>.log
# 並列: シミュレータを使うテスト(drive_*)は1台を共有するので直列。ほかの独立した重い処理(AABのビルド・ボットのシミュレーション)は、これと並列に流す。
# 注意: 他のエージェントのシミュレータ・エミュレータは使わない。実機は使わない(エミュレータだけで検証する方針)。
set -uo pipefail
cd "$(dirname "$0")/.."
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.35.4/bin/flutter}"
SIM_UDID="${SIM_UDID:-4C81E0DD-3457-4012-87C3-71B18916516B}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
LOG=build/gate; mkdir -p "$LOG"
failed=0

run() { # run <名前> <コマンド...>。結果の1行を build/gate/<名前>.result に書く(並列でも混ざらない)
  local name="$1"; shift
  local start=$SECONDS line
  if "$@" > "$LOG/$name.log" 2>&1; then line="PASS  $name ($((SECONDS-start))s)"; else line="FAIL  $name ($((SECONDS-start))s) → $LOG/$name.log"; fi
  echo "$line" > "$LOG/$name.result"
  echo "$line"
}
rm -f "$LOG"/*.result

xcrun simctl list devices | grep -q "$SIM_UDID" || { echo "シミュレータ $SIM_UDID が無い"; exit 2; }
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true

run analyze      "$FLUTTER" analyze --no-pub
run unit         "$FLUTTER" test --no-pub
run shared_assets tools/check_shared_assets.sh
run node         bash -c 'cd backend/ranking && npm test'

# 独立した重い処理は、バックグラウンドで並列に流す(シミュレータも ios/ も使わない)
run balance_sim  "$FLUTTER" test --no-pub tool/balance_sim_test.dart &

# シミュレータを使うテストは直列
for t in flow play ranking; do
  run "drive_$t" "$FLUTTER" drive --no-pub --driver=test_driver/integration_test.dart --target="integration_test/${t}_test.dart" -d "$SIM_UDID"
done

# リリースビルドは、drive(debugビルド)のあとに流す。並列にすると、プラグイン登録ファイル(GeneratedPluginRegistrant.java)を
# 書き換え合い、AABが integration_test を参照して落ちる(2026-11-16)。AABとiOSは、別のフォルダなので並列でよい。
if [ "${WITH_BUILD:-0}" = "1" ]; then
  rm -f android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
  run build_aab  "$FLUTTER" build appbundle --release --no-pub &
  run build_ios  "$FLUTTER" build ios --release --no-codesign --no-pub
fi
wait

echo; echo "===== ゲートの結果 ====="
for n in analyze unit shared_assets node balance_sim drive_flow drive_play drive_ranking build_aab build_ios; do
  [ -f "$LOG/$n.result" ] && { cat "$LOG/$n.result"; grep -q "^FAIL" "$LOG/$n.result" && failed=1; }
done
if [ $failed -eq 0 ]; then echo "全部通った"; else echo "落ちたテストがある(リリースしない)"; fi
exit $failed
