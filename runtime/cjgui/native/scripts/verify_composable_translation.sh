#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="$(xcrun --sdk macosx --show-sdk-path)"
output_dir="${CJGUI_TRANSLATION_TMPDIR:-$(mktemp -d /private/tmp/cjgui-translation.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_translation_native_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_translation_native_test" >"$output_dir/build.log" 2>&1 || {
    tail -80 "$output_dir/build.log"
    exit 1
  }
"$output_dir/composable_translation_native_test"
