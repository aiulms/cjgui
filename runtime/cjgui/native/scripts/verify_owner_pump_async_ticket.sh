#!/usr/bin/env zsh
# Deterministic native pump handoff regression. Uses an actual AppKit main run
# loop and a private FIFO seam; does not inject system-wide input.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_ROOT="${CJGUI_OWNER_PUMP_TMPDIR:-/private/tmp/cjgui-owner-pump-async-ticket}"
OUTPUT_DIR="$OUTPUT_ROOT/$(date +%Y%m%d%H%M%S)-$$"

if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "owner pump async ticket: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/owner_pump_async_ticket_native_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/owner_pump_async_ticket_native_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*owner_pump_async_ticket_native_test.m' \
      "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "owner pump async ticket: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

"$OUTPUT_DIR/owner_pump_async_ticket_native_test" 2>&1 | tee "$OUTPUT_DIR/result.log"
print "owner pump async ticket: passed output=$OUTPUT_DIR"
