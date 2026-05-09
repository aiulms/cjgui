#!/usr/bin/env zsh
#
# Owner: native bridge isolated no-resource C ABI FFI probe。
# Truth: 只验证仓颉 foreign 声明、direct cjc link 与 no-resource callable 的 deterministic result。
# Stop-line: 不修改 runtime/cjgui/cjpm.toml，不接 runtime FFI，不调用 resource callable，不创建 native object。
# Same-shape Boundary Brake: probe success 只是 FFI syntax/link evidence，不是 runtime bridge、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROBE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$PROBE_DIR/../.." && pwd)"
source "$SCRIPT_DIR/env.sh"

NATIVE_HEADER="$REPO_DIR/runtime/cjgui/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$REPO_DIR/runtime/cjgui/native/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-ffi-probe-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_probe.a"
EXECUTABLE="$OUTPUT_DIR/native_bridge_ffi_probe"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread)$'

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge ffi probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$NATIVE_HEADER" || ! -f "$NATIVE_SOURCE" ]]; then
  echo "cjgui native bridge ffi probe: missing production native skeleton" >&2
  exit 3
fi

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal|QuartzCore/CAMetalLayer)\.h>' "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui native bridge ffi probe: production skeleton must not import AppKit / Metal frameworks" >&2
  exit 4
fi

if grep -E 'cjgui_app_run|cjgui_last_error|NSWindow|NSView|CAMetalLayer|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release|destroy' "$NATIVE_HEADER" "$NATIVE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui native bridge ffi probe: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 5
fi

while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge ffi probe: callable symbol is outside no-resource allowlist: $callable_name" >&2
    exit 6
  fi
done < <(grep -Eoh 'cjgui_[A-Za-z0-9_]+[[:space:]]*\(' "$NATIVE_HEADER" "$NATIVE_SOURCE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge ffi probe: clang not found" >&2
  exit 7
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge ffi probe: SDKROOT not found" >&2
  exit 8
fi

echo "cjgui native bridge ffi probe: output=$OUTPUT_DIR"
echo "cjgui native bridge ffi probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge ffi probe: compiling production skeleton object"

"$CLANG_BIN" \
  -fobjc-arc \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$NATIVE_SOURCE" \
  -o "$OBJECT_FILE"

ar rcs "$STATIC_LIB" "$OBJECT_FILE"

if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge ffi probe: cjc not found" >&2
  exit 9
fi

echo "cjgui native bridge ffi probe: compiling Cangjie foreign caller"

cjc "$PROBE_DIR/src/main.cj" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$OUTPUT_DIR" \
  -lcjgui_native_bridge_probe \
  -o "$EXECUTABLE"

"$EXECUTABLE"
