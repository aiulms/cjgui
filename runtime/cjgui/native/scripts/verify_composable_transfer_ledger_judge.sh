#!/usr/bin/env zsh
# Headless acceptance for the transfer-retention judge boundary cases.
#
# Builds the real native renderer with -DCJGUI_INTERNAL_TESTING and runs the
# ledger judge directly, so the verdict vocabulary the transfer integration
# probe relies on is verified without a window, a desktop session or an
# autorelease-pool timing argument:
#   capacity edge recorded, capacity edge balanced, placeholder release not
#   masking a filled leak, double release, out-of-range invalidation, and a
#   single-id leak reported then cleared.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_TRANSFER_LEDGER_JUDGE_TMPDIR:-/private/tmp/cjgui-transfer-ledger-judge}/$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$OUTPUT_DIR"

if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "transfer ledger judge: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/renderer.o" 2>"$OUTPUT_DIR/renderer-build.log"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/tests/composable_transfer_ledger_judge_test.m" -o "$OUTPUT_DIR/judge-test.o"
clang -fobjc-arc -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$OUTPUT_DIR/judge-test.o" "$OUTPUT_DIR/renderer.o" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/transfer_ledger_judge_test"

LOG="$OUTPUT_DIR/judge-test.log"
set +e
"$OUTPUT_DIR/transfer_ledger_judge_test" > "$LOG" 2>&1
STATUS=$?
set -e
cat "$LOG"
if [[ "$STATUS" != 0 ]]; then
  print -r -- "transfer ledger judge: FAILED status=$STATUS"
  exit 1
fi
grep -q 'CJGUI_LEDGER_JUDGE failures=0 PASSED' "$LOG" || {
  print -r -- "transfer ledger judge: missing pass line"
  exit 1
}
for case in capacity_edge_recorded capacity_edge_filled_not_released capacity_edge_balanced \
            placeholder_release_does_not_mask_filled_leak double_release out_of_range_invalidates \
            single_id_leak single_id_leak_released; do
  grep -q "case=${case} " "$LOG" || {
    print -r -- "transfer ledger judge: case ${case} did not run"
    exit 1
  }
done
print -r -- "transfer ledger judge: PASSED raw_log=$LOG"
exit 0
