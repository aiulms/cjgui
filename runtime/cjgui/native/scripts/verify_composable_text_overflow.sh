#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
output_dir="${CJGUI_TEXT_OVERFLOW_OUTPUT:?set an owned bounded evidence directory}"
mkdir -p "$output_dir"
binary="$output_dir/composable_text_overflow_test"
# One reusable binary, at most 8MiB transient; logs remain below 1MiB.
# Successful, failed and cancelled runs release the compiler's executable.
trap 'rm -f -- "$binary"' EXIT INT TERM
shasum -a 256 "$runtime_dir/native/cjgui_internal_renderer.m" \
  "$runtime_dir/native/cjgui_internal_renderer.h" \
  "$runtime_dir/native/tests/composable_text_overflow_test.m"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$(xcrun --sdk macosx --show-sdk-path)" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_text_overflow_test.m" "$runtime_dir/native/cjgui_native_bridge.m" \
  "$runtime_dir/native/cjgui_async_multiline_measure.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$binary" >"$output_dir/build.log" 2>&1
"$binary" "$@"
