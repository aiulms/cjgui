#!/usr/bin/env zsh
# Controlled native cache probe. It holds the AppKit main queue while an owner
# reads an already-published scalar snapshot; no renderer window is created.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_ROOT="${CJGUI_BACKGROUND_CACHE_TMPDIR:-/private/tmp/cjgui-window-background-snapshot-cache}"
OUTPUT_DIR="$OUTPUT_ROOT/$(date +%Y%m%d%H%M%S)-$$"

if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "window background snapshot cache: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/window_background_snapshot_cache_native_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/window_background_snapshot_cache_native_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*window_background_snapshot_cache_native_test.m' \
      "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "window background snapshot cache: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

"$OUTPUT_DIR/window_background_snapshot_cache_native_test" 2>&1 | tee "$OUTPUT_DIR/result.log"
print "window background snapshot cache: passed output=$OUTPUT_DIR"
