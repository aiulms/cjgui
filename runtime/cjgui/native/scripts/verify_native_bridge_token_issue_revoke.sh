#!/usr/bin/env zsh
#
# Owner: native token table no-resource issue/revoke probe。
# Truth: 验证 production native bridge 的 fixed-capacity opaque token issue / revoke / classify sequence。
# Stop-line: 不修改源码或 build config，不接 public API，不调用 resource callable，不创建 native 对象。
# Same-shape Boundary Brake: issue/revoke probe 只是 no-resource token mechanics evidence，不是 resource table、backend-ready 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-token-issue-revoke-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_token_issue_revoke_probe.a"
PROBE_SOURCE="$OUTPUT_DIR/token_issue_revoke_probe.cj"
PROBE_EXECUTABLE="$OUTPUT_DIR/token_issue_revoke_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked|cjgui_native_bridge_cametallayer_allocation_feasible|cjgui_native_bridge_cametallayer_allocation_requires_main_thread|cjgui_native_bridge_cametallayer_allocation_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_device_binding_blocked|cjgui_native_bridge_cametallayer_allocation_feasibility_probe|cjgui_native_bridge_cametallayer_table_capacity|cjgui_native_bridge_cametallayer_table_enabled|cjgui_native_bridge_cametallayer_table_empty|cjgui_native_bridge_cametallayer_table_token_classify|cjgui_native_bridge_cametallayer_table_allocation_still_blocked|cjgui_native_bridge_cametallayer_table_destroy_still_blocked|cjgui_native_bridge_cametallayer_create|cjgui_native_bridge_cametallayer_destroy|cjgui_native_bridge_cametallayer_token_classify|cjgui_native_bridge_cametallayer_table_occupied_count|cjgui_native_bridge_cametallayer_double_destroy_classify|cjgui_native_bridge_cametallayer_destroy_requires_main_thread|cjgui_native_bridge_cametallayer_attach_to_nsview|cjgui_native_bridge_cametallayer_detach_from_nsview|cjgui_native_bridge_cametallayer_attachment_classify|cjgui_native_bridge_cametallayer_double_detach_classify|cjgui_native_bridge_cametallayer_attach_requires_main_thread|cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked|cjgui_native_bridge_metal_import_available|cjgui_native_bridge_metal_default_device_available|cjgui_native_bridge_metal_device_no_command_queue_admission|cjgui_native_bridge_metal_device_creation_still_blocked|cjgui_native_bridge_metal_device_table_capacity|cjgui_native_bridge_metal_device_table_enabled|cjgui_native_bridge_metal_device_table_occupied_count|cjgui_native_bridge_metal_default_device_create|cjgui_native_bridge_metal_device_destroy|cjgui_native_bridge_metal_device_token_classify|cjgui_native_bridge_metal_device_double_destroy_classify|cjgui_native_bridge_metal_device_create_requires_main_thread|cjgui_native_bridge_metal_device_destroy_requires_main_thread|cjgui_native_bridge_metal_device_command_queue_still_blocked|cjgui_native_bridge_cametallayer_bind_metal_device|cjgui_native_bridge_cametallayer_unbind_metal_device|cjgui_native_bridge_cametallayer_device_binding_classify|cjgui_native_bridge_cametallayer_double_unbind_device_classify|cjgui_native_bridge_cametallayer_device_binding_requires_main_thread|cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked|cjgui_native_bridge_command_queue_table_capacity|cjgui_native_bridge_command_queue_table_enabled|cjgui_native_bridge_command_queue_table_occupied_count|cjgui_native_bridge_command_queue_create|cjgui_native_bridge_command_queue_destroy|cjgui_native_bridge_command_queue_token_classify|cjgui_native_bridge_command_queue_double_destroy_classify|cjgui_native_bridge_command_queue_create_requires_main_thread|cjgui_native_bridge_command_queue_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_creation_still_blocked|cjgui_native_bridge_command_buffer_table_capacity|cjgui_native_bridge_command_buffer_table_enabled|cjgui_native_bridge_command_buffer_table_occupied_count|cjgui_native_bridge_command_buffer_create|cjgui_native_bridge_command_buffer_destroy|cjgui_native_bridge_command_buffer_token_classify|cjgui_native_bridge_command_buffer_double_destroy_classify|cjgui_native_bridge_command_buffer_create_requires_main_thread|cjgui_native_bridge_command_buffer_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_commit_still_blocked|cjgui_native_bridge_command_buffer_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_table_capacity|cjgui_native_bridge_render_pass_descriptor_table_enabled|cjgui_native_bridge_render_pass_descriptor_table_occupied_count|cjgui_native_bridge_render_pass_descriptor_create|cjgui_native_bridge_render_pass_descriptor_destroy|cjgui_native_bridge_render_pass_descriptor_token_classify|cjgui_native_bridge_render_pass_descriptor_double_destroy_classify|cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked|cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked)$'
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge token issue/revoke probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge token issue/revoke probe: missing production native bridge" >&2
  exit 3
fi
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge token issue/revoke probe: production bridge must not import Cocoa / Metal frameworks" >&2
  exit 4
fi
if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSWindow|NSApplication|CALayer)[[:space:]]+(alloc|new)\]|(NSWindow|NSApplication|CALayer)[[:space:]]*\*|nextDrawable|commit\]|presentDrawable|present\]|\[[^]]+[[:space:]]+(retain|release)\]|CFRelease|CFRetain|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge token issue/revoke probe: forbidden resource/native behavior token found" >&2
  exit 5
fi
while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge token issue/revoke probe: callable outside allowlist: $callable_name" >&2
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
  echo "cjgui native bridge token issue/revoke probe: cjc not found" >&2
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
  echo "cjgui native bridge token issue/revoke probe: clang not found" >&2
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
  echo "cjgui native bridge token issue/revoke probe: SDKROOT not found" >&2
  exit 9
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_TOKEN_ISSUE_REVOKE_PROBE'
foreign func cjgui_native_bridge_token_invalid(): UInt64
foreign func cjgui_native_bridge_token_table_capacity(): UInt32
foreign func cjgui_native_bridge_token_table_enabled(): UInt32
foreign func cjgui_native_bridge_token_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_token_issue(): UInt64
foreign func cjgui_native_bridge_token_revoke(token: UInt64): Int32
main(): Int64 {
    println("cjgui native bridge token issue/revoke probe: requested=true")
    let invalidToken = unsafe {
        cjgui_native_bridge_token_invalid()
    }
    let tableCapacity = unsafe {
        cjgui_native_bridge_token_table_capacity()
    }
    let tableEnabled = unsafe {
        cjgui_native_bridge_token_table_enabled()
    }
    let invalidTokenClass = unsafe {
        cjgui_native_bridge_token_classify(invalidToken)
    }
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let issuedTokenClass = unsafe {
        cjgui_native_bridge_token_classify(issuedToken)
    }
    let revokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    let revokedTokenClass = unsafe {
        cjgui_native_bridge_token_classify(issuedToken)
    }
    let doubleRevokeStatus = unsafe {
        cjgui_native_bridge_token_revoke(issuedToken)
    }
    let capacityObserved = tableCapacity == UInt32(8)
    let enabledObserved = tableEnabled == UInt32(1)
    let invalidObserved =
        invalidToken == UInt64(0) && invalidTokenClass == Int32(0)
    let issueObserved =
        issuedToken != UInt64(0) && issuedTokenClass == Int32(1)
    let revokeObserved =
        revokeStatus == Int32(0) && revokedTokenClass == Int32(-2)
    let doubleRevokeObserved = doubleRevokeStatus == Int32(-2)
    let success = capacityObserved &&
        enabledObserved &&
        invalidObserved &&
        issueObserved &&
        revokeObserved &&
        doubleRevokeObserved
    println("cjgui native bridge token issue/revoke probe: capacity_observed=${capacityObserved}")
    println("cjgui native bridge token issue/revoke probe: table_enabled_observed=${enabledObserved}")
    println("cjgui native bridge token issue/revoke probe: invalid_token_observed=${invalidObserved}")
    println("cjgui native bridge token issue/revoke probe: issue_observed=${issueObserved}")
    println("cjgui native bridge token issue/revoke probe: revoke_observed=${revokeObserved}")
    println("cjgui native bridge token issue/revoke probe: double_revoke_observed=${doubleRevokeObserved}")
    println("cjgui native bridge token issue/revoke probe: public_api_modified=false")
    println("cjgui native bridge token issue/revoke probe: resource_callable_invoked=false")
    println("cjgui native bridge token issue/revoke probe: native_object_created=false")
    if (success) {
        println("cjgui native bridge token issue/revoke probe: success=true reason=none")
        return 0
    }
    println("cjgui native bridge token issue/revoke probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_TOKEN_ISSUE_REVOKE_PROBE
echo "cjgui native bridge token issue/revoke probe: output=$OUTPUT_DIR"
echo "cjgui native bridge token issue/revoke probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge token issue/revoke probe: compiling production no-resource bridge"
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
  -lcjgui_native_bridge_token_issue_revoke_probe \
  --link-options "-framework AppKit -framework QuartzCore -framework Metal -lobjc" \
  -o "$PROBE_EXECUTABLE"
if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi
"$PROBE_EXECUTABLE"
