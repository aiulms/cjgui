#!/usr/bin/env zsh
# Focused native PNG resource-domain budget counterexample. This compiles the
# production renderer into a standalone native probe; it does not run cjpm or
# open an application window.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
OUTPUT_DIR="${CJGUI_PNG_BUDGET_TMPDIR:-/private/tmp/cjgui-png-resource-budget}/$(date +%Y%m%d%H%M%S)-$$"
if [[ -z "$SDKROOT_PATH" || ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "png resource budget test: unavailable macOS SDK=$SDKROOT_PATH"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
FIXTURE="$OUTPUT_DIR/valid-3x2.png"
FIXTURE_META="$(python3 "$RUNTIME_DIR/native/tests/png_fixture.py" valid "$FIXTURE")"
ALTERNATE="$OUTPUT_DIR/valid-alt-3x2.png"
python3 "$RUNTIME_DIR/native/tests/png_fixture.py" valid-alt "$ALTERNATE" >"$OUTPUT_DIR/valid-alt.json"
RGB="$OUTPUT_DIR/valid-rgb-3x2.png"
python3 "$RUNTIME_DIR/native/tests/png_fixture.py" valid-rgb "$RGB" >"$OUTPUT_DIR/valid-rgb.json"
OVER_DIMENSION="$OUTPUT_DIR/over-dimension.png"
python3 "$RUNTIME_DIR/native/tests/png_fixture.py" over-dimension "$OVER_DIMENSION" >"$OUTPUT_DIR/over-dimension.json"
OVER_PIXEL="$OUTPUT_DIR/over-pixel.png"
python3 "$RUNTIME_DIR/native/tests/png_fixture.py" over-pixel "$OVER_PIXEL" >"$OUTPUT_DIR/over-pixel.json"
GRAY="$OUTPUT_DIR/grayscale.png"
INDEXED="$OUTPUT_DIR/indexed.png"
RGB16="$OUTPUT_DIR/rgb16.png"
BAD_DEFLATE="$OUTPUT_DIR/bad-deflate.png"
for kind in grayscale indexed rgb16 bad-deflate; do
  python3 "$RUNTIME_DIR/native/tests/png_fixture.py" "$kind" "$OUTPUT_DIR/$kind.png" >"$OUTPUT_DIR/$kind.json"
done
BEACON="$RUNTIME_DIR/resources/composable-beacon.png"
BEACON_CORAL="$RUNTIME_DIR/resources/composable-beacon-coral.png"
[[ -f "$BEACON" && -f "$BEACON_CORAL" ]] || {
  print -u2 'png resource budget test: existing two-beacon baseline resources missing'
  exit 2
}

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_png_resource_budget_test.m" \
  "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/composable_png_resource_budget_test" \
  >"$OUTPUT_DIR/build.stdout.log" 2>"$OUTPUT_DIR/build.stderr.log" || {
    rg -n ': error:|warning:.*composable_png_resource_budget_test.m' "$OUTPUT_DIR/build.stderr.log" | tail -80 >&2 || true
    print -u2 "png resource budget test: native probe compile failed output=$OUTPUT_DIR"
    exit 2
  }

"$OUTPUT_DIR/composable_png_resource_budget_test" "$FIXTURE" "$BEACON" "$BEACON_CORAL" \
  "$OVER_DIMENSION" "$GRAY" "$INDEXED" "$RGB16" "$BAD_DEFLATE" "$ALTERNATE" "$OVER_PIXEL" "$RGB" \
  2>&1 | tee "$OUTPUT_DIR/result.log"
print "png resource budget test: passed fixture=$(shasum -a 256 "$FIXTURE" | awk '{print $1}') metadata=$FIXTURE_META output=$OUTPUT_DIR"
