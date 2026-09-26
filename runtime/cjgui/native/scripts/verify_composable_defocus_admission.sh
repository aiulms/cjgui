#!/usr/bin/env zsh

# Exercises the defocus re-admission (text resource prepare pass) on the two
# production rejection judgments — scene aggregate budget rejection and
# tile-plan failure — and asserts the retained old resources survive byte-for-
# byte, plus a healthy-prepare recovery. Sibling byte counts are fabricated to
# fill the unmodified 24MB production capacity (controlled evidence).
#
# Stage "长文本增量更新与完整样式绑定" A3.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
output_dir="${CJGUI_DEFOCUS_ADMISSION_TMPDIR:-$(mktemp -d /private/tmp/cjgui-defocus-admission.XXXXXX)}"

if [[ ! -d "$sdkroot_path" ]]; then
  print -u2 "cjgui defocus admission test: unavailable SDKROOT=$sdkroot_path"
  exit 2
fi

mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_defocus_admission_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_defocus_admission_test"
"$output_dir/composable_defocus_admission_test"
