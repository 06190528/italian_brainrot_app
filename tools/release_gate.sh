#!/bin/bash
# リリース前のゲート: 貯めたテストを全部流し、1つでも落ちたら終了コード1。全部通ったらリリースする(メモリ: tests-gate-release)。
#
# 使い方:
#   tools/release_gate.sh              # 解析・単体・Node・iOSシミュレータの統合テスト・ボットのシミュレーション
#   WITH_BUILD=1 tools/release_gate.sh # さらに Android の AAB と iOS のリリースビルドを作って検査する(時間がかかる)
# 環境変数: FLUTTER(既定 ~/fvm/versions/3.35.4/bin/flutter) / SIM_UDID(専用シミュレータ。既定 italian-brainrot-dev)
# ログ: build/gate/<名前>.log
# 注意: 他のエージェントのシミュレータ・エミュレータは使わない。実機は使わない(エミュレータだけで検証する方針)。
set -uo pipefail
cd "$(dirname "$0")/.."
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.35.4/bin/flutter}"
SIM_UDID="${SIM_UDID:-4C81E0DD-3457-4012-87C3-71B18916516B}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
LOG=build/gate; mkdir -p "$LOG"
results=(); failed=0

run() { # run <名前> <コマンド...>
  local name="$1"; shift
  local start=$SECONDS line
  if "$@" > "$LOG/$name.log" 2>&1; then line="PASS  $name ($((SECONDS-start))s)"; else line="FAIL  $name ($((SECONDS-start))s) → $LOG/$name.log"; failed=1; fi
  results+=("$line")   # macOS標準のbash(3.2)は、配列の負の添字が使えない
  echo "$line"
}

xcrun simctl list devices | grep -q "$SIM_UDID" || { echo "シミュレータ $SIM_UDID が無い"; exit 2; }
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true

run analyze      "$FLUTTER" analyze --no-pub
run unit         "$FLUTTER" test --no-pub
run node         bash -c 'cd backend/ranking && npm test'
for t in flow play ranking; do
  run "drive_$t" "$FLUTTER" drive --no-pub --driver=test_driver/integration_test.dart --target="integration_test/${t}_test.dart" -d "$SIM_UDID"
done
run balance_sim  "$FLUTTER" test --no-pub tool/balance_sim_test.dart

if [ "${WITH_BUILD:-0}" = "1" ]; then
  run build_aab  "$FLUTTER" build appbundle --release --no-pub
  run build_ios  "$FLUTTER" build ios --release --no-codesign --no-pub
fi

echo; echo "===== ゲートの結果 ====="; printf '%s\n' "${results[@]}"
if [ $failed -eq 0 ]; then echo "全部通った"; else echo "落ちたテストがある(リリースしない)"; fi
exit $failed
