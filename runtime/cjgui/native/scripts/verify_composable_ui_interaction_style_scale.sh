#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_INTERACTION_STYLE_SCALE_TMPDIR:-/private/tmp/cjgui-interaction-style-scale}"
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"
(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -isysroot "$SDKROOT_PATH" \
  -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_interaction_style_scale.a" "$OUTPUT_DIR/native/cjgui_internal_renderer.o" \
  "$OUTPUT_DIR/native/cjgui_native_bridge.o"
cjc --sysroot "$SDKROOT_PATH" --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" "$RUNTIME_DIR/probe/composable_ui_interaction_style_scale_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_interaction_style_scale \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/interaction_style_scale_probe"
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/interaction_style_scale_probe" | tee "$OUTPUT_DIR/result"
python3 - "$OUTPUT_DIR/result" <<'PY'
import math
import re
import sys

samples = {}
pattern = re.compile(r"CJGUI_INTERACTION_STYLE_SCALE_SAMPLE controls=(\d+) sample=(\d+) pump_ns=(\d+) .* valid=true$")
for line in open(sys.argv[1], encoding="utf-8"):
    match = pattern.search(line.strip())
    if match:
        samples.setdefault(int(match.group(1)), []).append(int(match.group(3)))
for controls in (8, 128, 960):
    values = sorted(samples.get(controls, []))
    if len(values) != 30:
        raise SystemExit(f"interaction style scale missing valid samples controls={controls} count={len(values)}")
    p50 = (values[14] + values[15]) // 2
    p95 = values[math.ceil(len(values) * 0.95) - 1]
    print(f"CJGUI_INTERACTION_STYLE_SCALE_REPORT controls={controls} samples=30 pump_ns_p50={p50} pump_ns_p95={p95}")
PY
