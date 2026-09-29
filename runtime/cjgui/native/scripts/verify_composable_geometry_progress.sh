#!/usr/bin/env zsh
# One normal AppKit/Metal scene per window, then controlled platform backing
# notification, rejected redraw, recovery, resize and isolated second window.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUTPUT_DIR="${CJGUI_GEOMETRY_PROGRESS_TMPDIR:-/private/tmp/cjgui-geometry-progress}/$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$OUTPUT_DIR"
clang -DCJGUI_INTERNAL_TESTING -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules \
  -fstack-protector-strong -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_geometry_progress_test.m" \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/composable_geometry_progress_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:' "$OUTPUT_DIR/build.stderr.log" | tail -40 >&2 || true
    print -u2 "geometry progress: compile failed output=$OUTPUT_DIR"
    exit 2
  }
"$OUTPUT_DIR/composable_geometry_progress_test" 2>&1 | tee "$OUTPUT_DIR/result.log"
print "geometry progress: passed output=$OUTPUT_DIR"
