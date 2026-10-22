#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_OWNER_IDLE_TMPDIR:-/private/tmp/cjgui-owner-idle-wait}"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
mkdir -p "$OUTPUT_DIR"
# One reusable, task-owned output. Callers preserve a RED binary before reuse.
trap 'rm -f "$OUTPUT_DIR/owner_idle_wait.part"' EXIT
clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/owner_idle_wait_native_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  "$RUNTIME_DIR/native/cjgui_async_multiline_measure.m" \
  "$RUNTIME_DIR/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -framework CoreText -lobjc \
  -o "$OUTPUT_DIR/owner_idle_wait.part" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log"
mv "$OUTPUT_DIR/owner_idle_wait.part" "$OUTPUT_DIR/owner_idle_wait"
"$OUTPUT_DIR/owner_idle_wait" 2>&1 | tee "$OUTPUT_DIR/result.log"
