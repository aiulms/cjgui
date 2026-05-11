#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 范围：本脚本只验证 drawable acquisition first implementation 的 recovery / no-acquire facts。
# 停止线：不得调用 nextDrawable，不得 present，不得创建 command queue / buffer /
# encoder，不得提交 GPU work，不得返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-drawable-recovery.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/drawable_recovery_probe"
PROBE_SOURCE="${TMP_DIR}/drawable_recovery_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_nsview_create"
  "cjgui_native_bridge_nsview_destroy"
  "cjgui_native_bridge_nsview_table_occupied_count"
  "cjgui_native_bridge_cametallayer_create"
  "cjgui_native_bridge_cametallayer_destroy"
  "cjgui_native_bridge_cametallayer_table_occupied_count"
  "cjgui_native_bridge_cametallayer_attach_to_nsview"
  "cjgui_native_bridge_cametallayer_detach_from_nsview"
  "cjgui_native_bridge_metal_default_device_create"
  "cjgui_native_bridge_metal_device_destroy"
  "cjgui_native_bridge_metal_device_table_occupied_count"
  "cjgui_native_bridge_cametallayer_bind_metal_device"
  "cjgui_native_bridge_cametallayer_unbind_metal_device"
  "cjgui_native_bridge_cametallayer_device_binding_classify"
  "cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked"
  "cjgui_native_bridge_metal_device_command_queue_still_blocked"
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
if grep -Eq 'NSWindow[[:space:]]*\\*[^;=]*=[[:space:]]*\\[NSWindow|NSApplication[[:space:]]+sharedApplication|makeKeyAndOrderFront|orderFront' "$SOURCE_PATH"; then
  echo "forbidden visible NSWindow / NSApplication creation path found" >&2
  exit 1
fi
if grep -Eq 'cjgui_native_bridge_[A-Za-z0-9_]+\\([^;{)]*\\)\\s*\\*|void\\s*\\*\\s+cjgui_native_bridge_|id\\s+cjgui_native_bridge_|Class\\s+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
static int expect_zero(const char *name, int32_t value) {
  if (value != 0) {
    fprintf(stderr, "%s expected zero, got %d\n", name, value);
    return 1;
  }
  return 0;
}
static int expect_positive(const char *name, int32_t value) {
  if (value <= 0) {
    fprintf(stderr, "%s expected positive, got %d\n", name, value);
    return 1;
  }
  return 0;
}
static int expect_negative(const char *name, int32_t value) {
  if (value >= 0) {
    fprintf(stderr, "%s expected negative, got %d\n", name, value);
    return 1;
  }
  return 0;
}
int main(void) {
  int failures = 0;
  uint32_t view_count_before = cjgui_native_bridge_nsview_table_occupied_count();
  uint32_t layer_count_before =
      cjgui_native_bridge_cametallayer_table_occupied_count();
  uint32_t device_count_before =
      cjgui_native_bridge_metal_device_table_occupied_count();
  uint64_t view_token = 0;
  uint64_t layer_token = 0;
  uint64_t device_token = 0;
  failures += expect_zero("nsview create", cjgui_native_bridge_nsview_create(&view_token));
  failures += expect_zero("cametallayer create",
                          cjgui_native_bridge_cametallayer_create(&layer_token));
  failures += expect_zero("cametallayer attach",
                          cjgui_native_bridge_cametallayer_attach_to_nsview(
                              layer_token, view_token));
  failures += expect_zero("metal device create",
                          cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_zero("cametallayer bind metal device",
                          cjgui_native_bridge_cametallayer_bind_metal_device(
                              layer_token, device_token));
  failures += expect_positive(
      "cametallayer device binding classify",
      cjgui_native_bridge_cametallayer_device_binding_classify(
          layer_token, device_token));
  int32_t drawable_blocked =
      cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked();
  int32_t command_queue_blocked =
      cjgui_native_bridge_metal_device_command_queue_still_blocked();
  failures += expect_negative("drawable acquisition recovery", drawable_blocked);
  failures += expect_negative("command queue still blocked", command_queue_blocked);
  failures += expect_zero("cametallayer unbind metal device",
                          cjgui_native_bridge_cametallayer_unbind_metal_device(
                              layer_token, device_token));
  failures += expect_zero("metal device destroy",
                          cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_zero("cametallayer detach",
                          cjgui_native_bridge_cametallayer_detach_from_nsview(
                              layer_token, view_token));
  failures += expect_zero("cametallayer destroy",
                          cjgui_native_bridge_cametallayer_destroy(layer_token));
  failures += expect_zero("nsview destroy",
                          cjgui_native_bridge_nsview_destroy(view_token));
  uint32_t view_count_after = cjgui_native_bridge_nsview_table_occupied_count();
  uint32_t layer_count_after =
      cjgui_native_bridge_cametallayer_table_occupied_count();
  uint32_t device_count_after =
      cjgui_native_bridge_metal_device_table_occupied_count();
  if (view_count_after != view_count_before ||
      layer_count_after != layer_count_before ||
      device_count_after != device_count_before) {
    fprintf(stderr, "cleanup counts did not return to baseline\n");
    failures++;
  }
  printf("token_backed_layer_device_bound=true\n");
  printf("drawable_acquisition_recovery=%d\n", drawable_blocked);
  printf("command_queue_still_blocked=%d\n", command_queue_blocked);
  printf("visible_window_evidence=false\n");
  printf("display_backed_layer_evidence=false\n");
  printf("next_drawable_called=false\n");
  printf("present_called=false\n");
  printf("command_buffer_created=false\n");
  printf("gpu_work_submitted=false\n");
  printf("view_count_before=%u\n", view_count_before);
  printf("view_count_after=%u\n", view_count_after);
  printf("layer_count_before=%u\n", layer_count_before);
  printf("layer_count_after=%u\n", layer_count_after);
  printf("device_count_before=%u\n", device_count_before);
  printf("device_count_after=%u\n", device_count_after);
  printf("drawable_acquisition_recovery_probe=%s\n",
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
