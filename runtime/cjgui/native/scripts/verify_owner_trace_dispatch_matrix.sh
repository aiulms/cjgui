#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
repo_dir="$(cd "$runtime_dir/../.." && pwd)"
output_dir="${CJGUI_OWNER_DISPATCH_MATRIX_TMPDIR:-$(mktemp -d /private/tmp/cjgui-owner-dispatch-matrix.XXXXXX)}"
sdkroot_path="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/owner_trace_dispatch_matrix_native_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/owner_trace_dispatch_matrix_native_test" >"$output_dir/build.log" 2>&1 || {
    tail -80 "$output_dir/build.log"
    exit 1
  }
for mode in blocked idle; do
  "$output_dir/owner_trace_dispatch_matrix_native_test" "$mode" 2>"$output_dir/$mode.trace.log"
  python3 "$runtime_dir/native/tests/test_owner_trace_dispatch_matrix.py" \
    "$mode" "$output_dir/$mode.trace.log"
done
printf 'fixture_kind=normal-macro-false-native-renderer-consumer\n'
printf 'fixture_modes=blocked,idle\n'
printf 'fixture_artifacts=%s\n' "$output_dir"
