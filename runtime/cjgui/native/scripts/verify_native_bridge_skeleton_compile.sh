#!/usr/bin/env zsh
#
# Owner: production native bridge skeleton 隔离编译 probe。
# Truth: 只验证 cjgui_native_bridge.m 在本机 Objective-C 工具链下可独立编译到临时对象文件。
# Stop-line: 不修改源码或 build config，不接入 cjpm，不链接 framework，不执行 app，不调用 C ABI / FFI。
# Same-shape Boundary Brake: probe 只是 build feasibility evidence，不是 bridge-ready、C-ABI-ready、FFI-ready、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-build-probe-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread)$'

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge probe: macOS is required for Objective-C skeleton compile" >&2
  exit 2
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge probe: missing source $SOURCE_FILE" >&2
  exit 3
fi

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal|QuartzCore/CAMetalLayer)\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge probe: production skeleton must not import AppKit / Metal frameworks" >&2
  exit 6
fi

if grep -E 'cjgui_app_run|cjgui_last_error|NSWindow|NSView|CAMetalLayer|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release|destroy' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge probe: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 7
fi

while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge probe: callable symbol is outside no-resource allowlist: $callable_name" >&2
    exit 8
  fi
done < <(grep -Eoh 'cjgui_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
  SDKROOT_VALUE="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"
else
  CLANG_BIN=""
  SDKROOT_VALUE="${SDKROOT:-}"
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge probe: clang not found" >&2
  exit 4
fi

if [[ -z "${SDKROOT_VALUE:-}" || ! -d "$SDKROOT_VALUE" ]]; then
  echo "cjgui native bridge probe: SDKROOT not found; set SDKROOT or install macOS SDK" >&2
  exit 5
fi

echo "cjgui native bridge probe: source=$SOURCE_FILE"
echo "cjgui native bridge probe: output=$OBJECT_FILE"
echo "cjgui native bridge probe: sdkroot=$SDKROOT_VALUE"

"$CLANG_BIN" \
  -fobjc-arc \
  -fmodules \
  -isysroot "$SDKROOT_VALUE" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"

if command -v nm >/dev/null 2>&1; then
  while IFS= read -r symbol_name; do
    if [[ "$symbol_name" == _cjgui_* || "$symbol_name" == cjgui_* ]]; then
      if [[ ! "$symbol_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
        echo "cjgui native bridge probe: object exports forbidden callable symbol: $symbol_name" >&2
        exit 9
      fi
    fi
  done < <(nm -g "$OBJECT_FILE" | awk '{print $NF}')
fi

echo "cjgui native bridge probe: skeleton compile passed"
echo "cjgui native bridge probe: no cjpm integration, no FFI, no resource/native-object callable C ABI"
