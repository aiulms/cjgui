#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
output_dir="${CJGUI_CARET_BLINK_TMPDIR:-$(mktemp -d /private/tmp/cjgui-caret-blink.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_caret_blink_clock_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_caret_blink_clock_test"
"$output_dir/composable_caret_blink_clock_test"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_caret_blink_release_clock_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_caret_blink_release_clock_test"
"$output_dir/composable_caret_blink_release_clock_test"
