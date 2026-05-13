#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 shader library no-draw create/destroy first slice。
# stop-line：只允许基于 token-backed MTLDevice 编译最小 shader library；
# 上游 shader 调用路径不创建 encoder，不 draw，不创建 vertex buffer，
# 不 commit，不 present，不提交 GPU work，不执行 render，不返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-shader-library.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/shader_library_probe"
PROBE_SOURCE="${TMP_DIR}/shader_library_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_shader_source_contract_available"
  "cjgui_native_bridge_shader_library_table_capacity"
  "cjgui_native_bridge_shader_library_table_enabled"
  "cjgui_native_bridge_shader_library_table_occupied_count"
  "cjgui_native_bridge_shader_library_create"
  "cjgui_native_bridge_shader_library_destroy"
  "cjgui_native_bridge_shader_library_token_classify"
  "cjgui_native_bridge_shader_library_double_destroy_classify"
  "cjgui_native_bridge_shader_library_create_requires_main_thread"
  "cjgui_native_bridge_shader_library_destroy_requires_main_thread"
  "cjgui_native_bridge_shader_pipeline_state_creation_still_blocked"
  "cjgui_native_bridge_shader_encoder_binding_still_blocked"
  "cjgui_native_bridge_shader_draw_still_blocked"
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
if grep -Eq 'renderCommandEncoder|setRenderPipelineState|drawPrimitives|drawIndexedPrimitives|newBuffer|commit]|presentDrawable|present]|dispatchThreadgroups' "$SOURCE_PATH"; then
  echo "forbidden encoder / draw / submit path found" >&2
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
  int32_t library_create;
  int32_t library_destroy;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  uint64_t library_token = 0;
  result->library_create =
      cjgui_native_bridge_shader_library_create(0, &library_token);
  result->library_destroy =
      cjgui_native_bridge_shader_library_destroy(library_token);
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
    printf("shader_library_create_destroy_probe=skipped_no_device\n");
    return 0;
  }
  failures += expect_positive(
      "shader source contract",
      cjgui_native_bridge_shader_source_contract_available());
  failures += expect_positive(
      "shader library table capacity",
      (int32_t)cjgui_native_bridge_shader_library_table_capacity());
  failures += expect_positive(
      "shader library table enabled",
      (int32_t)cjgui_native_bridge_shader_library_table_enabled());
  failures += expect_negative(
      "pipeline state still blocked",
      cjgui_native_bridge_shader_pipeline_state_creation_still_blocked());
  failures += expect_negative(
      "encoder binding still blocked",
      cjgui_native_bridge_shader_encoder_binding_still_blocked());
  failures += expect_negative(
      "draw still blocked",
      cjgui_native_bridge_shader_draw_still_blocked());
  failures += expect_negative(
      "null out token denied",
      cjgui_native_bridge_shader_library_create(0, 0));
  uint64_t invalid_library_token = 0;
  failures += expect_negative(
      "invalid device token denied",
      cjgui_native_bridge_shader_library_create(0, &invalid_library_token));
  int32_t device_count_before =
      cjgui_native_bridge_metal_device_table_occupied_count();
  int32_t library_count_before =
      cjgui_native_bridge_shader_library_table_occupied_count();
  uint64_t device_token = 0;
  uint64_t library_token = 0;
  failures += expect_zero(
      "metal device create",
      cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_zero(
      "shader library create",
      cjgui_native_bridge_shader_library_create(device_token, &library_token));
  failures += expect_positive(
      "shader library classify",
      cjgui_native_bridge_shader_library_token_classify(library_token));
  if (library_token == 0 ||
      (library_token & 0xffff000000000000ULL) != 0) {
    fprintf(stderr, "library token must be opaque small table token, got %llu\n",
            (unsigned long long)library_token);
    failures++;
  }
  failures += expect_positive(
      "shader library occupied increment",
      cjgui_native_bridge_shader_library_table_occupied_count() -
          library_count_before);
  failures += expect_zero(
      "shader library destroy",
      cjgui_native_bridge_shader_library_destroy(library_token));
  failures += expect_negative(
      "shader library classify after destroy",
      cjgui_native_bridge_shader_library_token_classify(library_token));
  failures += expect_negative(
      "shader library double destroy status",
      cjgui_native_bridge_shader_library_destroy(library_token));
  failures += expect_negative(
      "shader library double destroy classify",
      cjgui_native_bridge_shader_library_double_destroy_classify(
          library_token));
  failures += expect_negative(
      "invalid library destroy",
      cjgui_native_bridge_shader_library_destroy(0));
  failures += expect_zero(
      "metal device destroy",
      cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_zero(
      "library occupied cleanup",
      cjgui_native_bridge_shader_library_table_occupied_count() -
          library_count_before);
  failures += expect_zero(
      "device occupied cleanup",
      cjgui_native_bridge_metal_device_table_occupied_count() -
          device_count_before);
  ThreadResult background = {0, 0};
  pthread_t thread;
  if (pthread_create(&thread, NULL, run_background_checks, &background) == 0) {
    pthread_join(thread, NULL);
    failures += expect_negative(
        "background library create denied", background.library_create);
    failures += expect_negative(
        "background library destroy denied", background.library_destroy);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  printf("device_token=%llu\n", (unsigned long long)device_token);
  printf("library_token=%llu\n", (unsigned long long)library_token);
  printf("library_count_before=%d\n", library_count_before);
  printf("library_count_after=%u\n",
         cjgui_native_bridge_shader_library_table_occupied_count());
  printf("pipeline_state_created=false\n");
  printf("encoder_created=false\n");
  printf("draw_called=false\n");
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("shader_library_create_destroy_probe=%s\n",
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
