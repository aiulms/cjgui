#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 MTLRenderPipelineDescriptor no-draw configuration facts。
# stop-line：只允许 pixel format / sample count / nil shader facts；不得创建
# pipeline state、encoder，不 draw，不 commit，不 present；shader library/function
# 已由后续 no-draw 阶段单独验证，
# 不提交 GPU work，不执行 render。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-pipeline-descriptor-config.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/pipeline_descriptor_config_probe"
PROBE_SOURCE="${TMP_DIR}/pipeline_descriptor_config_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_pipeline_descriptor_configure_no_draw"
  "cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify"
  "cjgui_native_bridge_pipeline_descriptor_sample_count_classify"
  "cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked"
  "cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked"
  "cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked"
  "cjgui_native_bridge_pipeline_descriptor_blending_still_blocked"
  "cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked"
  "cjgui_native_bridge_pipeline_state_creation_still_blocked"
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
if grep -Eq 'newRenderPipelineState|MTLRenderPipelineState|renderCommandEncoder|setRenderPipelineState|drawPrimitives|drawIndexedPrimitives|newBuffer|commit]|presentDrawable|present]|dispatchThreadgroups' "$SOURCE_PATH"; then
  echo "forbidden pipeline state / encoder / draw / submit path found" >&2
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
  int32_t descriptor_configure;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  result->descriptor_configure =
      cjgui_native_bridge_pipeline_descriptor_configure_no_draw(1);
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
  int32_t descriptor_count_before =
      cjgui_native_bridge_pipeline_descriptor_table_occupied_count();
  uint64_t descriptor_token = 0;
  failures += expect_zero(
      "pipeline descriptor create",
      cjgui_native_bridge_pipeline_descriptor_create(&descriptor_token));
  failures += expect_negative(
      "pixel format before configure",
      cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
          descriptor_token));
  int32_t sample_count_before_configure =
      cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
          descriptor_token);
  if (sample_count_before_configure != 223 &&
      sample_count_before_configure >= 0) {
    fprintf(stderr, "sample count before configure unexpected value %d\n",
            sample_count_before_configure);
    failures++;
  }
  ThreadResult background = {0};
  pthread_t thread;
  if (pthread_create(&thread, NULL, run_background_checks, &background) == 0) {
    pthread_join(thread, NULL);
    failures += expect_negative(
        "background configure denied", background.descriptor_configure);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  failures += expect_zero(
      "pipeline descriptor configure",
      cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
          descriptor_token));
  failures += expect_positive(
      "pipeline descriptor valid classify",
      cjgui_native_bridge_pipeline_descriptor_token_classify(descriptor_token));
  if (cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
          descriptor_token) != 222) {
    fprintf(stderr, "color pixel format classification mismatch\n");
    failures++;
  }
  if (cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
          descriptor_token) != 223) {
    fprintf(stderr, "sample count classification mismatch\n");
    failures++;
  }
  failures += expect_negative(
      "pipeline state still blocked",
      cjgui_native_bridge_pipeline_state_creation_still_blocked());
  failures += expect_negative(
      "shader library still blocked",
      cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked());
  failures += expect_negative(
      "vertex function still blocked",
      cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked());
  failures += expect_negative(
      "fragment function still blocked",
      cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked());
  failures += expect_negative(
      "blending still blocked",
      cjgui_native_bridge_pipeline_descriptor_blending_still_blocked());
  failures += expect_negative(
      "encoder binding still blocked",
      cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked());
  failures += expect_zero(
      "pipeline descriptor destroy",
      cjgui_native_bridge_pipeline_descriptor_destroy(descriptor_token));
  failures += expect_negative(
      "pipeline descriptor double destroy",
      cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(
          descriptor_token));
  failures += expect_zero(
      "descriptor occupied cleanup",
      cjgui_native_bridge_pipeline_descriptor_table_occupied_count() -
          descriptor_count_before);
  printf("descriptor_token=%llu\n", (unsigned long long)descriptor_token);
  printf("sample_count_before_configure=%d\n", sample_count_before_configure);
  printf("descriptor_count_before=%d\n", descriptor_count_before);
  printf("descriptor_count_after=%u\n",
         cjgui_native_bridge_pipeline_descriptor_table_occupied_count());
  printf("color_pixel_format_configured=true\n");
  printf("sample_count_configured=true\n");
  printf("shader_library_created=false\n");
  printf("shader_function_created=false\n");
  printf("pipeline_state_created=false\n");
  printf("encoder_created=false\n");
  printf("draw_called=false\n");
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("pipeline_descriptor_configuration_probe=%s\n",
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
