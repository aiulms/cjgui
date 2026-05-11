#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 token-backed MTLCommandBuffer create/destroy first slice。
# stop-line：允许 commandBuffer；允许下游 MTLRenderPassDescriptor C ABI 存在；
# 本 probe 不创建 descriptor，不得 commit / present，不得创建 encoder，
# 不提交 GPU work，不执行 render，不返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-command-buffer.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/command_buffer_probe"
PROBE_SOURCE="${TMP_DIR}/command_buffer_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_command_buffer_table_capacity"
  "cjgui_native_bridge_command_buffer_table_enabled"
  "cjgui_native_bridge_command_buffer_table_occupied_count"
  "cjgui_native_bridge_command_buffer_create"
  "cjgui_native_bridge_command_buffer_destroy"
  "cjgui_native_bridge_command_buffer_token_classify"
  "cjgui_native_bridge_command_buffer_double_destroy_classify"
  "cjgui_native_bridge_command_buffer_create_requires_main_thread"
  "cjgui_native_bridge_command_buffer_destroy_requires_main_thread"
  "cjgui_native_bridge_command_buffer_commit_still_blocked"
  "cjgui_native_bridge_command_buffer_encoder_creation_still_blocked"
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
if grep -Eq 'commit]|presentDrawable|present]|MTLRenderCommandEncoder|renderCommandEncoder|newRenderPipelineState|drawPrimitives|dispatchThreadgroups' "$SOURCE_PATH"; then
  echo "forbidden commit / present / encoder / GPU path found" >&2
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
  int32_t buffer_create;
  int32_t buffer_destroy;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  uint64_t buffer_token = 0;
  result->buffer_create = cjgui_native_bridge_command_buffer_create(0, &buffer_token);
  result->buffer_destroy = cjgui_native_bridge_command_buffer_destroy(buffer_token);
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
    printf("command_buffer_create_destroy_probe=skipped_no_device\n");
    return 0;
  }
  failures += expect_positive("buffer table capacity", (int32_t)cjgui_native_bridge_command_buffer_table_capacity());
  failures += expect_positive("buffer table enabled", (int32_t)cjgui_native_bridge_command_buffer_table_enabled());
  failures += expect_negative("commit still blocked", cjgui_native_bridge_command_buffer_commit_still_blocked());
  failures += expect_negative("encoder still blocked", cjgui_native_bridge_command_buffer_encoder_creation_still_blocked());
  int32_t device_count_before = cjgui_native_bridge_metal_device_table_occupied_count();
  int32_t queue_count_before = cjgui_native_bridge_command_queue_table_occupied_count();
  int32_t buffer_count_before = cjgui_native_bridge_command_buffer_table_occupied_count();
  uint64_t device_token = 0;
  uint64_t queue_token = 0;
  uint64_t buffer_token = 0;
  failures += expect_zero("metal device create", cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_zero("command queue create", cjgui_native_bridge_command_queue_create(device_token, &queue_token));
  failures += expect_zero("command buffer create", cjgui_native_bridge_command_buffer_create(queue_token, &buffer_token));
  failures += expect_positive("command buffer classify", cjgui_native_bridge_command_buffer_token_classify(buffer_token));
  failures += expect_positive("command buffer occupied increment", cjgui_native_bridge_command_buffer_table_occupied_count() - buffer_count_before);
  if (buffer_token == 0 || (buffer_token & 0xffff000000000000ULL) != 0) {
    fprintf(stderr, "buffer token must be opaque small table token, got %llu\n", (unsigned long long)buffer_token);
    failures++;
  }
  failures += expect_negative("queue destroy blocked by buffer", cjgui_native_bridge_command_queue_destroy(queue_token));
  failures += expect_zero("command buffer destroy", cjgui_native_bridge_command_buffer_destroy(buffer_token));
  failures += expect_negative("command buffer classify after destroy", cjgui_native_bridge_command_buffer_token_classify(buffer_token));
  failures += expect_negative("command buffer double destroy", cjgui_native_bridge_command_buffer_double_destroy_classify(buffer_token));
  failures += expect_zero("command queue destroy", cjgui_native_bridge_command_queue_destroy(queue_token));
  failures += expect_zero("metal device destroy", cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_negative("invalid buffer destroy", cjgui_native_bridge_command_buffer_destroy(0));
  failures += expect_zero("buffer occupied cleanup", cjgui_native_bridge_command_buffer_table_occupied_count() - buffer_count_before);
  failures += expect_zero("queue occupied cleanup", cjgui_native_bridge_command_queue_table_occupied_count() - queue_count_before);
  failures += expect_zero("device occupied cleanup", cjgui_native_bridge_metal_device_table_occupied_count() - device_count_before);
  ThreadResult background = {0, 0};
  pthread_t thread;
  if (pthread_create(&thread, NULL, run_background_checks, &background) == 0) {
    pthread_join(thread, NULL);
    failures += expect_negative("background buffer create denied", background.buffer_create);
    failures += expect_negative("background buffer destroy denied", background.buffer_destroy);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  printf("metal_default_device_available=%d\n", availability);
  printf("queue_token=%llu\n", (unsigned long long)queue_token);
  printf("buffer_token=%llu\n", (unsigned long long)buffer_token);
  printf("buffer_count_before=%d\n", buffer_count_before);
  printf("buffer_count_after=%u\n", cjgui_native_bridge_command_buffer_table_occupied_count());
  printf("queue_count_before=%d\n", queue_count_before);
  printf("queue_count_after=%u\n", cjgui_native_bridge_command_queue_table_occupied_count());
  printf("device_count_before=%d\n", device_count_before);
  printf("device_count_after=%u\n", cjgui_native_bridge_metal_device_table_occupied_count());
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("encoder_created=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("command_buffer_create_destroy_probe=%s\n", failures == 0 ? "passed" : "failed");
  return failures == 0 ? 0 : 1;
}
OBJC
clang -fobjc-arc -ObjC -I"$NATIVE_DIR" \
  "$SOURCE_PATH" "$PROBE_SOURCE" \
  -framework AppKit -framework QuartzCore -framework Metal -lobjc \
  -o "$BIN_PATH"
"$BIN_PATH" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
