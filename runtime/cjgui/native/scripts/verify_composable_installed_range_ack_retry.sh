#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
output_dir="${CJGUI_INSTALLED_RANGE_ACK_RETRY_TMPDIR:-$(mktemp -d /private/tmp/cjgui-installed-range-ack-retry.XXXXXX)}"
mkdir -p "$output_dir"

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_installed_range_ack_retry_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_installed_range_ack_retry_test" \
  >"$output_dir/build.log" 2>&1 || {
    tail -100 "$output_dir/build.log"
    exit 1
  }

"$output_dir/composable_installed_range_ack_retry_test" >"$output_dir/native.log" 2>&1 || {
  tail -100 "$output_dir/native.log"
  exit 1
}
rg '^CJGUI_TEST_INSTALLED_RANGE_ACK_(FAIL_ONCE|RETRY_SUCCESS)|^ACK_RETRY_PROBE |^installed_range_ack_retry failures=0$' \
  "$output_dir/native.log"
