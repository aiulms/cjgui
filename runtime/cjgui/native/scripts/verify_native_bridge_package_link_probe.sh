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
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked|cjgui_native_bridge_cametallayer_allocation_feasible|cjgui_native_bridge_cametallayer_allocation_requires_main_thread|cjgui_native_bridge_cametallayer_allocation_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_device_binding_blocked|cjgui_native_bridge_cametallayer_allocation_feasibility_probe|cjgui_native_bridge_cametallayer_table_capacity|cjgui_native_bridge_cametallayer_table_enabled|cjgui_native_bridge_cametallayer_table_empty|cjgui_native_bridge_cametallayer_table_token_classify|cjgui_native_bridge_cametallayer_table_allocation_still_blocked|cjgui_native_bridge_cametallayer_table_destroy_still_blocked|cjgui_native_bridge_cametallayer_create|cjgui_native_bridge_cametallayer_destroy|cjgui_native_bridge_cametallayer_token_classify|cjgui_native_bridge_cametallayer_table_occupied_count|cjgui_native_bridge_cametallayer_double_destroy_classify|cjgui_native_bridge_cametallayer_destroy_requires_main_thread|cjgui_native_bridge_cametallayer_attach_to_nsview|cjgui_native_bridge_cametallayer_detach_from_nsview|cjgui_native_bridge_cametallayer_attachment_classify|cjgui_native_bridge_cametallayer_double_detach_classify|cjgui_native_bridge_cametallayer_attach_requires_main_thread|cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked|cjgui_native_bridge_metal_import_available|cjgui_native_bridge_metal_default_device_available|cjgui_native_bridge_metal_device_no_command_queue_admission|cjgui_native_bridge_metal_device_creation_still_blocked|cjgui_native_bridge_metal_device_table_capacity|cjgui_native_bridge_metal_device_table_enabled|cjgui_native_bridge_metal_device_table_occupied_count|cjgui_native_bridge_metal_default_device_create|cjgui_native_bridge_metal_device_destroy|cjgui_native_bridge_metal_device_token_classify|cjgui_native_bridge_metal_device_double_destroy_classify|cjgui_native_bridge_metal_device_create_requires_main_thread|cjgui_native_bridge_metal_device_destroy_requires_main_thread|cjgui_native_bridge_metal_device_command_queue_still_blocked|cjgui_native_bridge_cametallayer_bind_metal_device|cjgui_native_bridge_cametallayer_unbind_metal_device|cjgui_native_bridge_cametallayer_device_binding_classify|cjgui_native_bridge_cametallayer_double_unbind_device_classify|cjgui_native_bridge_cametallayer_device_binding_requires_main_thread|cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked|cjgui_native_bridge_command_queue_table_capacity|cjgui_native_bridge_command_queue_table_enabled|cjgui_native_bridge_command_queue_table_occupied_count|cjgui_native_bridge_command_queue_create|cjgui_native_bridge_command_queue_destroy|cjgui_native_bridge_command_queue_token_classify|cjgui_native_bridge_command_queue_double_destroy_classify|cjgui_native_bridge_command_queue_create_requires_main_thread|cjgui_native_bridge_command_queue_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_creation_still_blocked|cjgui_native_bridge_command_buffer_table_capacity|cjgui_native_bridge_command_buffer_table_enabled|cjgui_native_bridge_command_buffer_table_occupied_count|cjgui_native_bridge_command_buffer_create|cjgui_native_bridge_command_buffer_destroy|cjgui_native_bridge_command_buffer_token_classify|cjgui_native_bridge_command_buffer_double_destroy_classify|cjgui_native_bridge_command_buffer_create_requires_main_thread|cjgui_native_bridge_command_buffer_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_commit_still_blocked|cjgui_native_bridge_command_buffer_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_table_capacity|cjgui_native_bridge_render_pass_descriptor_table_enabled|cjgui_native_bridge_render_pass_descriptor_table_occupied_count|cjgui_native_bridge_render_pass_descriptor_create|cjgui_native_bridge_render_pass_descriptor_destroy|cjgui_native_bridge_render_pass_descriptor_token_classify|cjgui_native_bridge_render_pass_descriptor_double_destroy_classify|cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked|cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked)$'
PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_pipeline_descriptor_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|configure_requires_main_thread|configure_no_draw|color_pixel_format_classify|sample_count_classify|shader_library_still_blocked|vertex_function_still_blocked|fragment_function_still_blocked|blending_still_blocked|encoder_binding_still_blocked)|cjgui_native_bridge_pipeline_state_creation_still_blocked)$'
VERTEX_BUFFER_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?cjgui_native_bridge_vertex_buffer_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|upload_static_triangle|data_classify|create_requires_main_thread|destroy_requires_main_thread|upload_requires_main_thread|layout_position_color|encoder_binding_still_blocked|draw_still_blocked)$'
DRAW_CALL_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?cjgui_native_bridge_draw_call_(encoder_required|pipeline_binding_required|vertex_binding_required|still_blocked)$'
NSWINDOW_HARNESS_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?cjgui_native_bridge_nswindow_(harness_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|next_drawable_still_blocked|command_buffer_still_blocked|render_encoder_still_blocked|present_still_blocked|content_view_(attach|detach|attachment_classify|double_attach_classify|double_detach_classify|attach_requires_main_thread|visible_order_still_blocked))|visible_order_(application_ownership_required|application_creation_deferred|activation_deferred|bounded_run_loop_required|auto_close_required|headless_fail_closed|content_view_required|still_blocked|drawable_still_blocked|render_still_blocked))$'
NSAPPLICATION_GUARD_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?cjgui_native_bridge_nsapplication_guard_(ownership_required|main_thread_required|creation_deferred|activation_deferred|activation_policy_deferred|event_loop_deferred|bounded_run_loop_required|auto_close_required|headless_fail_closed|visible_order_still_blocked|drawable_still_blocked|render_still_blocked)$'
SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_shader_(source_contract_available|library_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread)|function_(table_capacity|table_enabled|table_occupied_count|lookup_vertex|lookup_fragment|destroy|token_classify|double_destroy_classify|lookup_requires_main_thread|destroy_requires_main_thread|missing_classify)|pipeline_state_creation_still_blocked|encoder_binding_still_blocked|draw_still_blocked)|cjgui_native_bridge_pipeline_state_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|encoder_binding_still_blocked|draw_still_blocked))$'
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
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: production skeleton must not import Cocoa / Metal frameworks" >&2
  exit 7
fi
if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSApplication|CALayer)[[:space:]]+(alloc|new)\]|(NSApplication|CALayer)[[:space:]]*\*|nextDrawable|commit\]|presentDrawable|present\]|\[[^]]+[[:space:]]+(retain|release)\]|CFRelease|CFRetain' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 8
fi
while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $VERTEX_BUFFER_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $DRAW_CALL_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $NSWINDOW_HARNESS_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $NSAPPLICATION_GUARD_ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge package link probe: callable symbol is outside no-resource allowlist: $callable_name" >&2
    exit 9
  fi
done < <(grep -Eoh 'cjgui_native_bridge_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')
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
foreign func cjgui_native_bridge_token_invalid(): UInt64
foreign func cjgui_native_bridge_token_table_capacity(): UInt32
foreign func cjgui_native_bridge_token_table_enabled(): UInt32
foreign func cjgui_native_bridge_token_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_token_issue(): UInt64
foreign func cjgui_native_bridge_token_revoke(token: UInt64): Int32
foreign func cjgui_native_bridge_teardown_admission(token: UInt64): Int32
foreign func cjgui_native_bridge_destroy_not_supported(): Int32
foreign func cjgui_native_bridge_revoke_before_destroy_required(): Int32
foreign func cjgui_native_bridge_double_destroy_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_appkit_import_available(): Int32
foreign func cjgui_native_bridge_appkit_no_object_admission(): Int32
foreign func cjgui_native_bridge_platform_object_create_still_blocked(): Int32
foreign func cjgui_native_bridge_appkit_nswindow_class_available(): Int32
foreign func cjgui_native_bridge_appkit_nsview_class_available(): Int32
foreign func cjgui_native_bridge_appkit_class_lookup_no_object_admission(): Int32
foreign func cjgui_native_bridge_platform_object_allocation_still_blocked(): Int32
foreign func cjgui_native_bridge_appkit_platform_object_main_thread_required():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_main_thread_admitted():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_background_thread_denied():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_creation_still_blocked():
    Int32
foreign func cjgui_native_bridge_platform_object_create_no_object_admission():
    Int32
foreign func cjgui_native_bridge_platform_object_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_platform_object_create_requires_token_contract():
    Int32
foreign func cjgui_native_bridge_platform_object_create_allocation_blocked():
    Int32
foreign func cjgui_native_bridge_nsview_table_capacity(): UInt32
foreign func cjgui_native_bridge_nsview_table_enabled(): UInt32
foreign func cjgui_native_bridge_nsview_table_empty(): Int32
foreign func cjgui_native_bridge_nsview_table_token_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_nsview_table_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_nsview_table_destroy_still_blocked():
    Int32
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
    let tokenInvalid = unsafe {
        cjgui_native_bridge_token_invalid()
    }
    let tokenTableCapacity = unsafe {
        cjgui_native_bridge_token_table_capacity()
    }
    let tokenTableEnabled = unsafe {
        cjgui_native_bridge_token_table_enabled()
    }
    let tokenInvalidClass = unsafe {
        cjgui_native_bridge_token_classify(tokenInvalid)
    }
    let tokenNonZeroClass = unsafe {
        cjgui_native_bridge_token_classify(UInt64(1))
    }
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let issuedTokenClass = unsafe {
        cjgui_native_bridge_token_classify(issuedToken)
    }
    let nsViewTableCapacity = unsafe {
        cjgui_native_bridge_nsview_table_capacity()
    }
    let nsViewTableEnabled = unsafe {
        cjgui_native_bridge_nsview_table_enabled()
    }
    let nsViewTableEmpty = unsafe {
        cjgui_native_bridge_nsview_table_empty()
    }
    let nsViewTableTokenClass = unsafe {
        cjgui_native_bridge_nsview_table_token_classify(issuedToken)
    }
    let nsViewTableAllocationBlocked = unsafe {
        cjgui_native_bridge_nsview_table_allocation_still_blocked()
    }
    let nsViewTableDestroyBlocked = unsafe {
        cjgui_native_bridge_nsview_table_destroy_still_blocked()
    }
    let nsViewOccupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    var createdNsViewToken = UInt64(0)
    let nsViewCreateStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout createdNsViewToken)
    }
    let nsViewOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let nsViewTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdNsViewToken)
    }
    let nsViewInvalidDestroy = unsafe {
        cjgui_native_bridge_nsview_destroy(UInt64(0))
    }
    let nsViewDestroyRequiresMainThread = unsafe {
        cjgui_native_bridge_nsview_destroy_requires_main_thread()
    }
    let nsViewDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdNsViewToken)
    }
    let nsViewOccupiedAfterDestroy = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let nsViewDestroyedTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdNsViewToken)
    }
    let nsViewDoubleDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdNsViewToken)
    }
    let nsViewDoubleDestroyClass = unsafe {
        cjgui_native_bridge_nsview_double_destroy_classify(createdNsViewToken)
    }
    let validTeardownAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
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
    let destroyNotSupported = unsafe {
        cjgui_native_bridge_destroy_not_supported()
    }
    let revokeBeforeDestroyRequired = unsafe {
        cjgui_native_bridge_revoke_before_destroy_required()
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_double_destroy_classify(issuedToken)
    }
    let danglingTeardownAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
    }
    let appkitImportAvailable = unsafe {
        cjgui_native_bridge_appkit_import_available()
    }
    let appkitNoObjectAdmission = unsafe {
        cjgui_native_bridge_appkit_no_object_admission()
    }
    let platformObjectStillBlocked = unsafe {
        cjgui_native_bridge_platform_object_create_still_blocked()
    }
    let nsWindowClassAvailable = unsafe {
        cjgui_native_bridge_appkit_nswindow_class_available()
    }
    let nsViewClassAvailable = unsafe {
        cjgui_native_bridge_appkit_nsview_class_available()
    }
    let classLookupNoObjectAdmission = unsafe {
        cjgui_native_bridge_appkit_class_lookup_no_object_admission()
    }
    let platformObjectAllocationStillBlocked = unsafe {
        cjgui_native_bridge_platform_object_allocation_still_blocked()
    }
    let appkitPlatformObjectMainThreadRequired = unsafe {
        cjgui_native_bridge_appkit_platform_object_main_thread_required()
    }
    let appkitPlatformObjectMainThreadAdmitted = unsafe {
        cjgui_native_bridge_appkit_platform_object_main_thread_admitted()
    }
    let appkitPlatformObjectBackgroundThreadDenied = unsafe {
        cjgui_native_bridge_appkit_platform_object_background_thread_denied()
    }
    let appkitPlatformObjectCreationStillBlocked = unsafe {
        cjgui_native_bridge_appkit_platform_object_creation_still_blocked()
    }
    let platformObjectCreateNoObjectAdmission = unsafe {
        cjgui_native_bridge_platform_object_create_no_object_admission()
    }
    let platformObjectCreateRequiresMainThread = unsafe {
        cjgui_native_bridge_platform_object_create_requires_main_thread()
    }
    let platformObjectCreateRequiresTokenContract = unsafe {
        cjgui_native_bridge_platform_object_create_requires_token_contract()
    }
    let platformObjectCreateAllocationBlocked = unsafe {
        cjgui_native_bridge_platform_object_create_allocation_blocked()
    }
    let surfaceVersionObserved = surfaceVersion == UInt32(1)
    let capabilitiesObserved = surfaceCapabilities != UInt32(0)
    let statusObserved = statusOk == UInt32(0)
    let noResourceAdmissionObserved = noResourceAdmission == UInt32(0)
    let mainThreadQueryObserved =
        mainThreadValue == Int32(1) || mainThreadValue == Int32(0)
    let mainThreadObserved = mainThreadValue == Int32(1)
    let tokenInvalidObserved = tokenInvalid == UInt64(0)
    let tokenCapacityObserved = tokenTableCapacity == UInt32(8)
    let tokenEnabledObserved = tokenTableEnabled == UInt32(1)
    let tokenClassificationObserved =
        tokenInvalidClass == Int32(0) && tokenNonZeroClass == Int32(-2)
    let tokenIssueObserved = issuedToken != UInt64(0)
    let tokenRevokeObserved =
        issuedTokenClass == Int32(1) &&
        revokeStatus == Int32(0) &&
        revokedTokenClass == Int32(-2) &&
        doubleRevokeStatus == Int32(-2)
    let teardownAdmissionObserved =
        validTeardownAdmission == Int32(-11) &&
        destroyNotSupported == Int32(-10) &&
        revokeBeforeDestroyRequired == Int32(-11) &&
        doubleDestroyClass == Int32(-12) &&
        danglingTeardownAdmission == Int32(-13)
    let appkitImportObserved = appkitImportAvailable == Int32(20)
    let appkitNoObjectObserved = appkitNoObjectAdmission == Int32(21)
    let platformObjectStillBlockedObserved =
        platformObjectStillBlocked == Int32(-20)
    let nsWindowClassAvailableObserved = nsWindowClassAvailable == Int32(22)
    let nsViewClassAvailableObserved = nsViewClassAvailable == Int32(23)
    let classLookupNoObjectAdmissionObserved =
        classLookupNoObjectAdmission == Int32(24)
    let platformObjectAllocationStillBlockedObserved =
        platformObjectAllocationStillBlocked == Int32(-21)
    let appkitPlatformObjectMainThreadRequiredObserved =
        appkitPlatformObjectMainThreadRequired == Int32(25)
    let appkitPlatformObjectMainThreadAdmittedObserved =
        appkitPlatformObjectMainThreadAdmitted == Int32(26)
    let appkitPlatformObjectBackgroundThreadDeniedObserved =
        appkitPlatformObjectBackgroundThreadDenied == Int32(-22)
    let appkitPlatformObjectCreationStillBlockedObserved =
        appkitPlatformObjectCreationStillBlocked == Int32(-23)
    let platformObjectCreateNoObjectAdmissionObserved =
        platformObjectCreateNoObjectAdmission == Int32(27)
    let platformObjectCreateRequiresMainThreadObserved =
        platformObjectCreateRequiresMainThread == Int32(28)
    let platformObjectCreateRequiresTokenContractObserved =
        platformObjectCreateRequiresTokenContract == Int32(29)
    let platformObjectCreateAllocationBlockedObserved =
        platformObjectCreateAllocationBlocked == Int32(-24)
    let nsViewTableCapacityObserved = nsViewTableCapacity == UInt32(4)
    let nsViewTableEnabledObserved = nsViewTableEnabled == UInt32(1)
    let nsViewTableEmptyObserved = nsViewTableEmpty == Int32(30)
    let nsViewTableTokenClassObserved =
        nsViewTableTokenClass == Int32(-30)
    let nsViewTableAllocationBlockedObserved =
        nsViewTableAllocationBlocked == Int32(-31)
    let nsViewTableDestroyBlockedObserved =
        nsViewTableDestroyBlocked == Int32(-32)
    let nsViewCreateObserved =
        nsViewCreateStatus == Int32(0) &&
        createdNsViewToken != UInt64(0) &&
        createdNsViewToken < UInt64(4294967296)
    let nsViewTokenValidObserved = nsViewTokenClass == Int32(40)
    let nsViewDestroyObserved = nsViewDestroyStatus == Int32(0)
    let nsViewDestroyedStaleObserved =
        nsViewDestroyedTokenClass == Int32(-43)
    let nsViewDoubleDestroyObserved =
        nsViewDoubleDestroyStatus == Int32(-46) &&
        nsViewDoubleDestroyClass == Int32(-46)
    let nsViewInvalidDestroyObserved = nsViewInvalidDestroy == Int32(-42)
    let nsViewDestroyRequiresMainThreadObserved =
        nsViewDestroyRequiresMainThread == Int32(-41)
    let nsViewOccupiedCountObserved =
        nsViewOccupiedBefore == UInt32(0) &&
        nsViewOccupiedAfterCreate == UInt32(1) &&
        nsViewOccupiedAfterDestroy == UInt32(0)
    let success = surfaceVersionObserved &&
        capabilitiesObserved &&
        statusObserved &&
        noResourceAdmissionObserved &&
        mainThreadQueryObserved &&
        mainThreadObserved &&
        tokenInvalidObserved &&
        tokenCapacityObserved &&
        tokenEnabledObserved &&
        tokenClassificationObserved &&
        tokenIssueObserved &&
        tokenRevokeObserved &&
        teardownAdmissionObserved &&
        appkitImportObserved &&
        appkitNoObjectObserved &&
        platformObjectStillBlockedObserved &&
        nsWindowClassAvailableObserved &&
        nsViewClassAvailableObserved &&
        classLookupNoObjectAdmissionObserved &&
        platformObjectAllocationStillBlockedObserved &&
        appkitPlatformObjectMainThreadRequiredObserved &&
        appkitPlatformObjectMainThreadAdmittedObserved &&
        appkitPlatformObjectBackgroundThreadDeniedObserved &&
        appkitPlatformObjectCreationStillBlockedObserved &&
        platformObjectCreateNoObjectAdmissionObserved &&
        platformObjectCreateRequiresMainThreadObserved &&
        platformObjectCreateRequiresTokenContractObserved &&
        platformObjectCreateAllocationBlockedObserved &&
        nsViewTableCapacityObserved &&
        nsViewTableEnabledObserved &&
        nsViewTableEmptyObserved &&
        nsViewTableTokenClassObserved &&
        nsViewTableAllocationBlockedObserved &&
        nsViewTableDestroyBlockedObserved &&
        nsViewCreateObserved &&
        nsViewTokenValidObserved &&
        nsViewDestroyObserved &&
        nsViewDestroyedStaleObserved &&
        nsViewDoubleDestroyObserved &&
        nsViewInvalidDestroyObserved &&
        nsViewDestroyRequiresMainThreadObserved &&
        nsViewOccupiedCountObserved
    println("cjgui native bridge package link probe: surface_version_observed=${surfaceVersionObserved}")
    println("cjgui native bridge package link probe: capabilities_observed=${capabilitiesObserved}")
    println("cjgui native bridge package link probe: status_ok_observed=${statusObserved}")
    println("cjgui native bridge package link probe: no_resource_admission_observed=${noResourceAdmissionObserved}")
    println("cjgui native bridge package link probe: main_thread_query_observed=${mainThreadQueryObserved}")
    println("cjgui native bridge package link probe: main_thread_observed=${mainThreadObserved}")
    println("cjgui native bridge package link probe: token_invalid_observed=${tokenInvalidObserved}")
    println("cjgui native bridge package link probe: token_table_capacity_observed=${tokenCapacityObserved}")
    println("cjgui native bridge package link probe: token_table_enabled_observed=${tokenEnabledObserved}")
    println("cjgui native bridge package link probe: token_classification_observed=${tokenClassificationObserved}")
    println("cjgui native bridge package link probe: token_issue_observed=${tokenIssueObserved}")
    println("cjgui native bridge package link probe: token_revoke_observed=${tokenRevokeObserved}")
    println("cjgui native bridge package link probe: teardown_admission_observed=${teardownAdmissionObserved}")
    println("cjgui native bridge package link probe: appkit_import_observed=${appkitImportObserved}")
    println("cjgui native bridge package link probe: appkit_no_object_admission_observed=${appkitNoObjectObserved}")
    println("cjgui native bridge package link probe: platform_object_still_blocked_observed=${platformObjectStillBlockedObserved}")
    println("cjgui native bridge package link probe: nswindow_class_available_observed=${nsWindowClassAvailableObserved}")
    println("cjgui native bridge package link probe: nsview_class_available_observed=${nsViewClassAvailableObserved}")
    println("cjgui native bridge package link probe: class_lookup_no_object_admission_observed=${classLookupNoObjectAdmissionObserved}")
    println("cjgui native bridge package link probe: platform_object_allocation_still_blocked_observed=${platformObjectAllocationStillBlockedObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_main_thread_required_observed=${appkitPlatformObjectMainThreadRequiredObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_main_thread_admitted_observed=${appkitPlatformObjectMainThreadAdmittedObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_background_thread_denied_observed=${appkitPlatformObjectBackgroundThreadDeniedObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_creation_still_blocked_observed=${appkitPlatformObjectCreationStillBlockedObserved}")
    println("cjgui native bridge package link probe: platform_object_create_no_object_admission_observed=${platformObjectCreateNoObjectAdmissionObserved}")
    println("cjgui native bridge package link probe: platform_object_create_requires_main_thread_observed=${platformObjectCreateRequiresMainThreadObserved}")
    println("cjgui native bridge package link probe: platform_object_create_requires_token_contract_observed=${platformObjectCreateRequiresTokenContractObserved}")
    println("cjgui native bridge package link probe: platform_object_create_allocation_blocked_observed=${platformObjectCreateAllocationBlockedObserved}")
    println("cjgui native bridge package link probe: nsview_table_capacity_observed=${nsViewTableCapacityObserved}")
    println("cjgui native bridge package link probe: nsview_table_enabled_observed=${nsViewTableEnabledObserved}")
    println("cjgui native bridge package link probe: nsview_table_empty_observed=${nsViewTableEmptyObserved}")
    println("cjgui native bridge package link probe: nsview_table_token_class_observed=${nsViewTableTokenClassObserved}")
    println("cjgui native bridge package link probe: nsview_table_allocation_blocked_observed=${nsViewTableAllocationBlockedObserved}")
    println("cjgui native bridge package link probe: nsview_table_destroy_blocked_observed=${nsViewTableDestroyBlockedObserved}")
    println("cjgui native bridge package link probe: nsview_create_observed=${nsViewCreateObserved}")
    println("cjgui native bridge package link probe: nsview_token_valid_observed=${nsViewTokenValidObserved}")
    println("cjgui native bridge package link probe: nsview_destroy_observed=${nsViewDestroyObserved}")
    println("cjgui native bridge package link probe: nsview_destroyed_stale_observed=${nsViewDestroyedStaleObserved}")
    println("cjgui native bridge package link probe: nsview_double_destroy_observed=${nsViewDoubleDestroyObserved}")
    println("cjgui native bridge package link probe: nsview_invalid_destroy_observed=${nsViewInvalidDestroyObserved}")
    println("cjgui native bridge package link probe: nsview_destroy_requires_main_thread_observed=${nsViewDestroyRequiresMainThreadObserved}")
    println("cjgui native bridge package link probe: nsview_occupied_count_observed=${nsViewOccupiedCountObserved}")
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
  -fno-objc-msgsend-selector-stubs \
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
  --link-options "-framework AppKit -framework QuartzCore -framework Metal -lobjc" \
  -o "$PROBE_EXECUTABLE"
if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi
"$PROBE_EXECUTABLE"

SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_shader_(source_contract_available|library_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread)|function_(table_capacity|table_enabled|table_occupied_count|lookup_vertex|lookup_fragment|destroy|token_classify|double_destroy_classify|lookup_requires_main_thread|destroy_requires_main_thread|missing_classify)|pipeline_state_creation_still_blocked|encoder_binding_still_blocked|draw_still_blocked)|cjgui_native_bridge_pipeline_state_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|encoder_binding_still_blocked|draw_still_blocked))$'
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
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: production skeleton must not import Cocoa / Metal frameworks" >&2
  exit 7
fi
if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSApplication|CALayer)[[:space:]]+(alloc|new)\]|(NSApplication|CALayer)[[:space:]]*\*|nextDrawable|commit\]|presentDrawable|present\]|\[[^]]+[[:space:]]+(retain|release)\]|CFRelease|CFRetain' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge package link probe: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 8
fi
while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $VERTEX_BUFFER_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $DRAW_CALL_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $NSWINDOW_HARNESS_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $NSAPPLICATION_GUARD_ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge package link probe: callable symbol is outside no-resource allowlist: $callable_name" >&2
    exit 9
  fi
done < <(grep -Eoh 'cjgui_native_bridge_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')
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
foreign func cjgui_native_bridge_token_invalid(): UInt64
foreign func cjgui_native_bridge_token_table_capacity(): UInt32
foreign func cjgui_native_bridge_token_table_enabled(): UInt32
foreign func cjgui_native_bridge_token_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_token_issue(): UInt64
foreign func cjgui_native_bridge_token_revoke(token: UInt64): Int32
foreign func cjgui_native_bridge_teardown_admission(token: UInt64): Int32
foreign func cjgui_native_bridge_destroy_not_supported(): Int32
foreign func cjgui_native_bridge_revoke_before_destroy_required(): Int32
foreign func cjgui_native_bridge_double_destroy_classify(token: UInt64): Int32
foreign func cjgui_native_bridge_appkit_import_available(): Int32
foreign func cjgui_native_bridge_appkit_no_object_admission(): Int32
foreign func cjgui_native_bridge_platform_object_create_still_blocked(): Int32
foreign func cjgui_native_bridge_appkit_nswindow_class_available(): Int32
foreign func cjgui_native_bridge_appkit_nsview_class_available(): Int32
foreign func cjgui_native_bridge_appkit_class_lookup_no_object_admission(): Int32
foreign func cjgui_native_bridge_platform_object_allocation_still_blocked(): Int32
foreign func cjgui_native_bridge_appkit_platform_object_main_thread_required():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_main_thread_admitted():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_background_thread_denied():
    Int32
foreign func cjgui_native_bridge_appkit_platform_object_creation_still_blocked():
    Int32
foreign func cjgui_native_bridge_platform_object_create_no_object_admission():
    Int32
foreign func cjgui_native_bridge_platform_object_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_platform_object_create_requires_token_contract():
    Int32
foreign func cjgui_native_bridge_platform_object_create_allocation_blocked():
    Int32
foreign func cjgui_native_bridge_nsview_table_capacity(): UInt32
foreign func cjgui_native_bridge_nsview_table_enabled(): UInt32
foreign func cjgui_native_bridge_nsview_table_empty(): Int32
foreign func cjgui_native_bridge_nsview_table_token_classify(token: UInt64):
    Int32
foreign func cjgui_native_bridge_nsview_table_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_nsview_table_destroy_still_blocked():
    Int32
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
    let tokenInvalid = unsafe {
        cjgui_native_bridge_token_invalid()
    }
    let tokenTableCapacity = unsafe {
        cjgui_native_bridge_token_table_capacity()
    }
    let tokenTableEnabled = unsafe {
        cjgui_native_bridge_token_table_enabled()
    }
    let tokenInvalidClass = unsafe {
        cjgui_native_bridge_token_classify(tokenInvalid)
    }
    let tokenNonZeroClass = unsafe {
        cjgui_native_bridge_token_classify(UInt64(1))
    }
    let issuedToken = unsafe {
        cjgui_native_bridge_token_issue()
    }
    let issuedTokenClass = unsafe {
        cjgui_native_bridge_token_classify(issuedToken)
    }
    let nsViewTableCapacity = unsafe {
        cjgui_native_bridge_nsview_table_capacity()
    }
    let nsViewTableEnabled = unsafe {
        cjgui_native_bridge_nsview_table_enabled()
    }
    let nsViewTableEmpty = unsafe {
        cjgui_native_bridge_nsview_table_empty()
    }
    let nsViewTableTokenClass = unsafe {
        cjgui_native_bridge_nsview_table_token_classify(issuedToken)
    }
    let nsViewTableAllocationBlocked = unsafe {
        cjgui_native_bridge_nsview_table_allocation_still_blocked()
    }
    let nsViewTableDestroyBlocked = unsafe {
        cjgui_native_bridge_nsview_table_destroy_still_blocked()
    }
    let nsViewOccupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    var createdNsViewToken = UInt64(0)
    let nsViewCreateStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout createdNsViewToken)
    }
    let nsViewOccupiedAfterCreate = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let nsViewTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdNsViewToken)
    }
    let nsViewInvalidDestroy = unsafe {
        cjgui_native_bridge_nsview_destroy(UInt64(0))
    }
    let nsViewDestroyRequiresMainThread = unsafe {
        cjgui_native_bridge_nsview_destroy_requires_main_thread()
    }
    let nsViewDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdNsViewToken)
    }
    let nsViewOccupiedAfterDestroy = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let nsViewDestroyedTokenClass = unsafe {
        cjgui_native_bridge_nsview_token_classify(createdNsViewToken)
    }
    let nsViewDoubleDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(createdNsViewToken)
    }
    let nsViewDoubleDestroyClass = unsafe {
        cjgui_native_bridge_nsview_double_destroy_classify(createdNsViewToken)
    }
    let validTeardownAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
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
    let destroyNotSupported = unsafe {
        cjgui_native_bridge_destroy_not_supported()
    }
    let revokeBeforeDestroyRequired = unsafe {
        cjgui_native_bridge_revoke_before_destroy_required()
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_double_destroy_classify(issuedToken)
    }
    let danglingTeardownAdmission = unsafe {
        cjgui_native_bridge_teardown_admission(issuedToken)
    }
    let appkitImportAvailable = unsafe {
        cjgui_native_bridge_appkit_import_available()
    }
    let appkitNoObjectAdmission = unsafe {
        cjgui_native_bridge_appkit_no_object_admission()
    }
    let platformObjectStillBlocked = unsafe {
        cjgui_native_bridge_platform_object_create_still_blocked()
    }
    let nsWindowClassAvailable = unsafe {
        cjgui_native_bridge_appkit_nswindow_class_available()
    }
    let nsViewClassAvailable = unsafe {
        cjgui_native_bridge_appkit_nsview_class_available()
    }
    let classLookupNoObjectAdmission = unsafe {
        cjgui_native_bridge_appkit_class_lookup_no_object_admission()
    }
    let platformObjectAllocationStillBlocked = unsafe {
        cjgui_native_bridge_platform_object_allocation_still_blocked()
    }
    let appkitPlatformObjectMainThreadRequired = unsafe {
        cjgui_native_bridge_appkit_platform_object_main_thread_required()
    }
    let appkitPlatformObjectMainThreadAdmitted = unsafe {
        cjgui_native_bridge_appkit_platform_object_main_thread_admitted()
    }
    let appkitPlatformObjectBackgroundThreadDenied = unsafe {
        cjgui_native_bridge_appkit_platform_object_background_thread_denied()
    }
    let appkitPlatformObjectCreationStillBlocked = unsafe {
        cjgui_native_bridge_appkit_platform_object_creation_still_blocked()
    }
    let platformObjectCreateNoObjectAdmission = unsafe {
        cjgui_native_bridge_platform_object_create_no_object_admission()
    }
    let platformObjectCreateRequiresMainThread = unsafe {
        cjgui_native_bridge_platform_object_create_requires_main_thread()
    }
    let platformObjectCreateRequiresTokenContract = unsafe {
        cjgui_native_bridge_platform_object_create_requires_token_contract()
    }
    let platformObjectCreateAllocationBlocked = unsafe {
        cjgui_native_bridge_platform_object_create_allocation_blocked()
    }
    let surfaceVersionObserved = surfaceVersion == UInt32(1)
    let capabilitiesObserved = surfaceCapabilities != UInt32(0)
    let statusObserved = statusOk == UInt32(0)
    let noResourceAdmissionObserved = noResourceAdmission == UInt32(0)
    let mainThreadQueryObserved =
        mainThreadValue == Int32(1) || mainThreadValue == Int32(0)
    let mainThreadObserved = mainThreadValue == Int32(1)
    let tokenInvalidObserved = tokenInvalid == UInt64(0)
    let tokenCapacityObserved = tokenTableCapacity == UInt32(8)
    let tokenEnabledObserved = tokenTableEnabled == UInt32(1)
    let tokenClassificationObserved =
        tokenInvalidClass == Int32(0) && tokenNonZeroClass == Int32(-2)
    let tokenIssueObserved = issuedToken != UInt64(0)
    let tokenRevokeObserved =
        issuedTokenClass == Int32(1) &&
        revokeStatus == Int32(0) &&
        revokedTokenClass == Int32(-2) &&
        doubleRevokeStatus == Int32(-2)
    let teardownAdmissionObserved =
        validTeardownAdmission == Int32(-11) &&
        destroyNotSupported == Int32(-10) &&
        revokeBeforeDestroyRequired == Int32(-11) &&
        doubleDestroyClass == Int32(-12) &&
        danglingTeardownAdmission == Int32(-13)
    let appkitImportObserved = appkitImportAvailable == Int32(20)
    let appkitNoObjectObserved = appkitNoObjectAdmission == Int32(21)
    let platformObjectStillBlockedObserved =
        platformObjectStillBlocked == Int32(-20)
    let nsWindowClassAvailableObserved = nsWindowClassAvailable == Int32(22)
    let nsViewClassAvailableObserved = nsViewClassAvailable == Int32(23)
    let classLookupNoObjectAdmissionObserved =
        classLookupNoObjectAdmission == Int32(24)
    let platformObjectAllocationStillBlockedObserved =
        platformObjectAllocationStillBlocked == Int32(-21)
    let appkitPlatformObjectMainThreadRequiredObserved =
        appkitPlatformObjectMainThreadRequired == Int32(25)
    let appkitPlatformObjectMainThreadAdmittedObserved =
        appkitPlatformObjectMainThreadAdmitted == Int32(26)
    let appkitPlatformObjectBackgroundThreadDeniedObserved =
        appkitPlatformObjectBackgroundThreadDenied == Int32(-22)
    let appkitPlatformObjectCreationStillBlockedObserved =
        appkitPlatformObjectCreationStillBlocked == Int32(-23)
    let platformObjectCreateNoObjectAdmissionObserved =
        platformObjectCreateNoObjectAdmission == Int32(27)
    let platformObjectCreateRequiresMainThreadObserved =
        platformObjectCreateRequiresMainThread == Int32(28)
    let platformObjectCreateRequiresTokenContractObserved =
        platformObjectCreateRequiresTokenContract == Int32(29)
    let platformObjectCreateAllocationBlockedObserved =
        platformObjectCreateAllocationBlocked == Int32(-24)
    let nsViewTableCapacityObserved = nsViewTableCapacity == UInt32(4)
    let nsViewTableEnabledObserved = nsViewTableEnabled == UInt32(1)
    let nsViewTableEmptyObserved = nsViewTableEmpty == Int32(30)
    let nsViewTableTokenClassObserved =
        nsViewTableTokenClass == Int32(-30)
    let nsViewTableAllocationBlockedObserved =
        nsViewTableAllocationBlocked == Int32(-31)
    let nsViewTableDestroyBlockedObserved =
        nsViewTableDestroyBlocked == Int32(-32)
    let nsViewCreateObserved =
        nsViewCreateStatus == Int32(0) &&
        createdNsViewToken != UInt64(0) &&
        createdNsViewToken < UInt64(4294967296)
    let nsViewTokenValidObserved = nsViewTokenClass == Int32(40)
    let nsViewDestroyObserved = nsViewDestroyStatus == Int32(0)
    let nsViewDestroyedStaleObserved =
        nsViewDestroyedTokenClass == Int32(-43)
    let nsViewDoubleDestroyObserved =
        nsViewDoubleDestroyStatus == Int32(-46) &&
        nsViewDoubleDestroyClass == Int32(-46)
    let nsViewInvalidDestroyObserved = nsViewInvalidDestroy == Int32(-42)
    let nsViewDestroyRequiresMainThreadObserved =
        nsViewDestroyRequiresMainThread == Int32(-41)
    let nsViewOccupiedCountObserved =
        nsViewOccupiedBefore == UInt32(0) &&
        nsViewOccupiedAfterCreate == UInt32(1) &&
        nsViewOccupiedAfterDestroy == UInt32(0)
    let success = surfaceVersionObserved &&
        capabilitiesObserved &&
        statusObserved &&
        noResourceAdmissionObserved &&
        mainThreadQueryObserved &&
        mainThreadObserved &&
        tokenInvalidObserved &&
        tokenCapacityObserved &&
        tokenEnabledObserved &&
        tokenClassificationObserved &&
        tokenIssueObserved &&
        tokenRevokeObserved &&
        teardownAdmissionObserved &&
        appkitImportObserved &&
        appkitNoObjectObserved &&
        platformObjectStillBlockedObserved &&
        nsWindowClassAvailableObserved &&
        nsViewClassAvailableObserved &&
        classLookupNoObjectAdmissionObserved &&
        platformObjectAllocationStillBlockedObserved &&
        appkitPlatformObjectMainThreadRequiredObserved &&
        appkitPlatformObjectMainThreadAdmittedObserved &&
        appkitPlatformObjectBackgroundThreadDeniedObserved &&
        appkitPlatformObjectCreationStillBlockedObserved &&
        platformObjectCreateNoObjectAdmissionObserved &&
        platformObjectCreateRequiresMainThreadObserved &&
        platformObjectCreateRequiresTokenContractObserved &&
        platformObjectCreateAllocationBlockedObserved &&
        nsViewTableCapacityObserved &&
        nsViewTableEnabledObserved &&
        nsViewTableEmptyObserved &&
        nsViewTableTokenClassObserved &&
        nsViewTableAllocationBlockedObserved &&
        nsViewTableDestroyBlockedObserved &&
        nsViewCreateObserved &&
        nsViewTokenValidObserved &&
        nsViewDestroyObserved &&
        nsViewDestroyedStaleObserved &&
        nsViewDoubleDestroyObserved &&
        nsViewInvalidDestroyObserved &&
        nsViewDestroyRequiresMainThreadObserved &&
        nsViewOccupiedCountObserved
    println("cjgui native bridge package link probe: surface_version_observed=${surfaceVersionObserved}")
    println("cjgui native bridge package link probe: capabilities_observed=${capabilitiesObserved}")
    println("cjgui native bridge package link probe: status_ok_observed=${statusObserved}")
    println("cjgui native bridge package link probe: no_resource_admission_observed=${noResourceAdmissionObserved}")
    println("cjgui native bridge package link probe: main_thread_query_observed=${mainThreadQueryObserved}")
    println("cjgui native bridge package link probe: main_thread_observed=${mainThreadObserved}")
    println("cjgui native bridge package link probe: token_invalid_observed=${tokenInvalidObserved}")
    println("cjgui native bridge package link probe: token_table_capacity_observed=${tokenCapacityObserved}")
    println("cjgui native bridge package link probe: token_table_enabled_observed=${tokenEnabledObserved}")
    println("cjgui native bridge package link probe: token_classification_observed=${tokenClassificationObserved}")
    println("cjgui native bridge package link probe: token_issue_observed=${tokenIssueObserved}")
    println("cjgui native bridge package link probe: token_revoke_observed=${tokenRevokeObserved}")
    println("cjgui native bridge package link probe: teardown_admission_observed=${teardownAdmissionObserved}")
    println("cjgui native bridge package link probe: appkit_import_observed=${appkitImportObserved}")
    println("cjgui native bridge package link probe: appkit_no_object_admission_observed=${appkitNoObjectObserved}")
    println("cjgui native bridge package link probe: platform_object_still_blocked_observed=${platformObjectStillBlockedObserved}")
    println("cjgui native bridge package link probe: nswindow_class_available_observed=${nsWindowClassAvailableObserved}")
    println("cjgui native bridge package link probe: nsview_class_available_observed=${nsViewClassAvailableObserved}")
    println("cjgui native bridge package link probe: class_lookup_no_object_admission_observed=${classLookupNoObjectAdmissionObserved}")
    println("cjgui native bridge package link probe: platform_object_allocation_still_blocked_observed=${platformObjectAllocationStillBlockedObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_main_thread_required_observed=${appkitPlatformObjectMainThreadRequiredObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_main_thread_admitted_observed=${appkitPlatformObjectMainThreadAdmittedObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_background_thread_denied_observed=${appkitPlatformObjectBackgroundThreadDeniedObserved}")
    println("cjgui native bridge package link probe: appkit_platform_object_creation_still_blocked_observed=${appkitPlatformObjectCreationStillBlockedObserved}")
    println("cjgui native bridge package link probe: platform_object_create_no_object_admission_observed=${platformObjectCreateNoObjectAdmissionObserved}")
    println("cjgui native bridge package link probe: platform_object_create_requires_main_thread_observed=${platformObjectCreateRequiresMainThreadObserved}")
    println("cjgui native bridge package link probe: platform_object_create_requires_token_contract_observed=${platformObjectCreateRequiresTokenContractObserved}")
    println("cjgui native bridge package link probe: platform_object_create_allocation_blocked_observed=${platformObjectCreateAllocationBlockedObserved}")
    println("cjgui native bridge package link probe: nsview_table_capacity_observed=${nsViewTableCapacityObserved}")
    println("cjgui native bridge package link probe: nsview_table_enabled_observed=${nsViewTableEnabledObserved}")
    println("cjgui native bridge package link probe: nsview_table_empty_observed=${nsViewTableEmptyObserved}")
    println("cjgui native bridge package link probe: nsview_table_token_class_observed=${nsViewTableTokenClassObserved}")
    println("cjgui native bridge package link probe: nsview_table_allocation_blocked_observed=${nsViewTableAllocationBlockedObserved}")
    println("cjgui native bridge package link probe: nsview_table_destroy_blocked_observed=${nsViewTableDestroyBlockedObserved}")
    println("cjgui native bridge package link probe: nsview_create_observed=${nsViewCreateObserved}")
    println("cjgui native bridge package link probe: nsview_token_valid_observed=${nsViewTokenValidObserved}")
    println("cjgui native bridge package link probe: nsview_destroy_observed=${nsViewDestroyObserved}")
    println("cjgui native bridge package link probe: nsview_destroyed_stale_observed=${nsViewDestroyedStaleObserved}")
    println("cjgui native bridge package link probe: nsview_double_destroy_observed=${nsViewDoubleDestroyObserved}")
    println("cjgui native bridge package link probe: nsview_invalid_destroy_observed=${nsViewInvalidDestroyObserved}")
    println("cjgui native bridge package link probe: nsview_destroy_requires_main_thread_observed=${nsViewDestroyRequiresMainThreadObserved}")
    println("cjgui native bridge package link probe: nsview_occupied_count_observed=${nsViewOccupiedCountObserved}")
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
  -fno-objc-msgsend-selector-stubs \
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
  --link-options "-framework AppKit -framework QuartzCore -framework Metal -lobjc" \
  -o "$PROBE_EXECUTABLE"
if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi
"$PROBE_EXECUTABLE"
