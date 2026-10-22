#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
output_dir="${CJGUI_FONT_OUTPUT:?set an owned evidence directory}"
mkdir -p "$output_dir"
binary="$output_dir/font-resource-test"
# One transient executable; exact owned file is removed on all exit paths.
trap 'rm -f -- "$binary"' EXIT INT TERM
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_ASYNC_MULTILINE_MEASURE_TESTING=1 \
  -isysroot "$(xcrun --sdk macosx --show-sdk-path)" -mmacosx-version-min=12.0 \
  "${CJGUI_FONT_TEST_SOURCE:-$runtime_dir/native/tests/composable_font_resource_test.m}" "$runtime_dir/native/cjgui_native_bridge.m" \
  "$runtime_dir/native/cjgui_async_multiline_measure.m" \
  "$runtime_dir/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -framework CoreText -lobjc \
  -o "$binary" >"$output_dir/build.log" 2>&1
"$binary" "$runtime_dir/resources/fonts/Lilex-Regular.ttf"
