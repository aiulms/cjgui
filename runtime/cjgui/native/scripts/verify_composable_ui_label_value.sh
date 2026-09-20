#!/usr/bin/env zsh

# Exercises the production Objective-C display-text helper directly.  The
# test translation unit imports the renderer implementation, so this is not a
# copied string-formatting policy.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
output_dir="${CJGUI_COMPOSABLE_LABEL_VALUE_TMPDIR:-$(mktemp -d /private/tmp/cjgui-composable-label-value.XXXXXX)}"

if [[ ! -d "$sdkroot_path" ]]; then
  print -u2 "cjgui composable label/value test: unavailable SDKROOT=$sdkroot_path"
  exit 2
fi

mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_ui_label_value_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_ui_label_value_test"
"$output_dir/composable_ui_label_value_test"
print "cjgui composable label/value test: passed output=$output_dir"
