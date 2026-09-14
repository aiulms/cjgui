#!/usr/bin/env zsh

# Direct normal-window test entry. It drives the production Cangjie
# controller/window boundary through the production native FIFO, then proves
# that a text intent reaches the controller before its Apply intent. The
# native injection symbol is compiled only into this probe sidecar.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
OUTPUT_DIR="${CJGUI_COMPOSABLE_UI_WINDOW_CONTROLLER_TMPDIR:-/private/tmp/cjgui-composable-ui-window-controller}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui composable window controller probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_composable_ui_window_controller.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/composable_ui_window_controller_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_composable_ui_window_controller \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_ui_window_controller_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/composable_ui_window_controller_probe"
