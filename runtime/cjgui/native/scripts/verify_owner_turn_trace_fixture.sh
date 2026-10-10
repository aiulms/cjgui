#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
repo_dir="$(cd "$runtime_dir/../.." && pwd)"
sdkroot_path="$(xcrun --sdk macosx --show-sdk-path)"
output_dir="${CJGUI_OWNER_TRACE_FIXTURE_TMPDIR:-$(mktemp -d /private/tmp/cjgui-owner-trace.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/owner_turn_trace_native_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/owner_turn_trace_native_test" >"$output_dir/build.log" 2>&1 || {
    tail -80 "$output_dir/build.log"
    exit 1
  }
for mode in mainqueue output idle; do
  "$output_dir/owner_turn_trace_native_test" "$mode" 2>"$output_dir/$mode.trace.log"
  python3 "$repo_dir/artifacts/e-macos-large-visual-20261002/tools/test_owner_turn_trace.py" \
    "$mode" "$output_dir/$mode.trace.log"
  python3 "$repo_dir/artifacts/e-macos-large-visual-20261002/tools/test_owner_trace_export_lifecycle.py" \
    "$mode" "$output_dir/$mode.trace.log"
done
"$output_dir/owner_turn_trace_native_test" exit-no-explicit-export \
  2>"$output_dir/exit-no-explicit-export.trace.log"
python3 "$repo_dir/artifacts/e-macos-large-visual-20261002/tools/test_owner_trace_export_lifecycle.py" \
  exit-no-explicit-export "$output_dir/exit-no-explicit-export.trace.log"
printf 'fixture_kind=normal-macro-false-native-bridge-consumer\n'
printf 'fixture_modes=mainqueue,output,idle,exit-no-explicit-export\n'
printf 'fixture_artifacts=%s\n' "$output_dir"
