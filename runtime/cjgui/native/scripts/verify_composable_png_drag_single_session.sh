#!/usr/bin/env zsh
# Standalone native responder probe. It does not launch a window or send
# system-wide pointer events; the test double intercepts AppKit drag creation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_DIR="${CJGUI_PNG_DRAG_TMPDIR:-/private/tmp/cjgui-png-drag-single-session}/$(date +%Y%m%d%H%M%S)-$$"
if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "png drag single-session test: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_png_drag_single_session_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/composable_png_drag_single_session_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*composable_png_drag_single_session_test.m' "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "png drag single-session test: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

"$OUTPUT_DIR/composable_png_drag_single_session_test" 2>&1 | tee "$OUTPUT_DIR/result.log"
print "png drag single-session test: passed output=$OUTPUT_DIR"
