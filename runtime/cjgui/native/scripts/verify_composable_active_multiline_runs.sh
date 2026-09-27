#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
output_dir="${CJGUI_ACTIVE_MULTILINE_RUNS_TMPDIR:-$(mktemp -d /private/tmp/cjgui-active-multiline-runs.XXXXXX)}"

if [[ ! -d "$sdkroot_path" ]]; then
  print -u2 "cjgui active multiline runs test: unavailable SDKROOT=$sdkroot_path"
  exit 2
fi

mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_active_multiline_runs_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_active_multiline_runs_test"
"$output_dir/composable_active_multiline_runs_test"
