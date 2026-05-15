#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 MTLBuffer 固定三角形数据上传 facts。上传只发生在 native
# bridge 内部，contents 指针不保存、不返回。
# stop-line：不绑定 encoder，不调用 setVertexBuffer，不 draw，不 commit，
# 不 present，不提交 GPU work，不执行 render。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-vertex-buffer-upload.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/vertex_buffer_upload_probe"
PROBE_SOURCE="${TMP_DIR}/vertex_buffer_upload_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_vertex_buffer_upload_static_triangle"
  "cjgui_native_bridge_vertex_buffer_data_classify"
  "cjgui_native_bridge_vertex_buffer_upload_requires_main_thread"
  "cjgui_native_bridge_vertex_buffer_layout_position_color"
  "cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked"
  "cjgui_native_bridge_vertex_buffer_draw_still_blocked"
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
if grep -Ev '^[[:space:]]*(/\*|\*|//)' "$SOURCE_PATH" | grep -Eq 'renderCommandEncoder|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|newBufferWithBytes|commit]|presentDrawable|present]|dispatchThreadgroups|dispatchThreads'; then
  echo "forbidden encoder / vertex binding / draw / submit path found" >&2
  exit 1
fi
if grep -Eq 'cjgui_native_bridge_[A-Za-z0-9_]+\([^;{)]*\)\s*\*|void\s*\*\s+cjgui_native_bridge_|id\s+cjgui_native_bridge_|Class\s+cjgui_native_bridge_|uintptr_t\s+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge public C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
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
    printf("vertex_buffer_data_upload_probe=skipped_no_device\n");
    return 0;
  }
  int32_t device_count_before =
      cjgui_native_bridge_metal_device_table_occupied_count();
  int32_t buffer_count_before =
      cjgui_native_bridge_vertex_buffer_table_occupied_count();
  uint64_t device_token = 0;
  uint64_t buffer_token = 0;
  failures += expect_negative(
      "invalid upload denied",
      cjgui_native_bridge_vertex_buffer_upload_static_triangle(0));
  failures += expect_zero(
      "metal device create",
      cjgui_native_bridge_metal_default_device_create(&device_token));
  failures += expect_zero(
      "vertex buffer create",
      cjgui_native_bridge_vertex_buffer_create(device_token, &buffer_token));
  failures += expect_negative(
      "data not uploaded before upload",
      cjgui_native_bridge_vertex_buffer_data_classify(buffer_token));
  failures += expect_zero(
      "static triangle upload",
      cjgui_native_bridge_vertex_buffer_upload_static_triangle(buffer_token));
  failures += expect_positive(
      "data classify after upload",
      cjgui_native_bridge_vertex_buffer_data_classify(buffer_token));
  failures += expect_positive(
      "position color layout",
      cjgui_native_bridge_vertex_buffer_layout_position_color());
  failures += expect_negative(
      "encoder binding blocked",
      cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked());
  failures += expect_negative(
      "draw blocked",
      cjgui_native_bridge_vertex_buffer_draw_still_blocked());
  failures += expect_zero(
      "vertex buffer destroy",
      cjgui_native_bridge_vertex_buffer_destroy(buffer_token));
  failures += expect_negative(
      "data classify after destroy",
      cjgui_native_bridge_vertex_buffer_data_classify(buffer_token));
  failures += expect_zero(
      "metal device destroy",
      cjgui_native_bridge_metal_device_destroy(device_token));
  failures += expect_zero(
      "vertex buffer occupied cleanup",
      cjgui_native_bridge_vertex_buffer_table_occupied_count() -
          buffer_count_before);
  failures += expect_zero(
      "device occupied cleanup",
      cjgui_native_bridge_metal_device_table_occupied_count() -
          device_count_before);
  printf("device_token=%llu\n", (unsigned long long)device_token);
  printf("vertex_buffer_token=%llu\n", (unsigned long long)buffer_token);
  printf("vertex_data_layout=position_color\n");
  printf("set_vertex_buffer_called=false\n");
  printf("draw_called=false\n");
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("vertex_buffer_data_upload_probe=%s\n",
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
