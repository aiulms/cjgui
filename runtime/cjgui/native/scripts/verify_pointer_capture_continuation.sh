#!/usr/bin/env zsh
# Native-only gate for capture continuation across an accepted windowed scene.
# Does not show a window or synthesize system input.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
output_dir="${CJGUI_POINTER_CAPTURE_CONTINUATION_TMPDIR:-$(mktemp -d /private/tmp/cjgui-pointer-capture-continuation.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_pointer_capture_continuation_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  "$runtime_dir/native/cjgui_async_multiline_measure.m" \
  "$runtime_dir/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_pointer_capture_continuation_test"
"$output_dir/composable_pointer_capture_continuation_test"
