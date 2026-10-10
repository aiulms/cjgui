#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
output_dir="${CJGUI_OWNER_MANAGED_TRACE_TMPDIR:-$(mktemp -d /private/tmp/cjgui-owner-managed-trace.XXXXXX)}"
sdkroot_path="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/owner_trace_managed_identity_native_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/owner_trace_managed_identity_native_test" >"$output_dir/build.log" 2>&1 || {
    tail -80 "$output_dir/build.log"
    exit 1
  }
"$output_dir/owner_trace_managed_identity_native_test" 2>"$output_dir/managed.trace.log"
python3 "$runtime_dir/native/tests/test_owner_trace_managed_identity.py" "$output_dir/managed.trace.log"
printf 'fixture_kind=trace-managed-sideband-watch-register-and-nonblocking-retirement\n'
printf 'fixture_artifacts=%s\n' "$output_dir"
