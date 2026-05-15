#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 shader function no-draw lookup/classify/destroy first slice。
# stop-line：只允许从 token-backed MTLLibrary lookup vertex / fragment function；
# 上游 shader function 调用路径不创建 encoder，不 draw，不 commit，不 present，
# 不提交 GPU work，不执行 render，不返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-shader-function.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/shader_function_probe"
PROBE_SOURCE="${TMP_DIR}/shader_function_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_shader_function_table_capacity"
  "cjgui_native_bridge_shader_function_table_enabled"
  "cjgui_native_bridge_shader_function_table_occupied_count"
  "cjgui_native_bridge_shader_function_lookup_vertex"
  "cjgui_native_bridge_shader_function_lookup_fragment"
  "cjgui_native_bridge_shader_function_destroy"
  "cjgui_native_bridge_shader_function_token_classify"
  "cjgui_native_bridge_shader_function_double_destroy_classify"
  "cjgui_native_bridge_shader_function_lookup_requires_main_thread"
  "cjgui_native_bridge_shader_function_destroy_requires_main_thread"
  "cjgui_native_bridge_shader_function_missing_classify"
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
if grep -Ev '^[[:space:]]*(/\*|\*|//)' "$SOURCE_PATH" | grep -Eq 'renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|commit]|presentDrawable|present]|dispatchThreadgroups'; then
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
  int32_t lookup_vertex;
  int32_t destroy_function;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  uint64_t function_token = 0;
  result->lookup_vertex =
      cjgui_native_bridge_shader_function_lookup_vertex(0, &function_token);
  result->destroy_function =
      cjgui_native_bridge_shader_function_destroy(function_token);
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
    printf("shader_function_lookup_probe=skipped_no_device\n");
    return 0;
  }
  failures += expect_positive(
      "shader function table capacity",
      (int32_t)cjgui_native_bridge_shader_function_table_capacity());
  failures += expect_positive(
      "shader function table enabled",
      (int32_t)cjgui_native_bridge_shader_function_table_enabled());
  failures += expect_negative(
      "null vertex out token denied",
      cjgui_native_bridge_shader_function_lookup_vertex(0, 0));
  failures += expect_negative(
      "invalid library token denied",
      cjgui_native_bridge_shader_function_lookup_vertex(0, &(uint64_t){0}));
  failures += expect_negative(
      "missing classify remains fail closed",
      cjgui_native_bridge_shader_function_missing_classify());
  int32_t device_count_before =
      cjgui_native_bridge_metal_device_table_occupied_count();
  int32_t library_count_before =
      cjgui_native_bridge_shader_library_table_occupied_count();
  int32_t function_count_before =
      cjgui_native_bridge_shader_function_table_occupied_count();
  uint64_t device_token = 0;
  uint64_t library_token = 0;
  uint64_t vertex_token = 0;
  uint64_t fragment_token = 0;
  failures += expect_zero(
      "metal device create",
      cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_zero(
      "shader library create",
      cjgui_native_bridge_shader_library_create(device_token, &library_token));
  failures += expect_zero(
      "vertex function lookup",
      cjgui_native_bridge_shader_function_lookup_vertex(
          library_token, &vertex_token));
  failures += expect_zero(
      "fragment function lookup",
      cjgui_native_bridge_shader_function_lookup_fragment(
          library_token, &fragment_token));
  failures += expect_positive(
      "vertex function classify",
      cjgui_native_bridge_shader_function_token_classify(vertex_token));
  failures += expect_positive(
      "fragment function classify",
      cjgui_native_bridge_shader_function_token_classify(fragment_token));
  if (vertex_token == 0 || fragment_token == 0 ||
      vertex_token == fragment_token ||
      (vertex_token & 0xffff000000000000ULL) != 0 ||
      (fragment_token & 0xffff000000000000ULL) != 0) {
    fprintf(stderr, "function tokens must be distinct opaque small table tokens\n");
    failures++;
  }
  failures += expect_negative(
      "library destroy blocked while functions live",
      cjgui_native_bridge_shader_library_destroy(library_token));
  failures += expect_positive(
      "function occupied increment",
      cjgui_native_bridge_shader_function_table_occupied_count() -
          function_count_before);
  failures += expect_zero(
      "vertex function destroy",
      cjgui_native_bridge_shader_function_destroy(vertex_token));
  failures += expect_zero(
      "fragment function destroy",
      cjgui_native_bridge_shader_function_destroy(fragment_token));
  failures += expect_negative(
      "vertex classify after destroy",
      cjgui_native_bridge_shader_function_token_classify(vertex_token));
  failures += expect_negative(
      "vertex double destroy status",
      cjgui_native_bridge_shader_function_destroy(vertex_token));
  failures += expect_negative(
      "vertex double destroy classify",
      cjgui_native_bridge_shader_function_double_destroy_classify(vertex_token));
  failures += expect_negative(
      "invalid function destroy",
      cjgui_native_bridge_shader_function_destroy(0));
  failures += expect_zero(
      "shader library destroy after functions",
      cjgui_native_bridge_shader_library_destroy(library_token));
  failures += expect_zero(
      "metal device destroy",
      cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_zero(
      "function occupied cleanup",
      cjgui_native_bridge_shader_function_table_occupied_count() -
          function_count_before);
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
        "background function lookup denied", background.lookup_vertex);
    failures += expect_negative(
        "background function destroy denied", background.destroy_function);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  printf("vertex_token=%llu\n", (unsigned long long)vertex_token);
  printf("fragment_token=%llu\n", (unsigned long long)fragment_token);
  printf("function_count_before=%d\n", function_count_before);
  printf("function_count_after=%u\n",
         cjgui_native_bridge_shader_function_table_occupied_count());
  printf("pipeline_state_created=false\n");
  printf("encoder_created=false\n");
  printf("draw_called=false\n");
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("shader_function_lookup_probe=%s\n",
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
