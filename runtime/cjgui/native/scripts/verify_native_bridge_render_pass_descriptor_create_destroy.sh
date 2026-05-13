#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 token-backed MTLRenderPassDescriptor create/destroy first slice。
# stop-line：允许创建 descriptor；不得创建 render command encoder，不 draw，
# 不 commit，不 present，不提交 GPU work，不执行 render，不返回 native pointer。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-render-pass-descriptor.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/render_pass_descriptor_probe"
PROBE_SOURCE="${TMP_DIR}/render_pass_descriptor_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_render_pass_descriptor_table_capacity"
  "cjgui_native_bridge_render_pass_descriptor_table_enabled"
  "cjgui_native_bridge_render_pass_descriptor_table_occupied_count"
  "cjgui_native_bridge_render_pass_descriptor_create"
  "cjgui_native_bridge_render_pass_descriptor_destroy"
  "cjgui_native_bridge_render_pass_descriptor_token_classify"
  "cjgui_native_bridge_render_pass_descriptor_double_destroy_classify"
  "cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread"
  "cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread"
  "cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked"
  "cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked"
  "cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked"
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
if grep -Eq 'renderCommandEncoder|MTLRenderCommandEncoder|drawPrimitives|commit]|presentDrawable|present]|dispatchThreadgroups' "$SOURCE_PATH"; then
  echo "forbidden encoder / draw / commit / present / GPU path found" >&2
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
  int32_t descriptor_create;
  int32_t descriptor_destroy;
} ThreadResult;
static void *run_background_checks(void *raw) {
  ThreadResult *result = (ThreadResult *)raw;
  uint64_t descriptor_token = 0;
  result->descriptor_create =
      cjgui_native_bridge_render_pass_descriptor_create(&descriptor_token);
  result->descriptor_destroy =
      cjgui_native_bridge_render_pass_descriptor_destroy(descriptor_token);
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
  failures += expect_positive(
      "descriptor table capacity",
      (int32_t)cjgui_native_bridge_render_pass_descriptor_table_capacity());
  failures += expect_positive(
      "descriptor table enabled",
      (int32_t)cjgui_native_bridge_render_pass_descriptor_table_enabled());
  failures += expect_negative(
      "color attachment still blocked",
      cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked());
  failures += expect_negative(
      "encoder still blocked",
      cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked());
  failures += expect_negative(
      "drawable texture still blocked",
      cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked());
  int32_t descriptor_count_before =
      cjgui_native_bridge_render_pass_descriptor_table_occupied_count();
  uint64_t descriptor_token = 0;
  failures += expect_zero(
      "render pass descriptor create",
      cjgui_native_bridge_render_pass_descriptor_create(&descriptor_token));
  failures += expect_positive(
      "render pass descriptor classify",
      cjgui_native_bridge_render_pass_descriptor_token_classify(descriptor_token));
  failures += expect_positive(
      "render pass descriptor occupied increment",
      cjgui_native_bridge_render_pass_descriptor_table_occupied_count() -
          descriptor_count_before);
  if (descriptor_token == 0 ||
      (descriptor_token & 0xffff000000000000ULL) != 0) {
    fprintf(stderr, "descriptor token must be opaque small table token, got %llu\n",
            (unsigned long long)descriptor_token);
    failures++;
  }
  failures += expect_zero(
      "render pass descriptor destroy",
      cjgui_native_bridge_render_pass_descriptor_destroy(descriptor_token));
  failures += expect_negative(
      "render pass descriptor classify after destroy",
      cjgui_native_bridge_render_pass_descriptor_token_classify(descriptor_token));
  failures += expect_negative(
      "render pass descriptor double destroy",
      cjgui_native_bridge_render_pass_descriptor_double_destroy_classify(
          descriptor_token));
  failures += expect_negative(
      "invalid descriptor destroy",
      cjgui_native_bridge_render_pass_descriptor_destroy(0));
  failures += expect_zero(
      "descriptor occupied cleanup",
      cjgui_native_bridge_render_pass_descriptor_table_occupied_count() -
          descriptor_count_before);
  ThreadResult background = {0, 0};
  pthread_t thread;
  if (pthread_create(&thread, NULL, run_background_checks, &background) == 0) {
    pthread_join(thread, NULL);
    failures += expect_negative(
        "background descriptor create denied", background.descriptor_create);
    failures += expect_negative(
        "background descriptor destroy denied", background.descriptor_destroy);
  } else {
    fprintf(stderr, "background thread creation failed\n");
    failures++;
  }
  printf("descriptor_token=%llu\n", (unsigned long long)descriptor_token);
  printf("descriptor_count_before=%d\n", descriptor_count_before);
  printf("descriptor_count_after=%u\n",
         cjgui_native_bridge_render_pass_descriptor_table_occupied_count());
  printf("color_attachment_configured=false\n");
  printf("encoder_created=false\n");
  printf("draw_called=false\n");
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("render_pass_descriptor_create_destroy_probe=%s\n",
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
