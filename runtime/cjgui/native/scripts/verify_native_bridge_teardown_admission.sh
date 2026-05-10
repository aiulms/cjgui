#!/usr/bin/env zsh
#
# Owner: native bridge no-resource teardown admission probe。
# Truth: 验证 production native bridge 的 teardown admission / not-supported / revoke-before-destroy-required / double-destroy classification callable。
# Stop-line: 不修改源码或 build config，不执行真实 native 生命周期，不调用 resource callable，不创建 native 对象。
# Same-shape Boundary Brake: teardown admission probe 只是 fail-closed classification evidence，不是 destroy、resource、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-teardown-admission-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_teardown_admission_probe.a"
PROBE_SOURCE="$OUTPUT_DIR/teardown_admission_probe.cj"
PROBE_EXECUTABLE="$OUTPUT_DIR/teardown_admission_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked)$'

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge teardown admission probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge teardown admission probe: missing production native bridge" >&2
  exit 3
fi

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal)\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge teardown admission probe: production bridge must not import Cocoa / Metal frameworks" >&2
  exit 4
fi

if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]+(alloc|new)\]|(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]*\*|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present|retain|release|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge teardown admission probe: forbidden resource/native behavior token found" >&2
  exit 5
fi

while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge teardown admission probe: callable outside allowlist: $callable_name" >&2
    exit 6
  fi
done < <(grep -Eoh 'cjgui_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')

if ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi

if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge teardown admission probe: cjc not found" >&2
  exit 7
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
  echo "cjgui native bridge teardown admission probe: clang not found" >&2
  exit 8
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge teardown admission probe: SDKROOT not found" >&2
  exit 9
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_TEARDOWN_ADMISSION_PROBE'
foreign func cjgui_native_bridge_token_invalid(): UInt64
foreign func cjgui_native_bridge_token_issue(): UInt64
foreign func cjgui_native_bridge_token_revoke(token: UInt64): Int32
foreign func cjgui_native_bridge_teardown_admission(token: UInt64): Int32
foreign func cjgui_native_bridge_destroy_not_supported(): Int32
foreign func cjgui_native_bridge_revoke_before_destroy_required(): Int32
foreign func cjgui_native_bridge_double_destroy_classify(token: UInt64): Int32

main(): Int64 {
    println("cjgui native bridge teardown admission probe: requested=true")

    let invalidToken = unsafe {
        cjgui_native_bridge_token_invalid()
    }
    let invalidAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(invalidToken)
    }
    let destroyNotSupported = unsafe {
        cjgui_native_bridge_destroy_not_supported()
    }
    let revokeBeforeDestroyRequired = unsafe {
        cjgui_native_bridge_revoke_before_destroy_required()
    }
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let validAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
    }
    let revokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_double_destroy_classify(issuedToken)
    }
    let danglingAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
    }

    let destroyNotSupportedObserved = destroyNotSupported == Int32(-10)
    let revokeBeforeDestroyObserved =
        revokeBeforeDestroyRequired == Int32(-11)
    let invalidAdmissionObserved = invalidAdmission == Int32(-13)
    let validAdmissionObserved =
        issuedToken != UInt64(0) && validAdmission == Int32(-11)
    let revokeObserved = revokeStatus == Int32(0)
    let doubleDestroyObserved = doubleDestroyClass == Int32(-12)
    let danglingAdmissionObserved = danglingAdmission == Int32(-13)
    let success = destroyNotSupportedObserved &&
        revokeBeforeDestroyObserved &&
        invalidAdmissionObserved &&
        validAdmissionObserved &&
        revokeObserved &&
        doubleDestroyObserved &&
        danglingAdmissionObserved

    println("cjgui native bridge teardown admission probe: destroy_not_supported_observed=${destroyNotSupportedObserved}")
    println("cjgui native bridge teardown admission probe: revoke_before_destroy_required_observed=${revokeBeforeDestroyObserved}")
    println("cjgui native bridge teardown admission probe: invalid_token_fail_closed_observed=${invalidAdmissionObserved}")
    println("cjgui native bridge teardown admission probe: valid_token_admission_observed=${validAdmissionObserved}")
    println("cjgui native bridge teardown admission probe: revoke_observed=${revokeObserved}")
    println("cjgui native bridge teardown admission probe: double_destroy_denial_observed=${doubleDestroyObserved}")
    println("cjgui native bridge teardown admission probe: dangling_token_denial_observed=${danglingAdmissionObserved}")
    println("cjgui native bridge teardown admission probe: actual_destroy_invoked=false")
    println("cjgui native bridge teardown admission probe: retain_release_invoked=false")
    println("cjgui native bridge teardown admission probe: public_api_modified=false")
    println("cjgui native bridge teardown admission probe: native_object_created=false")

    if (success) {
        println("cjgui native bridge teardown admission probe: success=true reason=none")
        return 0
    }

    println("cjgui native bridge teardown admission probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_TEARDOWN_ADMISSION_PROBE

echo "cjgui native bridge teardown admission probe: output=$OUTPUT_DIR"
echo "cjgui native bridge teardown admission probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge teardown admission probe: compiling production no-resource bridge"

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
  -lcjgui_native_bridge_teardown_admission_probe \
  --link-options "-framework AppKit -framework QuartzCore -lobjc" \
  -o "$PROBE_EXECUTABLE"

if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi

"$PROBE_EXECUTABLE"
