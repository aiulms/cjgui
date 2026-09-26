#!/usr/bin/env zsh

# Exercises the production focus-skip predicate directly.  The test
# translation unit imports the renderer implementation, so the assertions
# cover the exact `CjguiStagedNodeIsFocusedInput` the prepare pass calls.
#
# Stage A1 counter-example guard: a focused tab title or button must NOT take
# the active-input preparation skip (their static candidate must rasterize so
# a same-commit label/textColor change reaches the texture), while real text
# inputs keep the skip benefit.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
output_dir="${CJGUI_FOCUSED_INPUT_SKIP_TMPDIR:-$(mktemp -d /private/tmp/cjgui-focused-input-skip.XXXXXX)}"

if [[ ! -d "$sdkroot_path" ]]; then
  print -u2 "cjgui focused-input skip test: unavailable SDKROOT=$sdkroot_path"
  exit 2
fi

mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_focused_input_skip_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_focused_input_skip_test"
"$output_dir/composable_focused_input_skip_test"
