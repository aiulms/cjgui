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
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
OUTPUT_DIR="${CJGUI_TABS_KEYBOARD_TMPDIR:-/private/tmp/cjgui-tabs-keyboard}"

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
ar rcs "$OUTPUT_DIR/native/libcjgui_tabs_keyboard.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/generated_ui_tabs_keyboard_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_tabs_keyboard \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/generated_ui_tabs_keyboard_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
set +e
"$OUTPUT_DIR/generated_ui_tabs_keyboard_probe" | tee "$OUTPUT_DIR/probe.log"
PROBE_STATUS="${pipestatus[1]}"
set -e

LOG="$OUTPUT_DIR/probe.log"
fail() {
  echo "cjgui tabs keyboard: $*" >&2
  exit 1
}

grep -q '^CJGUI_TABS_KEYBOARD_TITLES .*advanced_enabled=false .* valid=true' "$LOG" \
  || fail "the probe window did not expose three titles with the middle one disabled"
grep -q '^CJGUI_TABS_KEYBOARD_ENTRY .* route_reached=true .*focused_control='\''tabs-keyboard-probe-tab-basic'\'' .*ok=true' "$LOG" \
  || fail "pure Tab from the previous control did not enter the active title"
grep -q '^CJGUI_TABS_KEYBOARD_ENTRY_PAGE .* route_reached=true .*focused_control='\''tabs-keyboard-editor'\'' .*ok=true' "$LOG" \
  || fail "Tab from the selected title did not enter the current page's first editor"
grep -q '^CJGUI_TABS_KEYBOARD_BACK_TITLE .* route_reached=true .*focused_control='\''tabs-keyboard-probe-tab-basic'\'' .*ok=true' "$LOG" \
  || fail "Shift-Tab from the current page did not return to the selected title"
grep -q '^CJGUI_TABS_KEYBOARD_BACK_OUT .* route_reached=true .*focused_control='\''tabs-keyboard-before'\'' .*ok=true' "$LOG" \
  || fail "Shift-Tab from the selected title did not leave the tab group"
grep -q '^CJGUI_TABS_KEYBOARD_ROUTE step=right .* route_reached=true .* active=basic ok=true' "$LOG" \
  || fail "Right did not move the title focus through the real responder route without switching the page"
grep -q '^CJGUI_TABS_KEYBOARD_PAGE step=return .* route_reached=true .*active=notes.*selected_title='\''tabs-keyboard-probe-tab-notes'\'' .*notes_h=[1-9][0-9]*.*ok=true' "$LOG" \
  || fail "Return did not activate the focused title into an accepted notes page"
grep -q '^CJGUI_TABS_KEYBOARD_ROUTE step=left .* route_reached=true .* active=notes ok=true' "$LOG" \
  || fail "Left did not move the title focus back without switching the page"
grep -q '^CJGUI_TABS_KEYBOARD_PAGE step=space .* route_reached=true .*active=basic.*basic_h=[1-9][0-9]*.*ok=true' "$LOG" \
  || fail "Space did not activate the focused title into an accepted basic page"
grep -q '^CJGUI_TABS_KEYBOARD_DISABLED activated=false active=basic ok=true' "$LOG" \
  || fail "the disabled title was activated"
grep -q '^CJGUI_TABS_KEYBOARD_SPLIT .*route_reached=true .*focused_control='\''tabs-keyboard-split-view-handle'\'' .*arrow_route_reached=true .*before=[0-9][0-9]* after=[0-9][0-9]* ok=true' "$LOG" \
  || fail "Tab did not reach the split divider or its arrow path did not change the accepted size"
grep -q '^CJGUI_TABS_KEYBOARD_SLIDER .*route_reached=true .*focused_control='\''tabs-keyboard-slider'\'' .*arrow_route_reached=true .*before=[0-9][0-9]* after=[0-9][0-9]* ok=true' "$LOG" \
  || fail "Tab did not reach the slider or its arrow path did not change the owner value"
grep -q '^CJGUI_TABS_KEYBOARD passed=true$' "$LOG" \
  || fail "the tab title keyboard probe did not pass (status=$PROBE_STATUS)"

if (( PROBE_STATUS != 0 )); then
  echo "cjgui tabs keyboard: probe failed status=$PROBE_STATUS output=$OUTPUT_DIR" >&2
  exit "$PROBE_STATUS"
fi
echo "PASSED generated ui tabs keyboard output=$OUTPUT_DIR"
