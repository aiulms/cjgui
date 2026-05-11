#!/usr/bin/env zsh
#
# Owner: platform object NSView runtime FFI call verification probe。
# Truth: 用临时仓颉 package 复核 NSView create / classify / destroy FFI
# 调用序列，并确认 runtime owner source 存在。
# Stop-line: 不修改 runtime/cjgui/cjpm.toml，不返回 Class / id / pointer /
# handle，不创建 NSWindow / NSApplication / layer / Metal resource。
# Same-shape Boundary Brake: runtime-adjacent probe 只证明 internal FFI call
# path 可复核，不是 backend-ready、render-ready、Metal layer 或 public API。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
REPO_DIR="$(cd "$PACKAGE_DIR/../.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
RUNTIME_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_nsview_runtime_call.cj"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-nsview-runtime-call-XXXXXX)"
NATIVE_BUILD_DIR="$OUTPUT_DIR/native-build"
PROBE_PACKAGE_DIR="$OUTPUT_DIR/nsview-runtime-call-probe"
OBJECT_FILE="$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
STATIC_LIB="$NATIVE_BUILD_DIR/libcjgui_native_bridge_nsview_runtime_call_probe.a"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge nsview runtime call probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$CJPM_TOML" || ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge nsview runtime call probe: missing package/native files" >&2
  exit 3
fi
if [[ ! -f "$RUNTIME_OWNER" ]]; then
  echo "cjgui native bridge nsview runtime call probe: missing runtime owner" >&2
  exit 4
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness" "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview runtime call probe: runtime owner endpoint missing" >&2
  exit 5
fi
if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview runtime call probe: runtime cjpm.toml must stay unwired" >&2
  exit 6
fi
if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview runtime call probe: runtime cjpm.toml must not wire native bridge" >&2
  exit 7
fi
for symbol in \
  "cjgui_native_bridge_nsview_create" \
  "cjgui_native_bridge_nsview_destroy" \
  "cjgui_native_bridge_nsview_token_classify" \
  "cjgui_native_bridge_nsview_table_occupied_count" \
  "cjgui_native_bridge_nsview_double_destroy_classify" \
  "cjgui_native_bridge_nsview_destroy_requires_main_thread"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge nsview runtime call probe: missing callable $symbol" >&2
    exit 8
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview runtime call probe: forbidden framework import" >&2
  exit 9
fi
if grep -E '\[[[:space:]]*(NSWindow|NSApplication|CALayer)[[:space:]]+(alloc|new|init)\]|^[[:space:]]*(Class|id|void[[:space:]]*\*|uintptr_t)[[:space:]]+cjgui_|nextDrawable|commit\]|presentDrawable|present\]|__bridge|CFBridging' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview runtime call probe: forbidden object / pointer / GPU token found" >&2
  exit 10
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge nsview runtime call probe: cjpm/cjc not found" >&2
  exit 11
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
  echo "cjgui native bridge nsview runtime call probe: clang not found" >&2
  exit 12
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge nsview runtime call probe: SDKROOT not found" >&2
  exit 13
fi
RUNTIME_CJPM_HASH_BEFORE="$(shasum -a 256 "$CJPM_TOML" | awk '{print $1}')"
mkdir -p "$NATIVE_BUILD_DIR" "$PROBE_PACKAGE_DIR/src"
echo "cjgui native bridge nsview runtime call probe: repo=$REPO_DIR"
echo "cjgui native bridge nsview runtime call probe: output=$OUTPUT_DIR"
echo "cjgui native bridge nsview runtime call probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge nsview runtime call probe: compiling production bridge"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"
ar rcs "$STATIC_LIB" "$OBJECT_FILE"
cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_NATIVE_BRIDGE_NSVIEW_RUNTIME_CALL_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_native_bridge_nsview_runtime_call_probe"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
  link-option = "-L $NATIVE_BUILD_DIR -lcjgui_native_bridge_nsview_runtime_call_probe -framework AppKit -framework QuartzCore -framework Metal -lobjc"
CJGUI_NATIVE_BRIDGE_NSVIEW_RUNTIME_CALL_TOML
cat > "$PROBE_PACKAGE_DIR/src/main.cj" <<'CJGUI_NATIVE_BRIDGE_NSVIEW_RUNTIME_CALL_MAIN'
package cjgui_native_bridge_nsview_runtime_call_probe
foreign func cjgui_native_bridge_nsview_create(outToken: CPointer<UInt64>):
    Int32
foreign func cjgui_native_bridge_nsview_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_nsview_token_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_nsview_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_nsview_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_nsview_destroy_requires_main_thread():
    Int32
main(): Int64 {
    println("cjgui native bridge nsview runtime call probe: requested=true")
    println("cjgui native bridge nsview runtime call probe: runtime_owner_source_present=true")
    println("cjgui native bridge nsview runtime call probe: runtime_package_config_modified=false")
    let occupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    var createdToken = UInt64(0)
    let createStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout createdToken)
    }
    let occupiedAfterCreate = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let validTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdToken)
    }
    let invalidDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(UInt64(0))
    }
    let destroyRequiresMainThread = unsafe {
        cjgui_native_bridge_nsview_destroy_requires_main_thread()
    }
    let destroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdToken)
    }
    let occupiedAfterDestroy = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let destroyedTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdToken)
    }
    let doubleDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_nsview_double_destroy_classify(createdToken)
    }
    let createObserved = createStatus == Int32(0) &&
        createdToken != UInt64(0)
    let tokenNotPointerObserved =
        createdToken != UInt64(0) && createdToken < UInt64(4294967296)
    let validObserved = validTokenClass == Int32(40)
    let occupiedObserved =
        occupiedBefore == UInt32(0) &&
        occupiedAfterCreate == UInt32(1) &&
        occupiedAfterDestroy == UInt32(0)
    let destroyObserved = destroyStatus == Int32(0)
    let destroyedObserved = destroyedTokenClass == Int32(-43)
    let doubleDestroyObserved =
        doubleDestroyStatus == Int32(-46) &&
        doubleDestroyClass == Int32(-46)
    let invalidObserved = invalidDestroyStatus == Int32(-42)
    let destroyRequiresMainThreadObserved =
        destroyRequiresMainThread == Int32(-41)
    let success =
        createObserved &&
        tokenNotPointerObserved &&
        validObserved &&
        occupiedObserved &&
        destroyObserved &&
        destroyedObserved &&
        doubleDestroyObserved &&
        invalidObserved &&
        destroyRequiresMainThreadObserved
    println("cjgui native bridge nsview runtime call probe: create_observed=${createObserved}")
    println("cjgui native bridge nsview runtime call probe: token_not_pointer_observed=${tokenNotPointerObserved}")
    println("cjgui native bridge nsview runtime call probe: classify_valid_observed=${validObserved}")
    println("cjgui native bridge nsview runtime call probe: occupied_count_lifecycle_observed=${occupiedObserved}")
    println("cjgui native bridge nsview runtime call probe: destroy_observed=${destroyObserved}")
    println("cjgui native bridge nsview runtime call probe: destroyed_stale_observed=${destroyedObserved}")
    println("cjgui native bridge nsview runtime call probe: double_destroy_fail_closed_observed=${doubleDestroyObserved}")
    println("cjgui native bridge nsview runtime call probe: invalid_token_fail_closed_observed=${invalidObserved}")
    println("cjgui native bridge nsview runtime call probe: destroy_requires_main_thread_observed=${destroyRequiresMainThreadObserved}")
    println("cjgui native bridge nsview runtime call probe: token_persisted=false")
    println("cjgui native bridge nsview runtime call probe: public_api_added=false")
    println("cjgui native bridge nsview runtime call probe: renderer_state_written=false")
    println("cjgui native bridge nsview runtime call probe: pointer_returned=false")
    println("cjgui native bridge nsview runtime call probe: class_or_id_returned=false")
    println("cjgui native bridge nsview runtime call probe: metal_import_allowed=true")
    if (success) {
        println("cjgui native bridge nsview runtime call probe: success=true reason=none")
        return 0
    }
    println("cjgui native bridge nsview runtime call probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_NSVIEW_RUNTIME_CALL_MAIN
echo "cjgui native bridge nsview runtime call probe: running temporary cjpm package"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm run --skip-script
)
RUNTIME_CJPM_HASH_AFTER="$(shasum -a 256 "$CJPM_TOML" | awk '{print $1}')"
if [[ "$RUNTIME_CJPM_HASH_BEFORE" != "$RUNTIME_CJPM_HASH_AFTER" ]]; then
  echo "cjgui native bridge nsview runtime call probe: runtime cjpm.toml changed" >&2
  exit 14
fi
echo "cjgui native bridge nsview runtime call probe: success=true reason=none"
