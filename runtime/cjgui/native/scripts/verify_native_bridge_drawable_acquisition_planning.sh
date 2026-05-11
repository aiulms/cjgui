#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本只验证 drawable acquisition runway 的 planning / no-acquire facts。
# stop-line：不得调用 nextDrawable，不得 present，不得创建 command queue / buffer /
# encoder，不得提交 GPU work，不得返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-drawable-planning.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/drawable_planning_probe"
PROBE_SOURCE="${TMP_DIR}/drawable_planning_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked"
  "cjgui_native_bridge_metal_device_command_queue_still_blocked"
  "cjgui_native_bridge_cametallayer_device_binding_requires_main_thread"
)
for symbol in "${required_symbols[@]}"; do
  if ! grep -q "$symbol" "$HEADER_PATH"; then
    echo "missing header symbol: $symbol" >&2
    exit 1
  fi
  if ! grep -q "$symbol" "$SOURCE_PATH"; then
    echo "missing source symbol: $symbol" >&2
    exit 1
  fi
done
if grep -Eq 'nextDrawable|presentDrawable|present]|MTLRenderCommandEncoder|renderCommandEncoder|commit]' "$SOURCE_PATH"; then
  echo "forbidden drawable presentation / command submission path found" >&2
  exit 1
fi
if grep -Eq 'cjgui_native_bridge_[A-Za-z0-9_]+\([^;{)]*\)\s*\*|void\s*\*\s+cjgui_native_bridge_|id\s+cjgui_native_bridge_|Class\s+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
static int expect_negative(const char *name, int32_t value) {
  if (value >= 0) {
    fprintf(stderr, "%s expected negative fail-closed value, got %d\n", name, value);
    return 1;
  }
  return 0;
}
int main(void) {
  int failures = 0;
  int32_t drawable_blocked =
      cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked();
  int32_t command_queue_blocked =
      cjgui_native_bridge_metal_device_command_queue_still_blocked();
  int32_t main_thread_required =
      cjgui_native_bridge_cametallayer_device_binding_requires_main_thread();
  failures += expect_negative("drawable acquisition blocked", drawable_blocked);
  failures += expect_negative("command queue blocked", command_queue_blocked);
  failures += expect_negative("binding main thread gate", main_thread_required);
  printf("drawable_acquisition_still_blocked=%d\n", drawable_blocked);
  printf("command_queue_still_blocked=%d\n", command_queue_blocked);
  printf("binding_main_thread_required=%d\n", main_thread_required);
  printf("next_drawable_called=false\n");
  printf("present_called=false\n");
  printf("command_buffer_created=false\n");
  printf("gpu_work_submitted=false\n");
  printf("drawable_acquisition_planning_probe=%s\n",
      failures == 0 ? "passed" : "failed");
  return failures == 0 ? 0 : 1;
}
OBJC
clang -fobjc-arc -ObjC -I"$NATIVE_DIR" \
  "$SOURCE_PATH" "$PROBE_SOURCE" \
  -framework AppKit -framework QuartzCore -framework Metal -lobjc \
  -o "$BIN_PATH"
"$BIN_PATH" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
