#!/usr/bin/env zsh
# B1: tab TITLE keyboard rules on the REAL AppKit responder route.
#
# The probe posts synthetic keys through NSApplication's responder chain (the same
# test seam the pointer-capture probe uses) and reports the route flags, so
# "Left/Right move the title focus" and "Return/Space switch the page" are
# verified where a real key would arrive - not by constructing a Cangjie event.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
OUTPUT_DIR="${CJGUI_TABS_KEYBOARD_TMPDIR:-/private/tmp/cjgui-reveal-keyboard}"

set +u
source "/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
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
ar rcs "$OUTPUT_DIR/native/libcjgui_reveal_keyboard.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/generated_ui_reveal_keyboard_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_reveal_keyboard \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/generated_ui_reveal_keyboard_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
set +e
"$OUTPUT_DIR/generated_ui_reveal_keyboard_probe" | tee "$OUTPUT_DIR/probe.log"
PROBE_STATUS="${pipestatus[1]}"
set -e

LOG="$OUTPUT_DIR/probe.log"
fail() {
  echo "cjgui reveal keyboard: $*" >&2
  exit 1
}

grep -q '^CJGUI_REVEAL_KEYBOARD_LAYOUT .*top_h=[1-9][0-9]*.*bottom_visible_before=false.*offset_before=0' "$LOG" \
  || fail "the probe window did not present a visible top control and a clipped bottom control"
grep -q '^CJGUI_REVEAL_KEYBOARD_FOCUS clipped_again=true .*bottom_visible_after=true.*ok=true' "$LOG" \
  || fail "the framework's focus entry did not reveal the clipped control"
grep -q '^CJGUI_REVEAL_KEYBOARD_TAB top_focused=true route_ok=true revealed=true .*ok=true' "$LOG" \
  || fail "a real Tab through the responder chain did not reveal the clipped control"
grep -q '^CJGUI_REVEAL_KEYBOARD passed=true$' "$LOG" \
  || fail "the reveal keyboard probe did not pass (status=$PROBE_STATUS)"

if (( PROBE_STATUS != 0 )); then
  echo "cjgui reveal keyboard: probe failed status=$PROBE_STATUS output=$OUTPUT_DIR" >&2
  exit "$PROBE_STATUS"
fi
echo "PASSED generated ui reveal keyboard output=$OUTPUT_DIR"
