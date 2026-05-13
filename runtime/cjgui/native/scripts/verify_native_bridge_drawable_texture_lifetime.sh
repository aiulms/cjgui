#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 范围：本脚本只验证 production drawable texture lifetime 当前停在 planning。
# 停止线：不调用 nextDrawable，不 present，不新增 drawable token C ABI，不创建
# command buffer / encoder，不提交 GPU work，不执行 render，不返回 native pointer。
# Same-shape Boundary Brake: planning facts 不是 drawable-ready / color attachment truth。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
OWNER_PATH="${NATIVE_DIR}/../src/runtime_renderer_drawable_texture_lifetime_planning.cj"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-drawable-texture-lifetime.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/drawable_texture_lifetime_probe"
PROBE_SOURCE="${TMP_DIR}/drawable_texture_lifetime_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked"
  "cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked"
  "cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked"
  "cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked"
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
if [[ ! -f "$OWNER_PATH" ]]; then
  echo "missing runtime planning owner: $OWNER_PATH" >&2
  exit 1
fi
if ! grep -q "CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness" "$OWNER_PATH"; then
  echo "missing drawable texture lifetime planning endpoint" >&2
  exit 1
fi
if ! grep -q "cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft" "$OWNER_PATH"; then
  echo "missing drawable texture lifetime planning default draft" >&2
  exit 1
fi
if grep -Eq 'cjgui_native_bridge_drawable_texture_(acquire|release|classify|table|lifetime)' "$HEADER_PATH" "$SOURCE_PATH"; then
  echo "production drawable texture lifetime callable must remain deferred" >&2
  exit 1
fi
python3 - "$SOURCE_PATH" <<'PY'
import re
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
violations = []
for index, line in enumerate(text.splitlines(), 1):
    code = line.split("//", 1)[0]
    for name, pattern in [
        ("nextDrawable", r"nextDrawable"),
        ("presentDrawable", r"presentDrawable"),
        ("renderCommandEncoder", r"renderCommandEncoder"),
        ("commit", r"\bcommit\b"),
    ]:
        if re.search(pattern, code):
            violations.append((index, name, code.strip()))
if violations:
    for index, name, code in violations:
        print(f"{path}:{index}: forbidden {name}: {code}", file=sys.stderr)
    sys.exit(1)
PY
if grep -Eq '^[[:space:]]*(void[[:space:]]*\*|id|Class)[[:space:]]+cjgui_native_bridge_|uintptr_t[[:space:]]+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
static int expect_negative(const char *name, int32_t value) {
  if (value >= 0) {
    fprintf(stderr, "%s expected fail-closed negative value, got %d\n", name, value);
    return 1;
  }
  return 0;
}
int main(void) {
  int failures = 0;
  int32_t drawable_blocked =
      cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked();
  int32_t descriptor_texture_blocked =
      cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked();
  int32_t color_attachment_blocked =
      cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked();
  int32_t encoder_blocked =
      cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked();
  failures += expect_negative("drawable acquisition", drawable_blocked);
  failures += expect_negative("descriptor drawable texture", descriptor_texture_blocked);
  failures += expect_negative("color attachment", color_attachment_blocked);
  failures += expect_negative("encoder creation", encoder_blocked);
  printf("drawable_texture_lifetime_route=planning_only\n");
  printf("production_drawable_texture_lifetime=false\n");
  printf("production_drawable_acquire_callable=false\n");
  printf("next_drawable_called=false\n");
  printf("present_called=false\n");
  printf("command_buffer_created_by_stage=false\n");
  printf("encoder_created=false\n");
  printf("commit_called=false\n");
  printf("gpu_work_submitted=false\n");
  printf("render_executed=false\n");
  printf("drawable_acquisition_still_blocked=%d\n", drawable_blocked);
  printf("descriptor_drawable_texture_still_blocked=%d\n",
      descriptor_texture_blocked);
  printf("color_attachment_still_blocked=%d\n", color_attachment_blocked);
  printf("encoder_creation_still_blocked=%d\n", encoder_blocked);
  printf("drawable_texture_lifetime_probe=%s\n",
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
