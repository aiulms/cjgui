#!/usr/bin/env zsh
#
# Owner: platform object NSView object table shell probe。
# Truth: 验证 production native bridge 暴露固定容量、empty、fail-closed
# NSView table shell integer facts。
# Stop-line: 不修改源码或 build config；本 probe 不触发 NSView create/destroy；
# 不返回 Class / id / pointer / handle，不导入 Metal。
# Same-shape Boundary Brake: object table shell probe 只是 no-allocation table
# facts，不是 NSView retention、platform object creation、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-nsview-object-table-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_nsview_object_table_probe.a"
PROBE_SOURCE="$OUTPUT_DIR/nsview_object_table_probe.cj"
PROBE_EXECUTABLE="$OUTPUT_DIR/nsview_object_table_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked)$'

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge nsview object table probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge nsview object table probe: missing production native bridge" >&2
  exit 3
fi

for symbol in \
  "cjgui_native_bridge_nsview_table_capacity" \
  "cjgui_native_bridge_nsview_table_enabled" \
  "cjgui_native_bridge_nsview_table_empty" \
  "cjgui_native_bridge_nsview_table_token_classify" \
  "cjgui_native_bridge_nsview_table_allocation_still_blocked" \
  "cjgui_native_bridge_nsview_table_destroy_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge nsview object table probe: missing callable $symbol" >&2
    exit 4
  fi
done

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal)\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview object table probe: production bridge must not import Cocoa / Metal" >&2
  exit 5
fi

if grep -E '\[[[:space:]]*(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]+(alloc|new|init)\]|^[[:space:]]*static[[:space:]]+(NSWindow|NSApplication|CALayer|CAMetalLayer|Class|id)[[:space:]]|^[[:space:]]*(Class|id|void[[:space:]]*\*|uintptr_t)[[:space:]]+cjgui_|(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]*\*|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release|__bridge|CFBridging' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview object table probe: forbidden allocation / storage / pointer token found" >&2
  exit 6
fi

while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge nsview object table probe: callable outside allowlist: $callable_name" >&2
    exit 7
  fi
done < <(grep -Eoh 'cjgui_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')

if ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi

if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge nsview object table probe: cjc not found" >&2
  exit 8
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
  echo "cjgui native bridge nsview object table probe: clang not found" >&2
  exit 9
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge nsview object table probe: SDKROOT not found" >&2
  exit 10
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_NSVIEW_OBJECT_TABLE_PROBE'
foreign func cjgui_native_bridge_token_issue(): UInt64
foreign func cjgui_native_bridge_token_revoke(token: UInt64): Int32
foreign func cjgui_native_bridge_nsview_table_capacity(): UInt32
foreign func cjgui_native_bridge_nsview_table_enabled(): UInt32
foreign func cjgui_native_bridge_nsview_table_empty(): Int32
foreign func cjgui_native_bridge_nsview_table_token_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_nsview_table_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_nsview_table_destroy_still_blocked():
    Int32

main(): Int64 {
    println("cjgui native bridge nsview object table probe: requested=true")

    let capacity = unsafe {
        cjgui_native_bridge_nsview_table_capacity()
    }
    let enabled = unsafe {
        cjgui_native_bridge_nsview_table_enabled()
    }
    let empty = unsafe {
        cjgui_native_bridge_nsview_table_empty()
    }
    let invalidTokenClass = unsafe {
        cjgui_native_bridge_nsview_table_token_classify(UInt64(0))
    }
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let issuedTokenClass = unsafe {
        cjgui_native_bridge_nsview_table_token_classify(issuedToken)
    }
    let allocationBlocked = unsafe {
        cjgui_native_bridge_nsview_table_allocation_still_blocked()
    }
    let destroyBlocked = unsafe {
        cjgui_native_bridge_nsview_table_destroy_still_blocked()
    }
    let revokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    let revokedTokenClass = unsafe {
        cjgui_native_bridge_nsview_table_token_classify(issuedToken)
    }

    let capacityObserved = capacity == UInt32(4)
    let enabledObserved = enabled == UInt32(1)
    let emptyObserved = empty == Int32(30)
    let invalidTokenObserved = invalidTokenClass == Int32(0)
    let tokenNotBoundObserved =
        issuedToken != UInt64(0) && issuedTokenClass == Int32(-30)
    let allocationBlockedObserved = allocationBlocked == Int32(-31)
    let destroyBlockedObserved = destroyBlocked == Int32(-32)
    let revokeObserved =
        revokeStatus == Int32(0) && revokedTokenClass == Int32(-2)
    let success = capacityObserved &&
        enabledObserved &&
        emptyObserved &&
        invalidTokenObserved &&
        tokenNotBoundObserved &&
        allocationBlockedObserved &&
        destroyBlockedObserved &&
        revokeObserved

    println("cjgui native bridge nsview object table probe: table_capacity_observed=${capacityObserved}")
    println("cjgui native bridge nsview object table probe: table_enabled_observed=${enabledObserved}")
    println("cjgui native bridge nsview object table probe: table_empty_observed=${emptyObserved}")
    println("cjgui native bridge nsview object table probe: invalid_token_fail_closed_observed=${invalidTokenObserved}")
    println("cjgui native bridge nsview object table probe: token_not_bound_observed=${tokenNotBoundObserved}")
    println("cjgui native bridge nsview object table probe: allocation_blocked_observed=${allocationBlockedObserved}")
    println("cjgui native bridge nsview object table probe: destroy_blocked_observed=${destroyBlockedObserved}")
    println("cjgui native bridge nsview object table probe: revoke_observed=${revokeObserved}")
    println("cjgui native bridge nsview object table probe: nsview_allocated_by_probe=false")
    println("cjgui native bridge nsview object table probe: nsview_saved_by_probe=false")
    println("cjgui native bridge nsview object table probe: pointer_returned=false")
    println("cjgui native bridge nsview object table probe: native_handle_returned=false")
    println("cjgui native bridge nsview object table probe: metal_imported=false")

    if (success) {
        println("cjgui native bridge nsview object table probe: success=true reason=none")
        return 0
    }

    println("cjgui native bridge nsview object table probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_NSVIEW_OBJECT_TABLE_PROBE

echo "cjgui native bridge nsview object table probe: output=$OUTPUT_DIR"
echo "cjgui native bridge nsview object table probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge nsview object table probe: compiling production bridge"

"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"

ar rcs "$STATIC_LIB" "$OBJECT_FILE"

cjc "$PROBE_SOURCE" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$OUTPUT_DIR" \
  -lcjgui_native_bridge_nsview_object_table_probe \
  --link-options "-framework AppKit -framework QuartzCore -lobjc" \
  -o "$PROBE_EXECUTABLE"

if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi

"$PROBE_EXECUTABLE"
