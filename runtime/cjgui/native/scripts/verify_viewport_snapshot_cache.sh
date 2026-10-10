#!/usr/bin/env zsh
# Isolated native regression for the private renderer viewport scalar cache.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_ROOT="${CJGUI_VIEWPORT_CACHE_TMPDIR:-/private/tmp/cjgui-viewport-snapshot-cache}"
OUTPUT_DIR="$OUTPUT_ROOT/$(date +%Y%m%d%H%M%S)-$$"

if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "viewport snapshot cache: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/viewport_snapshot_cache_native_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/viewport_snapshot_cache_native_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*viewport_snapshot_cache_native_test.m' \
      "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "viewport snapshot cache: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

"$OUTPUT_DIR/viewport_snapshot_cache_native_test" 2>&1 | tee "$OUTPUT_DIR/result.log"
print "viewport snapshot cache: completed output=$OUTPUT_DIR"
