#!/usr/bin/env zsh

# Controlled normal-window transfer proof. The synthetic dragging info exists
# only in the probe-side renderer build; FIFO draining, identity/format
# validation and the document owner are the production Cangjie path.
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
OUTPUT_DIR="${CJGUI_COMPOSABLE_DATA_TRANSFER_WINDOW_INTEGRATION_TMPDIR:-/private/tmp/cjgui-composable-data-transfer-window-integration}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui controlled data-transfer window probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
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
ar rcs "$OUTPUT_DIR/native/libcjgui_controlled_data_transfer_window.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/composable_data_transfer_window_integration_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_controlled_data_transfer_window \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_data_transfer_window_integration_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
RUN_LOG="$OUTPUT_DIR/composable_data_transfer_window_integration_probe.log"
set +e
"$OUTPUT_DIR/composable_data_transfer_window_integration_probe" >"$RUN_LOG" 2>&1
STATUS=$?
set -e
# A3 lifecycle judgment runs INSIDE the probe (explicit convergence +
# autorelease drain): the judge line is the deterministic verdict.  With
# CJGUI_TRANSFER_LEAK_TEST=<N> the probe retains its Nth filled object, the
# first judge reports the retained id as not-released, the retain is dropped
# and the second judge must be balanced (negative control proving the judge
# can fail).
LIFECYCLE_LINE="$(grep 'CJGUI_TRANSFER_LIFECYCLE' "$RUN_LOG" | tail -1 || true)"
if [[ "$STATUS" == 0 ]]; then
  echo "$LIFECYCLE_LINE" | grep -q 'ok=true' || {
    echo "lifecycle judge failed: $LIFECYCLE_LINE" >&2
    exit 1
  }
  grep 'cjgui: LEDGER' "$RUN_LOG" || true
else
  grep -E 'cjgui: LEDGER|transfer item (create|release)' "$RUN_LOG" | head -30 || true
fi
cat "$RUN_LOG"
print -r -- "cjgui controlled data-transfer window probe: raw_log=$RUN_LOG status=$STATUS"
exit "$STATUS"
