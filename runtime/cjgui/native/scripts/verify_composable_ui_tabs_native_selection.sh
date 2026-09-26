#!/usr/bin/env zsh
# Controlled TextKit selection replacement after a production tab round trip.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="$(xcrun --sdk macosx --show-sdk-path)"
output_dir="${CJGUI_TABS_NATIVE_SELECTION_TMPDIR:-/private/tmp/cjgui-tabs-native-selection}"
mkdir -p "$output_dir/native"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  -c "$runtime_dir/native/cjgui_internal_renderer.m" -o "$output_dir/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  -c "$runtime_dir/native/cjgui_native_bridge.m" -o "$output_dir/native/cjgui_native_bridge.o"
ar rcs "$output_dir/native/libcjgui_tabs_native_selection.a" \
  "$output_dir/native/cjgui_internal_renderer.o" "$output_dir/native/cjgui_native_bridge.o"

cjc --sysroot "$sdkroot_path" \
  --import-path "$runtime_dir/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$runtime_dir/src/runtime_renderer_session.cj" \
  "$runtime_dir/src/composable_ui.cj" \
  "$runtime_dir/src/composable_ui_component_instance.cj" \
  "$runtime_dir/src/composable_ui_window.cj" \
  "$runtime_dir/src/macos_application_host.cj" \
  "$runtime_dir/probe/composable_ui_tabs_native_selection_probe.cj" \
  -L "$runtime_dir/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$output_dir/native" -lcjgui_tabs_native_selection \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$output_dir/composable_ui_tabs_native_selection_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$output_dir/composable_ui_tabs_native_selection_probe" > "$output_dir/probe.log" 2>&1
grep -q '^CJGUI_TABS_NATIVE_SELECTION .*owner=甲X乙 .*other=其他字段 .*passed=true$' "$output_dir/probe.log"
echo "PASSED composable ui tabs native selection output=$output_dir"
