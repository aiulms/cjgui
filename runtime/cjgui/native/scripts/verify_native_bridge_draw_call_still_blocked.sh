#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 draw call no-submit still-blocked C ABI。
# stop-line：只允许读取 encoder / pipeline binding / vertex binding / draw blocked
# 分类；不创建 encoder，不调用 setVertexBuffer / setRenderPipelineState，
# 不 draw，不 commit，不 present，不提交 GPU work，不执行 render。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-draw-call-still-blocked.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/draw_call_still_blocked_probe"
PROBE_SOURCE="${TMP_DIR}/draw_call_still_blocked_probe.m"
SANITIZED_SOURCE="${TMP_DIR}/cjgui_native_bridge.no_comments.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

required_symbols=(
  "cjgui_native_bridge_draw_call_encoder_required"
  "cjgui_native_bridge_draw_call_pipeline_binding_required"
  "cjgui_native_bridge_draw_call_vertex_binding_required"
  "cjgui_native_bridge_draw_call_still_blocked"
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

perl -0pe 's{/\*.*?\*/}{}gs; s{//.*$}{}gm' "$SOURCE_PATH" > "$SANITIZED_SOURCE"
if grep -Eq 'renderCommandEncoder|setVertexBuffer|setRenderPipelineState|drawPrimitives|drawIndexedPrimitives|commit]|presentDrawable|present]|dispatchThreadgroups|dispatchThreads' "$SANITIZED_SOURCE"; then
  echo "forbidden encoder / binding / draw / submit path found" >&2
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

static int expect_negative(const char *name, int32_t value) {
  if (value >= 0) {
    fprintf(stderr, "%s expected negative, got %d\n", name, value);
    return 1;
  }
  return 0;
}

int main(void) {
  int failures = 0;
  int32_t encoder_required =
      cjgui_native_bridge_draw_call_encoder_required();
  int32_t pipeline_binding_required =
      cjgui_native_bridge_draw_call_pipeline_binding_required();
  int32_t vertex_binding_required =
      cjgui_native_bridge_draw_call_vertex_binding_required();
  int32_t draw_still_blocked =
      cjgui_native_bridge_draw_call_still_blocked();
  failures += expect_negative("draw call encoder required", encoder_required);
  failures += expect_negative(
      "draw call pipeline binding required", pipeline_binding_required);
  failures += expect_negative(
      "draw call vertex binding required", vertex_binding_required);
  failures += expect_negative("draw call still blocked", draw_still_blocked);
  printf("draw_call_encoder_required=%d\n", encoder_required);
  printf("draw_call_pipeline_binding_required=%d\n",
         pipeline_binding_required);
  printf("draw_call_vertex_binding_required=%d\n", vertex_binding_required);
  printf("draw_call_still_blocked=%d\n", draw_still_blocked);
  printf("encoder_created=false\n");
  printf("set_vertex_buffer_called=false\n");
  printf("set_render_pipeline_state_called=false\n");
  printf("draw_called=false\n");
  printf("commit_called=false\n");
  printf("present_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("draw_call_still_blocked_probe=%s\n",
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
