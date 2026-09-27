#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$RUNTIME_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUT_DIR="${CJGUI_WINDOW_MATERIAL_OUT_DIR:-$(mktemp -d /private/tmp/cjgui-window-material-native.XXXXXX)}"
mkdir -p "$OUT_DIR"

PROBE_SOURCE="$RUNTIME_DIR/probe/composable_window_material_probe.m"
RENDERER_SOURCE="$RUNTIME_DIR/native/cjgui_internal_renderer.m"
BINARY="$OUT_DIR/composable_window_material_probe"
BUILD_LOG="$OUT_DIR/build.log"
RUN_LOG="$OUT_DIR/run.log"

clang -fobjc-arc -fmodules -fno-objc-msgsend-selector-stubs \
  -mmacosx-version-min=12.0 -isysroot "$SDKROOT_PATH" -DCJGUI_INTERNAL_TESTING \
  "$RENDERER_SOURCE" "$PROBE_SOURCE" \
  -framework AppKit -framework Metal -framework QuartzCore -framework CoreText \
  -Wl,-undefined,dynamic_lookup -o "$BINARY" >"$BUILD_LOG" 2>&1

CJGUI_WINDOW_MATERIAL_OUT_DIR="$OUT_DIR" "$BINARY" >"$RUN_LOG" 2>&1
cat "$RUN_LOG"
printf 'window_material_probe_build_log=%s\nwindow_material_probe_run_log=%s\n' "$BUILD_LOG" "$RUN_LOG"
