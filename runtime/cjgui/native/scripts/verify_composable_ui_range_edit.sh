#!/usr/bin/env zsh

# Normal-window probe for the public range-text seam and the explicit
# text-edit delta event. It drives the production AppKit input path through the
# test-only insert/delete hooks and asserts the delivered (replaced UTF-16
# range, inserted string) plus the exact document byte range the sink received.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_RANGE_EDIT_PROBE_TMPDIR:-/private/tmp/cjgui-range-edit-probe}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui range edit probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
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
ar rcs "$OUTPUT_DIR/native/libcjgui_range_edit_probe.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/range_text.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_named_style.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/composable_ui_range_edit_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_range_edit_probe \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_ui_range_edit_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--range-edit" ) ]]; then
  echo "usage: $0 [--range-edit]" >&2
  exit 2
fi
if [[ $# -eq 0 ]]; then
  set -- --range-edit
fi
"$OUTPUT_DIR/composable_ui_range_edit_probe" "$@"
