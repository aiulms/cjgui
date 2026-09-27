#!/usr/bin/env zsh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib_cjgui_source_set.sh"
OUTPUT_DIR="${CJGUI_INTERACTION_STYLE_NATIVE_TMPDIR:-/private/tmp/cjgui-interaction-style-native}"
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"
(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -isysroot "$SDKROOT_PATH" \
  -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_interaction_style_native.a" "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
cjc --sysroot "$SDKROOT_PATH" --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/composable_ui_interaction_style_native_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_interaction_style_native \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/interaction_style_native_probe"
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/interaction_style_native_probe" | tee "$OUTPUT_DIR/result"
