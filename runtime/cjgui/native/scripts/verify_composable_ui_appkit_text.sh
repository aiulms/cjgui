#!/usr/bin/env zsh

# Direct normal-window probe for the upstream text path. It intentionally
# drives the production NSTextView delegate, not the test FIFO enqueue seam.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_COMPOSABLE_UI_APPKIT_TEXT_TMPDIR:-/private/tmp/cjgui-composable-ui-appkit-text}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui composable AppKit text probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
# This probe is part of the current CJGUI runtime baseline. Keep its build
# compiler explicit so a shell's generic Cangjie installation cannot silently
# compare 1.1.0 and 1.1.3 measurements in the same report.
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
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
ar rcs "$OUTPUT_DIR/native/libcjgui_composable_ui_appkit_text.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/composable_ui_appkit_text_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_composable_ui_appkit_text \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_ui_appkit_text_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
glyph_diagnostics=0
if [[ $# -eq 1 && "$1" == "--glyph-diagnostics" ]]; then
  glyph_diagnostics=1
  set --
fi
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--cost" && "$1" != "--cost-cold" && "$1" != "--cost-cold-single" && "$1" != "--diagnostic" && "$1" != "--multi-window" && "$1" != "--multi-window-fairness" && "$1" != "--multi-window-reentrancy" && "$1" != "--multi-window-exception-guard" && "$1" != "--multi-window-identity" && "$1" != "--multi-window-partial-creation" && "$1" != "--steady-cost" && "$1" != "--input-callback-trace" && "$1" != "--backing-scale" && "$1" != "--visible-layout-baseline" && "$1" != "--renderer-work-cost" && "$1" != "--selection-resource-cost" && "$1" != "--selection-resource-cost=full" && "$1" != "--selection-resource-cost-smoke" && "$1" != "--selection-resource-cost-smoke=full" && "$1" != "--selection-resource-cost-smoke-coverage" && "$1" != "--selection-resource-cost-smoke-coverage=full" ) ]]; then
  echo "usage: $0 [--cost|--cost-cold|--cost-cold-single|--diagnostic|--multi-window|--multi-window-fairness|--multi-window-reentrancy|--multi-window-exception-guard|--multi-window-identity|--multi-window-partial-creation|--steady-cost|--input-callback-trace|--backing-scale|--visible-layout-baseline|--renderer-work-cost|--selection-resource-cost[=full]|--selection-resource-cost-smoke[=full]|--selection-resource-cost-smoke-coverage[=full]|--glyph-diagnostics]" >&2
  exit 2
fi
if (( glyph_diagnostics )); then
  CJGUI_INTERNAL_VERBOSE_GLYPH_DIAGNOSTICS=1 "$OUTPUT_DIR/composable_ui_appkit_text_probe" "$@"
else
  "$OUTPUT_DIR/composable_ui_appkit_text_probe" "$@"
fi
