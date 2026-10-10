#!/usr/bin/env zsh
# Isolated native host-pump timing and lifecycle regression.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_ROOT="${CJGUI_HOST_PUMP_TMPDIR:-/private/tmp/cjgui-host-pump-wait}"
OUTPUT_DIR="$OUTPUT_ROOT/$(date +%Y%m%d%H%M%S)-$$"

if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "host pump wait: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_host_pump_wait_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/composable_host_pump_wait_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*composable_host_pump_wait_test.m' \
      "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "host pump wait: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

set +e
"$OUTPUT_DIR/composable_host_pump_wait_test" > >(tee "$OUTPUT_DIR/result.log") 2>&1
result_code=$?
set -e
print "host pump wait: exit=$result_code output=$OUTPUT_DIR"
exit "$result_code"
