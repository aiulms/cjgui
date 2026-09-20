#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_INTERACTION_STYLE_THEME_CONTINUITY_TMPDIR:-/private/tmp/cjgui-interaction-style-theme-continuity}"
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
PROBE_SRC="$RUNTIME_DIR/probe/interaction_style_theme_continuity_probe.cj"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

require_source_line() {
  local expected="$1"
  if ! rg -F -q "$expected" "$PROBE_SRC"; then
    print -u2 -- "theme continuity verifier: missing probe source line: $expected"
    exit 1
  fi
}

require_source_line "cjgui_internal_renderer_test_set_composable_selection"
require_source_line "cjgui_internal_renderer_test_scroll_composable_multiline"
require_source_line "cjgui_internal_renderer_test_set_composable_present_failures"
require_source_line "togglePaintOnlyTheme"
require_source_line "failed_candidate_retained"
require_source_line "CjguiComposableUiTheme.beaconDark()"
require_source_line "CjguiComposableUiTheme.paperLight()"
if rg -q 'fontFamily:|fontSize:' "$PROBE_SRC"; then
  print -u2 -- "theme continuity verifier: theme probe must remain paint-only"
  exit 1
fi

mkdir -p "$OUTPUT_DIR/native"
(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -isysroot "$SDKROOT_PATH" \
  -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_interaction_style_theme_continuity.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$PROBE_SRC" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_interaction_style_theme_continuity \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/interaction_style_theme_continuity_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/interaction_style_theme_continuity_probe" | tee "$OUTPUT_DIR/result"
rg -q '^CJGUI_INTERACTION_STYLE_THEME_CONTINUITY theme_changed=true selection_preserved=true focus_preserved=true scroll_preserved=true idle_no_work=true failed_candidate_retained=true action_preserved=true recovered=true valid=true$' "$OUTPUT_DIR/result"
print -r -- "composable ui interaction style theme continuity verification: PASS"
