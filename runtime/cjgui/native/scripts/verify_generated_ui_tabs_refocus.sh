#!/usr/bin/env zsh
# Focus ROLE re-establishment for the export chain's step2c, on the REAL AppKit
# responder route.
#
# The desktop chain cannot run while the console session is locked. This probe
# verifies the SAME mechanism in-process: a text input steals the first-responder
# role (a posted key no longer reaches the overlay's `keyDown`), and the production
# Accessibility press on a tab TITLE gives the role back so the very next key does
# reach it. The press is taken by stable nodeId, so the probe cannot silently press
# a neighbouring control.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
OUTPUT_DIR="${CJGUI_TABS_REFOCUS_TMPDIR:-/private/tmp/cjgui-tabs-refocus}"

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
ar rcs "$OUTPUT_DIR/native/libcjgui_tabs_refocus.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/generated_ui_tabs_refocus_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_tabs_refocus \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/generated_ui_tabs_refocus_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
set +e
"$OUTPUT_DIR/generated_ui_tabs_refocus_probe" | tee "$OUTPUT_DIR/probe.log"
PROBE_STATUS="${pipestatus[1]}"
set -e

LOG="$OUTPUT_DIR/probe.log"
fail() {
  echo "cjgui tabs refocus: $*" >&2
  exit 1
}

grep -q '^CJGUI_TABS_REFOCUS_TITLES .*valid=true' "$LOG" \
  || fail "the probe window did not expose both titles, the active-page editor and a hidden notes page"
grep -q '^CJGUI_TABS_REFOCUS_RED .*route_reached=false .*active=basic ok=true' "$LOG" \
  || fail "a posted key reached the overlay while the text input owned the first-responder role"
grep -q '^CJGUI_TABS_REFOCUS_AXPRESS .*capture=0 press=0 .*active=notes .*notes_h=[1-9][0-9]*.*ok=true' "$LOG" \
  || fail "the Accessibility press on the notes title did not select the notes page"
grep -q '^CJGUI_TABS_REFOCUS_GREEN .*route_reached=true .*ok=true' "$LOG" \
  || fail "the Accessibility press did not give the first-responder role back to the overlay"
grep -q '^CJGUI_TABS_REFOCUS_REPEAT_RED .*back_ok=true .*route_reached=false .*active=basic ok=true' "$LOG" \
  || fail "the probe did not re-establish the taken-away responder state before the repeat"
grep -q '^CJGUI_TABS_REFOCUS_REPEAT_GREEN .*press=0 .*route_reached=true .*active=basic ok=true' "$LOG" \
  || fail "pressing the ALREADY-ACTIVE title did not restore the responder role"
grep -q '^CJGUI_TABS_REFOCUS passed=true$' "$LOG" \
  || fail "the tab refocus probe did not pass (status=$PROBE_STATUS)"

if (( PROBE_STATUS != 0 )); then
  echo "cjgui tabs refocus: probe failed status=$PROBE_STATUS output=$OUTPUT_DIR" >&2
  exit "$PROBE_STATUS"
fi
echo "PASSED generated ui tabs refocus output=$OUTPUT_DIR"
