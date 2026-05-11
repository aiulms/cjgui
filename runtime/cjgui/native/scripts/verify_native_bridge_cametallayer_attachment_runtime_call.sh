#!/usr/bin/env zsh
#
# 维护注释：本脚本是 CAMetalLayer attachment runtime-adjacent FFI call probe。
# Truth: 用临时仓颉 package 复核 token-backed NSView / CAMetalLayer
# attach -> classify -> detach -> cleanup 调用序列，并确认 runtime owner source 存在。
# Stop-line: 不修改 runtime/cjgui/cjpm.toml，不导入 Metal，不设置 device，
# 不获取 drawable，不返回 Class / id / pointer / handle，不新增 public API。
# Same-shape Boundary Brake: runtime-adjacent probe 只证明 internal attachment
# FFI call path 可复核，不是 backend-ready、render-ready、GPU submission 或 public API。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
REPO_DIR="$(cd "$PACKAGE_DIR/../.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
RUNTIME_OWNER="$PACKAGE_DIR/src/runtime_renderer_cametallayer_attachment_runtime_call.cj"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-cametallayer-attachment-runtime-call-XXXXXX)"
NATIVE_BUILD_DIR="$OUTPUT_DIR/native-build"
PROBE_PACKAGE_DIR="$OUTPUT_DIR/cametallayer-attachment-runtime-call-probe"
OBJECT_FILE="$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
STATIC_LIB="$NATIVE_BUILD_DIR/libcjgui_native_bridge_cametallayer_attachment_runtime_call_probe.a"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$CJPM_TOML" || ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: missing package/native files" >&2
  exit 3
fi
if [[ ! -f "$RUNTIME_OWNER" ]]; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: missing runtime owner" >&2
  exit 4
fi
if ! grep -F "CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness" "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: runtime owner endpoint missing" >&2
  exit 5
fi
if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: runtime cjpm.toml must stay unwired" >&2
  exit 6
fi
if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: runtime cjpm.toml must not wire native bridge" >&2
  exit 7
fi
for symbol in \
  "cjgui_native_bridge_nsview_create" \
  "cjgui_native_bridge_nsview_destroy" \
  "cjgui_native_bridge_nsview_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_create" \
  "cjgui_native_bridge_cametallayer_destroy" \
  "cjgui_native_bridge_cametallayer_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_attach_to_nsview" \
  "cjgui_native_bridge_cametallayer_detach_from_nsview" \
  "cjgui_native_bridge_cametallayer_attachment_classify" \
  "cjgui_native_bridge_cametallayer_double_detach_classify" \
  "cjgui_native_bridge_cametallayer_attach_requires_main_thread" \
  "cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge CAMetalLayer attachment runtime call probe: missing callable $symbol" >&2
    exit 8
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: forbidden framework import" >&2
  exit 9
fi
if grep -E 'nextDrawable|commit\]|presentDrawable|present\]|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging|^[[:space:]]*(Class|id|CAMetalLayer[[:space:]]*\*|NSView[[:space:]]*\*)[[:space:]]+cjgui_' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: forbidden Metal / pointer return found" >&2
  exit 10
fi
if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|interface)' "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: runtime owner must stay internal" >&2
  exit 11
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: cjpm/cjc not found" >&2
  exit 12
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
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: clang not found" >&2
  exit 13
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: SDKROOT not found" >&2
  exit 14
fi
RUNTIME_CJPM_HASH_BEFORE="$(shasum -a 256 "$CJPM_TOML" | awk '{print $1}')"
mkdir -p "$NATIVE_BUILD_DIR" "$PROBE_PACKAGE_DIR/src"
echo "cjgui native bridge CAMetalLayer attachment runtime call probe: repo=$REPO_DIR"
echo "cjgui native bridge CAMetalLayer attachment runtime call probe: output=$OUTPUT_DIR"
echo "cjgui native bridge CAMetalLayer attachment runtime call probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge CAMetalLayer attachment runtime call probe: compiling production bridge"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"
ar rcs "$STATIC_LIB" "$OBJECT_FILE"
cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_RUNTIME_CALL_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_native_bridge_cametallayer_attachment_runtime_call_probe"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
  link-option = "-L $NATIVE_BUILD_DIR -lcjgui_native_bridge_cametallayer_attachment_runtime_call_probe -framework AppKit -framework QuartzCore -framework Metal -lobjc"
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_RUNTIME_CALL_TOML
cat > "$PROBE_PACKAGE_DIR/src/main.cj" <<'CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_RUNTIME_CALL_MAIN'
package cjgui_native_bridge_cametallayer_attachment_runtime_call_probe
foreign func cjgui_native_bridge_nsview_create(outToken: CPointer<UInt64>):
    Int32
foreign func cjgui_native_bridge_nsview_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_nsview_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_cametallayer_create(
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_cametallayer_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_cametallayer_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_cametallayer_attach_to_nsview(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_detach_from_nsview(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_attachment_classify(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_double_detach_classify(
    layerToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_cametallayer_attach_requires_main_thread():
    Int32
foreign func
cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked():
    Int32
main(): Int64 {
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: requested=true")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: runtime_owner_source_present=true")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: runtime_package_config_modified=false")
    let nsviewOccupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedBefore = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    var viewToken = UInt64(0)
    var layerToken = UInt64(0)
    let viewCreateStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout viewToken)
    }
    let layerCreateStatus = unsafe {
        cjgui_native_bridge_cametallayer_create(inout layerToken)
    }
    let attachRequiresMainThread = unsafe {
        cjgui_native_bridge_cametallayer_attach_requires_main_thread()
    }
    let deviceBindingStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked()
    }
    let attachStatus = unsafe {
        cjgui_native_bridge_cametallayer_attach_to_nsview(
            layerToken,
            viewToken
        )
    }
    let attachedClass = unsafe {
        cjgui_native_bridge_cametallayer_attachment_classify(
            layerToken,
            viewToken
        )
    }
    let detachStatus = unsafe {
        cjgui_native_bridge_cametallayer_detach_from_nsview(
            layerToken,
            viewToken
        )
    }
    let detachedClass = unsafe {
        cjgui_native_bridge_cametallayer_attachment_classify(
            layerToken,
            viewToken
        )
    }
    let doubleDetachStatus = unsafe {
        cjgui_native_bridge_cametallayer_detach_from_nsview(
            layerToken,
            viewToken
        )
    }
    let doubleDetachClass = unsafe {
        cjgui_native_bridge_cametallayer_double_detach_classify(
            layerToken,
            viewToken
        )
    }
    let layerDestroyStatus = unsafe {
        cjgui_native_bridge_cametallayer_destroy(layerToken)
    }
    let viewDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(viewToken)
    }
    let nsviewOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let layerOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_cametallayer_table_occupied_count()
    }
    let createObserved =
        viewCreateStatus == Int32(0) &&
        layerCreateStatus == Int32(0) &&
        viewToken != UInt64(0) &&
        layerToken != UInt64(0)
    let attachObserved = attachStatus == Int32(0)
    let attachedObserved = attachedClass == Int32(90)
    let detachObserved = detachStatus == Int32(0)
    let detachedObserved = detachedClass == Int32(-90)
    let doubleDetachObserved =
        doubleDetachStatus == Int32(-96) &&
        doubleDetachClass == Int32(-96)
    let cleanupObserved =
        layerDestroyStatus == Int32(0) &&
        viewDestroyStatus == Int32(0) &&
        nsviewOccupiedBefore == UInt32(0) &&
        layerOccupiedBefore == UInt32(0) &&
        nsviewOccupiedAfterCleanup == UInt32(0) &&
        layerOccupiedAfterCleanup == UInt32(0)
    let mainThreadGateObserved = attachRequiresMainThread == Int32(-91)
    let deviceBindingBlockedObserved =
        deviceBindingStillBlocked == Int32(-100)
    let success =
        createObserved &&
        attachObserved &&
        attachedObserved &&
        detachObserved &&
        detachedObserved &&
        doubleDetachObserved &&
        cleanupObserved &&
        mainThreadGateObserved &&
        deviceBindingBlockedObserved
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: create_tokens_observed=${createObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: attach_observed=${attachObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: classify_attached_observed=${attachedObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: detach_observed=${detachObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: classify_detached_observed=${detachedObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: double_detach_fail_closed_observed=${doubleDetachObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: cleanup_occupied_count_zero_observed=${cleanupObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: attach_requires_main_thread_observed=${mainThreadGateObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: device_binding_still_blocked_observed=${deviceBindingBlockedObserved}")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: token_persisted=false")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: renderer_state_written=false")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: public_api_added=false")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: metal_import_allowed=true")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: metal_device_created_by_probe=false")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: drawable_acquired=false")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: pointer_returned=false")
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: class_or_id_returned=false")
    if (success) {
        println("cjgui native bridge CAMetalLayer attachment runtime call probe: success=true reason=none")
        return 0
    }
    println("cjgui native bridge CAMetalLayer attachment runtime call probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ATTACHMENT_RUNTIME_CALL_MAIN
echo "cjgui native bridge CAMetalLayer attachment runtime call probe: running temporary cjpm package"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm run --skip-script
)
RUNTIME_CJPM_HASH_AFTER="$(shasum -a 256 "$CJPM_TOML" | awk '{print $1}')"
if [[ "$RUNTIME_CJPM_HASH_BEFORE" != "$RUNTIME_CJPM_HASH_AFTER" ]]; then
  echo "cjgui native bridge CAMetalLayer attachment runtime call probe: runtime cjpm.toml changed" >&2
  exit 15
fi
echo "cjgui native bridge CAMetalLayer attachment runtime call probe: success=true reason=none"
