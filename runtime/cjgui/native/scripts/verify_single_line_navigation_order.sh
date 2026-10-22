#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_SINGLE_LINE_ORDER_TMPDIR:-/private/tmp/cjgui-single-line-order}"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
mkdir -p "$OUTPUT_DIR"
trap 'rm -f "$OUTPUT_DIR/single_line_order.part"' EXIT
clang -fobjc-arc -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_single_line_navigation_order_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  "$RUNTIME_DIR/native/cjgui_async_multiline_measure.m" \
  "$RUNTIME_DIR/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -framework CoreText -lobjc \
  -o "$OUTPUT_DIR/single_line_order.part" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log"
mv "$OUTPUT_DIR/single_line_order.part" "$OUTPUT_DIR/single_line_order"
"$OUTPUT_DIR/single_line_order" 2>&1 | tee "$OUTPUT_DIR/result.log"
