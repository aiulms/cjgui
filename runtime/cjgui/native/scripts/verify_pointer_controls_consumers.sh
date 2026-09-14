#!/usr/bin/env zsh
set -euo pipefail

# Dedicated source/probe verifier. It deliberately does not invoke the
# shared cjpm target; the parent task schedules that build serially.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROBE="$RUNTIME_DIR/probe/pointer_controls_consumer_probe.cj"
RULE_MAIN="$RUNTIME_DIR/examples/rule_set_window_app/src/main.cj"
DOC_MAIN="$RUNTIME_DIR/examples/shared_document_window_app/src/main.cj"
TMP_DIR="${CJGUI_POINTER_CONTROLS_TMPDIR:-/private/tmp/cjgui-pointer-controls-consumers}"

require_line() {
  local needle="$1"
  local file="$2"
  if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
    echo "pointer-controls verifier: missing '$needle' in $file" >&2
    exit 10
  fi
}

require_line "cjguiComposableSplitView" "$RUNTIME_DIR/src/composable_ui.cj"
require_line "cjguiComposableSlider" "$RUNTIME_DIR/src/composable_ui.cj"
require_line "CJGUI_COMPOSABLE_UI_SPLIT_HANDLE" "$RUNTIME_DIR/src/composable_ui.cj"
require_line "CJGUI_COMPOSABLE_UI_SLIDER" "$RUNTIME_DIR/src/composable_ui.cj"
require_line "CjguiComposableUiSplitGeometry" "$RUNTIME_DIR/src/composable_ui.cj"
require_line "CjguiComposableUiSliderGeometry" "$RUNTIME_DIR/src/composable_ui.cj"
require_line "main(): Int64" "$PROBE"
require_line "CjguiComposableUiLayoutEngine.layout" "$PROBE"
require_line "cjguiComposableSplitView" "$PROBE"
require_line "cjguiComposableSlider" "$PROBE"
require_line "ProbeCasOwner" "$PROBE"
require_line "stale pointer cannot overwrite external value" "$PROBE"
require_line "cjguiComposableScopedSplitView" "$RULE_MAIN"
require_line "cjguiComposableSlider" "$DOC_MAIN"
require_line "operationResourceId" "$RULE_MAIN"
require_line "operationResourceId" "$DOC_MAIN"
require_line "event.pointerX" "$RULE_MAIN"
require_line "event.pointerX" "$DOC_MAIN"
require_line "previewLimit" "$DOC_MAIN"
require_line "splitFirstSize" "$RULE_MAIN"

if rg -n "cjgui_internal_renderer|runtime_state|renderer_state|NSEvent|NSView" "$PROBE" >/dev/null 2>&1; then
  echo "pointer-controls verifier: probe leaked native/runtime state" >&2
  exit 11
fi

# Compile only the platform-free public source and probe into a dedicated
# temporary output. This reads the already-built shared-core artifact and
# never invokes the cjgui cjpm target shared with the parent task.
if ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh" ]]; then
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
    set -u
  fi
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "pointer-controls verifier: cjc unavailable (static contract passed; compile not_run)" >&2
  exit 12
fi
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
SHARED_CORE="$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core"
if [[ ! -f "$SHARED_CORE/libcjgui_shared_operation_core.a" ]]; then
  echo "pointer-controls verifier: shared-core artifact missing" >&2
  exit 13
fi
mkdir -p "$TMP_DIR"
COMPILE_LOG="$TMP_DIR/compile.log"
if ! SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  cjc --sysroot /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  --import-path "$SHARED_CORE" "$RUNTIME_DIR/src/composable_ui.cj" "$PROBE" \
  -L "$SHARED_CORE" -lcjgui_shared_operation_core -o "$TMP_DIR/pointer_controls_probe" \
  >"$COMPILE_LOG" 2>&1; then
  cat "$COMPILE_LOG" >&2
  exit 14
fi
if ! "$TMP_DIR/pointer_controls_probe" >>"$COMPILE_LOG" 2>&1; then
  cat "$COMPILE_LOG" >&2
  exit 15
fi

echo "pointer-controls verifier: PASS source-contract=1 probe-contract=1 split-consumer=1 slider-consumer=1 cas-interleave=1 keyboard-bounds=1"
