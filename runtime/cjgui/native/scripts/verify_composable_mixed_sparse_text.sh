#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUTPUT_DIR="${CJGUI_MIXED_SPARSE_TMPDIR:-/private/tmp/cjgui-mixed-sparse-text}/$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$OUTPUT_DIR"

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_mixed_sparse_text_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/composable_mixed_sparse_text_test" \
  >"$OUTPUT_DIR/build.log" 2>&1 || {
    rg -n ': error:|warning:' "$OUTPUT_DIR/build.log" | tail -40 >&2 || true
    exit 2
  }
"$OUTPUT_DIR/composable_mixed_sparse_text_test" | tee "$OUTPUT_DIR/result.log"
rg -q '^CJGUI_MIXED_SPARSE clones=30/30 text_prepares=0/0 empty_layout=1 tiny_unprepared=1 rejected_keeps_old=1 kind_clear=1$' "$OUTPUT_DIR/result.log"
print -r -- "CJGUI_MIXED_SPARSE_VERIFY passed=true output=$OUTPUT_DIR"
