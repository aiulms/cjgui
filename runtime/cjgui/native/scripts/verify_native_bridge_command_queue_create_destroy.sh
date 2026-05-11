#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 token-backed MTLCommandQueue create/destroy first slice。
# stop-line：允许 newCommandQueue；不得创建 encoder，不得 commit /
# present，不得提交 GPU work，不执行 render，不返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-command-queue.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/command_queue_probe"
PROBE_SOURCE="${TMP_DIR}/command_queue_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_command_queue_table_capacity"
  "cjgui_native_bridge_command_queue_table_enabled"
  "cjgui_native_bridge_command_queue_table_occupied_count"
  "cjgui_native_bridge_command_queue_create"
  "cjgui_native_bridge_command_queue_destroy"
  "cjgui_native_bridge_command_queue_token_classify"
  "cjgui_native_bridge_command_queue_double_destroy_classify"
  "cjgui_native_bridge_command_queue_create_requires_main_thread"
  "cjgui_native_bridge_command_queue_destroy_requires_main_thread"
  "cjgui_native_bridge_command_buffer_creation_still_blocked"
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
if grep -Eq 'MTLRenderCommandEncoder|renderCommandEncoder|commit]|presentDrawable|present]' "$SOURCE_PATH"; then
  echo "forbidden command buffer commit / presentation / submission path found" >&2
  exit 1
fi
if grep -Eq 'cjgui_native_bridge_[A-Za-z0-9_]+\([^;{)]*\)\s*\*|void\s*\*\s+cjgui_native_bridge_|id\s+cjgui_native_bridge_|Class\s+cjgui_native_bridge_|uintptr_t\s+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge public C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
typedef struct ThreadResult {
  int32_t queue_create;
  int32_t queue_destroy;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  uint64_t queue_token = 0;
  result->queue_create = cjgui_native_bridge_command_queue_create(0, &queue_token);
  result->queue_destroy = cjgui_native_bridge_command_queue_destroy(queue_token);
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
  int32_t availability = cjgui_native_bridge_metal_default_device_available();
  if (availability <= 0) {
    printf("metal_default_device_available=%d\n", availability);
    printf("command_queue_create_destroy_probe=skipped_no_device\n");
    return 0;
  }
  failures += expect_positive("queue table capacity", (int32_t)cjgui_native_bridge_command_queue_table_capacity());
  failures += expect_positive("queue table enabled", (int32_t)cjgui_native_bridge_command_queue_table_enabled());
  failures += expect_negative("command buffer still blocked", cjgui_native_bridge_command_buffer_creation_still_blocked());
  int32_t device_count_before = cjgui_native_bridge_metal_device_table_occupied_count();
  int32_t queue_count_before = cjgui_native_bridge_command_queue_table_occupied_count();
  uint64_t device_token = 0;
  uint64_t queue_token = 0;
  failures += expect_zero("metal device create", cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_zero("command queue create", cjgui_native_bridge_command_queue_create(device_token, &queue_token));
  failures += expect_positive("command queue classify", cjgui_native_bridge_command_queue_token_classify(queue_token));
  failures += expect_positive("command queue occupied increment", cjgui_native_bridge_command_queue_table_occupied_count() - queue_count_before);
  if (queue_token == 0 || (queue_token & 0xffff000000000000ULL) != 0) {
    fprintf(stderr, "queue token must be opaque small table token, got %llu\n", (unsigned long long)queue_token);
    failures++;
  }
  failures += expect_negative("device destroy blocked by queue", cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_zero("command queue destroy", cjgui_native_bridge_command_queue_destroy(queue_token));
  failures += expect_negative("command queue classify after destroy", cjgui_native_bridge_command_queue_token_classify(queue_token));
  failures += expect_negative("command queue double destroy", cjgui_native_bridge_command_queue_double_destroy_classify(queue_token));
  failures += expect_zero("metal device destroy", cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_negative("invalid queue destroy", cjgui_native_bridge_command_queue_destroy(0));
  failures += expect_zero("queue occupied cleanup", cjgui_native_bridge_command_queue_table_occupied_count() - queue_count_before);
  failures += expect_zero("device occupied cleanup", cjgui_native_bridge_metal_device_table_occupied_count() - device_count_before);
  ThreadResult background = {0, 0};
  pthread_t thread;
  if (pthread_create(&thread, NULL, run_background_checks, &background) == 0) {
    pthread_join(thread, NULL);
    failures += expect_negative("background queue create denied", background.queue_create);
    failures += expect_negative("background queue destroy denied", background.queue_destroy);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  printf("metal_default_device_available=%d\n", availability);
  printf("queue_token=%llu\n", (unsigned long long)queue_token);
  printf("queue_count_before=%d\n", queue_count_before);
  printf("queue_count_after=%u\n", cjgui_native_bridge_command_queue_table_occupied_count());
  printf("device_count_before=%d\n", device_count_before);
  printf("device_count_after=%u\n", cjgui_native_bridge_metal_device_table_occupied_count());
  printf("command_buffer_created=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("command_queue_create_destroy_probe=%s\n", failures == 0 ? "passed" : "failed");
  return failures == 0 ? 0 : 1;
}
OBJC
clang -fobjc-arc -ObjC -I"$NATIVE_DIR" \
  "$SOURCE_PATH" "$PROBE_SOURCE" \
  -framework AppKit -framework QuartzCore -framework Metal -lobjc \
  -o "$BIN_PATH"
"$BIN_PATH" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
