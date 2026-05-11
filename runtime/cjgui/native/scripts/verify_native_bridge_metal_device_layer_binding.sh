#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本只验证 Metal device availability / token-backed device table / CAMetalLayer 绑定分类。
# stop-line：不得获取 drawable，不得创建 command queue / command buffer，不得提交 GPU work，不得返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-metal-device-binding.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/metal_device_binding_probe"
PROBE_SOURCE="${TMP_DIR}/metal_device_binding_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_metal_import_available"
  "cjgui_native_bridge_metal_default_device_available"
  "cjgui_native_bridge_metal_device_no_command_queue_admission"
  "cjgui_native_bridge_metal_device_table_capacity"
  "cjgui_native_bridge_metal_device_table_enabled"
  "cjgui_native_bridge_metal_device_table_occupied_count"
  "cjgui_native_bridge_metal_default_device_create"
  "cjgui_native_bridge_metal_device_destroy"
  "cjgui_native_bridge_metal_device_token_classify"
  "cjgui_native_bridge_metal_device_double_destroy_classify"
  "cjgui_native_bridge_metal_device_create_requires_main_thread"
  "cjgui_native_bridge_metal_device_destroy_requires_main_thread"
  "cjgui_native_bridge_metal_device_command_queue_still_blocked"
  "cjgui_native_bridge_cametallayer_bind_metal_device"
  "cjgui_native_bridge_cametallayer_unbind_metal_device"
  "cjgui_native_bridge_cametallayer_device_binding_classify"
  "cjgui_native_bridge_cametallayer_double_unbind_device_classify"
  "cjgui_native_bridge_cametallayer_device_binding_requires_main_thread"
  "cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked"
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
if grep -Eq 'nextDrawable|MTLRenderCommandEncoder|renderCommandEncoder|commit]|presentDrawable|present]' "$SOURCE_PATH"; then
  echo "forbidden Metal GPU submission or drawable path found" >&2
  exit 1
fi
if grep -Eq 'cjgui_native_bridge_[A-Za-z0-9_]+\([^;{)]*\)\s*\*|void\s*\*\s+cjgui_native_bridge_|id\s+cjgui_native_bridge_|Class\s+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge public C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
typedef struct ThreadResult {
  int32_t create_device;
  int32_t destroy_device;
  int32_t bind_device;
  int32_t unbind_device;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  uint64_t device_token = 0;
  result->create_device = cjgui_native_bridge_metal_default_device_create(&device_token);
  result->destroy_device = cjgui_native_bridge_metal_device_destroy(device_token);
  result->bind_device = cjgui_native_bridge_cametallayer_bind_metal_device(0, 0);
  result->unbind_device = cjgui_native_bridge_cametallayer_unbind_metal_device(0, 0);
  return NULL;
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
static int expect_zero(const char *name, int32_t value) {
  if (value != 0) {
    fprintf(stderr, "%s expected zero, got %d\n", name, value);
    return 1;
  }
  return 0;
}
int main(void) {
  int failures = 0;
  failures += expect_positive("metal import", cjgui_native_bridge_metal_import_available());
  int32_t availability = cjgui_native_bridge_metal_default_device_available();
  if (availability <= 0) {
    printf("metal_default_device_available=%d\n", availability);
    printf("metal_device_binding_probe=skipped_no_device\n");
    return 0;
  }
  failures += expect_negative("command queue admission", cjgui_native_bridge_metal_device_no_command_queue_admission());
  failures += expect_negative("command queue still blocked", cjgui_native_bridge_metal_device_command_queue_still_blocked());
  failures += expect_negative("drawable still blocked", cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked());
  failures += expect_positive("device table capacity", (int32_t)cjgui_native_bridge_metal_device_table_capacity());
  failures += expect_positive("device table enabled", (int32_t)cjgui_native_bridge_metal_device_table_enabled());
  int32_t device_count_before = cjgui_native_bridge_metal_device_table_occupied_count();
  int32_t layer_count_before = cjgui_native_bridge_cametallayer_table_occupied_count();
  int32_t view_count_before = cjgui_native_bridge_nsview_table_occupied_count();
  uint64_t view_token = 0;
  uint64_t layer_token = 0;
  uint64_t device_token = 0;
  failures += expect_zero("nsview create", cjgui_native_bridge_nsview_create(&view_token));
  failures += expect_zero("cametallayer create", cjgui_native_bridge_cametallayer_create(&layer_token));
  failures += expect_zero("cametallayer attach", cjgui_native_bridge_cametallayer_attach_to_nsview(layer_token, view_token));
  failures += expect_zero("metal device create", cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_positive("metal device classify", cjgui_native_bridge_metal_device_token_classify(device_token));
  if (device_token == 0 || (device_token & 0xffff000000000000ULL) != 0) {
    fprintf(stderr, "device token must be opaque small table token, got %llu\n", (unsigned long long)device_token);
    failures++;
  }
  failures += expect_zero("layer bind device", cjgui_native_bridge_cametallayer_bind_metal_device(layer_token, device_token));
  failures += expect_positive("layer device classify", cjgui_native_bridge_cametallayer_device_binding_classify(layer_token, device_token));
  failures += expect_negative("double bind denied", cjgui_native_bridge_cametallayer_bind_metal_device(layer_token, device_token));
  failures += expect_zero("layer unbind device", cjgui_native_bridge_cametallayer_unbind_metal_device(layer_token, device_token));
  failures += expect_negative("layer device classify after unbind", cjgui_native_bridge_cametallayer_device_binding_classify(layer_token, device_token));
  failures += expect_negative("double unbind denied", cjgui_native_bridge_cametallayer_double_unbind_device_classify(layer_token, device_token));
  failures += expect_zero("metal device destroy", cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_negative("metal device classify after destroy", cjgui_native_bridge_metal_device_token_classify(device_token));
  failures += expect_negative("metal device double destroy", cjgui_native_bridge_metal_device_double_destroy_classify(device_token));
  failures += expect_zero("cametallayer detach", cjgui_native_bridge_cametallayer_detach_from_nsview(layer_token, view_token));
  failures += expect_zero("cametallayer destroy", cjgui_native_bridge_cametallayer_destroy(layer_token));
  failures += expect_zero("nsview destroy", cjgui_native_bridge_nsview_destroy(view_token));
  failures += expect_zero("device occupied cleanup", cjgui_native_bridge_metal_device_table_occupied_count() - device_count_before);
  failures += expect_zero("layer occupied cleanup", cjgui_native_bridge_cametallayer_table_occupied_count() - layer_count_before);
  failures += expect_zero("view occupied cleanup", cjgui_native_bridge_nsview_table_occupied_count() - view_count_before);
  ThreadResult background = {0, 0, 0, 0};
  pthread_t thread;
  if (pthread_create(&thread, NULL, run_background_checks, &background) == 0) {
    pthread_join(thread, NULL);
    failures += expect_negative("background device create denied", background.create_device);
    failures += expect_negative("background device destroy denied", background.destroy_device);
    failures += expect_negative("background bind denied", background.bind_device);
    failures += expect_negative("background unbind denied", background.unbind_device);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  printf("metal_default_device_available=%d\n", availability);
  printf("device_count_before=%d\n", device_count_before);
  printf("device_count_after=%d\n", cjgui_native_bridge_metal_device_table_occupied_count());
  printf("metal_device_binding_probe=%s\n", failures == 0 ? "passed" : "failed");
  return failures == 0 ? 0 : 1;
}
OBJC
clang -fobjc-arc -ObjC -I"$NATIVE_DIR" \
  "$SOURCE_PATH" "$PROBE_SOURCE" \
  -framework AppKit -framework QuartzCore -framework Metal -lobjc \
  -o "$BIN_PATH"
"$BIN_PATH" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
