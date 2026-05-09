#!/usr/bin/env zsh
#
# Owner: native bridge package-adjacent link probe。
# Truth: 只在 runtime/cjgui 语境旁路验证 production no-resource native bridge object 与仓颉 direct link 可行。
# Stop-line: 不修改 cjpm.toml，不接 runtime FFI，不新增 public API，不调用 resource callable，不创建 native 对象。
# Same-shape Boundary Brake: package-adjacent probe 只是 link-route evidence，不是 cjpm integration、runtime-call、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
REPO_DIR="$(cd "$PACKAGE_DIR/../.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-package-link-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_package_link_probe.a"
PROBE_SOURCE="$OUTPUT_DIR/package_link_probe.cj"
PROBE_EXECUTABLE="$OUTPUT_DIR/package_link_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread)$'

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge package link probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$CJPM_TOML" ]]; then
  echo "cjgui native bridge package link probe: missing $CJPM_TOML" >&2
  exit 3
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge package link probe: missing production native skeleton" >&2
  exit 4
fi

if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: cjpm.toml must stay unwired for this stage" >&2
  exit 5
fi

if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: cjpm.toml must not wire production native skeleton yet" >&2
  exit 6
fi

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal|QuartzCore/CAMetalLayer)\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: production skeleton must not import AppKit / Metal frameworks" >&2
  exit 7
fi

if grep -E 'cjgui_app_run|cjgui_last_error|NSWindow|NSView|CAMetalLayer|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release|destroy' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 8
fi

while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge package link probe: callable symbol is outside no-resource allowlist: $callable_name" >&2
    exit 9
  fi
done < <(grep -Eoh 'cjgui_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')

if ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi

if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: cjc not found" >&2
  exit 10
fi

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge package link probe: clang not found" >&2
  exit 11
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge package link probe: SDKROOT not found" >&2
  exit 12
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_PACKAGE_LINK_PROBE'
foreign func cjgui_native_bridge_surface_version(): UInt32
foreign func cjgui_native_bridge_surface_capabilities(): UInt32
foreign func cjgui_native_bridge_status_ok(): UInt32
foreign func cjgui_native_bridge_no_resource_admission(): UInt32
foreign func cjgui_native_bridge_is_main_thread(): Int32

main(): Int64 {
    println("cjgui native bridge package link probe: package_link_probe_requested=true")
    println("cjgui native bridge package link probe: runtime_package_config_modified=false")

    let surfaceVersion = unsafe {
        cjgui_native_bridge_surface_version()
    }
    let surfaceCapabilities = unsafe {
        cjgui_native_bridge_surface_capabilities()
    }
    let statusOk = unsafe {
        cjgui_native_bridge_status_ok()
    }
    let noResourceAdmission = unsafe {
        cjgui_native_bridge_no_resource_admission()
    }
    let mainThreadValue = unsafe {
        cjgui_native_bridge_is_main_thread()
    }

    let surfaceVersionObserved = surfaceVersion == UInt32(1)
    let capabilitiesObserved = surfaceCapabilities != UInt32(0)
    let statusObserved = statusOk == UInt32(0)
    let noResourceAdmissionObserved = noResourceAdmission == UInt32(0)
    let mainThreadQueryObserved =
        mainThreadValue == Int32(1) || mainThreadValue == Int32(0)
    let mainThreadObserved = mainThreadValue == Int32(1)
    let success = surfaceVersionObserved &&
        capabilitiesObserved &&
        statusObserved &&
        noResourceAdmissionObserved &&
        mainThreadQueryObserved &&
        mainThreadObserved

    println("cjgui native bridge package link probe: surface_version_observed=${surfaceVersionObserved}")
    println("cjgui native bridge package link probe: capabilities_observed=${capabilitiesObserved}")
    println("cjgui native bridge package link probe: status_ok_observed=${statusObserved}")
    println("cjgui native bridge package link probe: no_resource_admission_observed=${noResourceAdmissionObserved}")
    println("cjgui native bridge package link probe: main_thread_query_observed=${mainThreadQueryObserved}")
    println("cjgui native bridge package link probe: main_thread_observed=${mainThreadObserved}")

    if (success) {
        println("cjgui native bridge package link probe: no_resource_symbols_linked=true")
        println("cjgui native bridge package link probe: success=true reason=none")
        return 0
    }

    println("cjgui native bridge package link probe: no_resource_symbols_linked=false")
    println("cjgui native bridge package link probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_PACKAGE_LINK_PROBE

echo "cjgui native bridge package link probe: repo=$REPO_DIR"
echo "cjgui native bridge package link probe: package=$PACKAGE_DIR"
echo "cjgui native bridge package link probe: output=$OUTPUT_DIR"
echo "cjgui native bridge package link probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge package link probe: compiling production no-resource skeleton"

"$CLANG_BIN" \
  -fobjc-arc \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"

echo "cjgui native bridge package link probe: native_object_built=true"

ar rcs "$STATIC_LIB" "$OBJECT_FILE"

echo "cjgui native bridge package link probe: compiling package-adjacent Cangjie foreign caller"

cjc "$PROBE_SOURCE" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$OUTPUT_DIR" \
  -lcjgui_native_bridge_package_link_probe \
  -o "$PROBE_EXECUTABLE"

if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi

"$PROBE_EXECUTABLE"
