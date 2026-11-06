#!/usr/bin/env zsh
# Exact-once refresh-demand notification boundary. Uses real tickets and an
# asynchronous main service; it does not inject system-wide input.
# Set CJGUI_REFRESH_BOUNDARY_RED_SOURCE=<abs path to the pre-change renderer>
# to build the same test against the two-call production sequence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_ROOT="${CJGUI_REFRESH_BOUNDARY_TMPDIR:-/private/tmp/cjgui-owner-refresh-demand-boundary}"
OUTPUT_DIR="$OUTPUT_ROOT/$(date +%Y%m%d%H%M%S)-$$"

if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "owner refresh demand boundary: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
defines=()
if [[ -n "${CJGUI_REFRESH_BOUNDARY_RED_SOURCE:-}" ]]; then
  defines+=(-DCJGUI_REFRESH_DEMAND_BOUNDARY_RED
    -DCJGUI_REFRESH_DEMAND_BOUNDARY_RED_SOURCE="\"$CJGUI_REFRESH_BOUNDARY_RED_SOURCE\"")
fi

clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -I "$RUNTIME_DIR/native" "${defines[@]}" \
  "$RUNTIME_DIR/native/tests/owner_refresh_demand_boundary_native_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/owner_refresh_demand_boundary_native_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*owner_refresh_demand_boundary_native_test.m' \
      "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "owner refresh demand boundary: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

"$OUTPUT_DIR/owner_refresh_demand_boundary_native_test" 2>&1 | tee "$OUTPUT_DIR/result.log"
print "owner refresh demand boundary: passed output=$OUTPUT_DIR"
