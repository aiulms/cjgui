#!/usr/bin/env zsh

# Exercises the production multiline raster's CPU-scratch accounting on the
# exact `rasterizeMultilineNode` path: success must count and release its
# transient BGRA allocation, a post-allocation failure must still release,
# and a never-allocated rejection must not move the counters.
#
# Stage "长文本增量更新与完整样式绑定" A2.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
output_dir="${CJGUI_MULTILINE_SCRATCH_TMPDIR:-$(mktemp -d /private/tmp/cjgui-multiline-scratch.XXXXXX)}"

if [[ ! -d "$sdkroot_path" ]]; then
  print -u2 "cjgui multiline scratch test: unavailable SDKROOT=$sdkroot_path"
  exit 2
fi

mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_multiline_scratch_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_multiline_scratch_test"
"$output_dir/composable_multiline_scratch_test"
