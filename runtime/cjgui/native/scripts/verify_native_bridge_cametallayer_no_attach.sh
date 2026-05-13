#!/usr/bin/env zsh
#
# Owner: CAMetalLayer no-attach class/runtime FFI probe。
# Truth: 验证 production native bridge 可观察 QuartzCore import 与 CAMetalLayer
# class availability，并只暴露 no-attach integer facts。
# Stop-line: 不修改源码或 build config；本 probe 只调用 no-attach facts。
# 允许后续 attachment C ABI 存在，但仍不导入 Metal，不创建 drawable，
# 不返回 Class / id / pointer / handle。
# Same-shape Boundary Brake: no-attach probe 只是 class lookup / blocked evidence，
# 不是 layer attachment、Metal device、backend-ready、render-ready 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-cametallayer-no-attach-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_cametallayer_no_attach_probe.a"
PROBE_SOURCE="$OUTPUT_DIR/cametallayer_no_attach_probe.cj"
PROBE_EXECUTABLE="$OUTPUT_DIR/cametallayer_no_attach_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked|cjgui_native_bridge_cametallayer_allocation_feasible|cjgui_native_bridge_cametallayer_allocation_requires_main_thread|cjgui_native_bridge_cametallayer_allocation_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_device_binding_blocked|cjgui_native_bridge_cametallayer_allocation_feasibility_probe|cjgui_native_bridge_cametallayer_table_capacity|cjgui_native_bridge_cametallayer_table_enabled|cjgui_native_bridge_cametallayer_table_empty|cjgui_native_bridge_cametallayer_table_token_classify|cjgui_native_bridge_cametallayer_table_allocation_still_blocked|cjgui_native_bridge_cametallayer_table_destroy_still_blocked|cjgui_native_bridge_cametallayer_create|cjgui_native_bridge_cametallayer_destroy|cjgui_native_bridge_cametallayer_token_classify|cjgui_native_bridge_cametallayer_table_occupied_count|cjgui_native_bridge_cametallayer_double_destroy_classify|cjgui_native_bridge_cametallayer_destroy_requires_main_thread|cjgui_native_bridge_cametallayer_attach_to_nsview|cjgui_native_bridge_cametallayer_detach_from_nsview|cjgui_native_bridge_cametallayer_attachment_classify|cjgui_native_bridge_cametallayer_double_detach_classify|cjgui_native_bridge_cametallayer_attach_requires_main_thread|cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked|cjgui_native_bridge_metal_import_available|cjgui_native_bridge_metal_default_device_available|cjgui_native_bridge_metal_device_no_command_queue_admission|cjgui_native_bridge_metal_device_creation_still_blocked|cjgui_native_bridge_metal_device_table_capacity|cjgui_native_bridge_metal_device_table_enabled|cjgui_native_bridge_metal_device_table_occupied_count|cjgui_native_bridge_metal_default_device_create|cjgui_native_bridge_metal_device_destroy|cjgui_native_bridge_metal_device_token_classify|cjgui_native_bridge_metal_device_double_destroy_classify|cjgui_native_bridge_metal_device_create_requires_main_thread|cjgui_native_bridge_metal_device_destroy_requires_main_thread|cjgui_native_bridge_metal_device_command_queue_still_blocked|cjgui_native_bridge_cametallayer_bind_metal_device|cjgui_native_bridge_cametallayer_unbind_metal_device|cjgui_native_bridge_cametallayer_device_binding_classify|cjgui_native_bridge_cametallayer_double_unbind_device_classify|cjgui_native_bridge_cametallayer_device_binding_requires_main_thread|cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked|cjgui_native_bridge_command_queue_table_capacity|cjgui_native_bridge_command_queue_table_enabled|cjgui_native_bridge_command_queue_table_occupied_count|cjgui_native_bridge_command_queue_create|cjgui_native_bridge_command_queue_destroy|cjgui_native_bridge_command_queue_token_classify|cjgui_native_bridge_command_queue_double_destroy_classify|cjgui_native_bridge_command_queue_create_requires_main_thread|cjgui_native_bridge_command_queue_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_creation_still_blocked|cjgui_native_bridge_command_buffer_table_capacity|cjgui_native_bridge_command_buffer_table_enabled|cjgui_native_bridge_command_buffer_table_occupied_count|cjgui_native_bridge_command_buffer_create|cjgui_native_bridge_command_buffer_destroy|cjgui_native_bridge_command_buffer_token_classify|cjgui_native_bridge_command_buffer_double_destroy_classify|cjgui_native_bridge_command_buffer_create_requires_main_thread|cjgui_native_bridge_command_buffer_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_commit_still_blocked|cjgui_native_bridge_command_buffer_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_table_capacity|cjgui_native_bridge_render_pass_descriptor_table_enabled|cjgui_native_bridge_render_pass_descriptor_table_occupied_count|cjgui_native_bridge_render_pass_descriptor_create|cjgui_native_bridge_render_pass_descriptor_destroy|cjgui_native_bridge_render_pass_descriptor_token_classify|cjgui_native_bridge_render_pass_descriptor_double_destroy_classify|cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked|cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked)$'
PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_pipeline_descriptor_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|configure_requires_main_thread|configure_no_draw|color_pixel_format_classify|sample_count_classify|shader_library_still_blocked|vertex_function_still_blocked|fragment_function_still_blocked|blending_still_blocked|encoder_binding_still_blocked)|cjgui_native_bridge_pipeline_state_creation_still_blocked)$'
SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_shader_(source_contract_available|library_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread)|function_(table_capacity|table_enabled|table_occupied_count|lookup_vertex|lookup_fragment|destroy|token_classify|double_destroy_classify|lookup_requires_main_thread|destroy_requires_main_thread|missing_classify)|pipeline_state_creation_still_blocked|encoder_binding_still_blocked|draw_still_blocked)|cjgui_native_bridge_pipeline_state_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|encoder_binding_still_blocked|draw_still_blocked))$'
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: missing production native bridge" >&2
  exit 3
fi
if ! grep -F '#import <QuartzCore/QuartzCore.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: missing QuartzCore import boundary" >&2
  exit 4
fi
if ! grep -F 'NSClassFromString(@"CAMetalLayer")' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: missing CAMetalLayer class lookup" >&2
  exit 5
fi
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: production bridge must not import Cocoa / Metal" >&2
  exit 6
fi
if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(CALayer)[[:space:]]+(alloc|new|init)\]|(CALayer)[[:space:]]*\*|nextDrawable|commit\]|presentDrawable|present\]|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging|^[[:space:]]*(Class|id)[[:space:]]+cjgui_|^[[:space:]]*static[[:space:]]+(Class|id|CALayer)[[:space:]]' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: forbidden layer/Metal/pointer/storage token found" >&2
  exit 7
fi
while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge CAMetalLayer no-attach probe: callable outside allowlist: $callable_name" >&2
    exit 8
  fi
done < <(grep -Eoh 'cjgui_native_bridge_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')
if ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: cjc not found" >&2
  exit 9
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
  echo "cjgui native bridge CAMetalLayer no-attach probe: clang not found" >&2
  exit 10
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge CAMetalLayer no-attach probe: SDKROOT not found" >&2
  exit 11
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_CAMETALLAYER_NO_ATTACH_PROBE'
foreign func cjgui_native_bridge_quartzcore_import_available(): Int32
foreign func cjgui_native_bridge_cametallayer_class_available(): Int32
foreign func cjgui_native_bridge_cametallayer_no_attach_admission(): Int32
foreign func cjgui_native_bridge_cametallayer_allocation_still_blocked():
    Int32
foreign func cjgui_native_bridge_cametallayer_device_binding_still_blocked():
    Int32
main(): Int64 {
    println("cjgui native bridge CAMetalLayer no-attach probe: requested=true")
    let quartzCoreImportAvailable = unsafe {
        cjgui_native_bridge_quartzcore_import_available()
    }
    let cametalLayerClassAvailable = unsafe {
        cjgui_native_bridge_cametallayer_class_available()
    }
    let noAttachAdmission = unsafe {
        cjgui_native_bridge_cametallayer_no_attach_admission()
    }
    let allocationStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_allocation_still_blocked()
    }
    let deviceBindingStillBlocked = unsafe {
        cjgui_native_bridge_cametallayer_device_binding_still_blocked()
    }
    let quartzCoreImportObserved = quartzCoreImportAvailable == Int32(50)
    let cametalLayerClassObserved = cametalLayerClassAvailable == Int32(51)
    let noAttachAdmissionObserved = noAttachAdmission == Int32(52)
    let allocationStillBlockedObserved =
        allocationStillBlocked == Int32(-50)
    let deviceBindingStillBlockedObserved =
        deviceBindingStillBlocked == Int32(-51)
    let success = quartzCoreImportObserved &&
        cametalLayerClassObserved &&
        noAttachAdmissionObserved &&
        allocationStillBlockedObserved &&
        deviceBindingStillBlockedObserved
    println("cjgui native bridge CAMetalLayer no-attach probe: quartzcore_import_observed=${quartzCoreImportObserved}")
    println("cjgui native bridge CAMetalLayer no-attach probe: cametallayer_class_available_observed=${cametalLayerClassObserved}")
    println("cjgui native bridge CAMetalLayer no-attach probe: no_attach_admission_observed=${noAttachAdmissionObserved}")
    println("cjgui native bridge CAMetalLayer no-attach probe: allocation_still_blocked_observed=${allocationStillBlockedObserved}")
    println("cjgui native bridge CAMetalLayer no-attach probe: device_binding_still_blocked_observed=${deviceBindingStillBlockedObserved}")
    println("cjgui native bridge CAMetalLayer no-attach probe: layer_allocated=false")
    println("cjgui native bridge CAMetalLayer no-attach probe: layer_attached=false")
    println("cjgui native bridge CAMetalLayer no-attach probe: metal_import_allowed=true")
    println("cjgui native bridge CAMetalLayer no-attach probe: metal_device_created_by_probe=false")
    println("cjgui native bridge CAMetalLayer no-attach probe: drawable_acquired=false")
    println("cjgui native bridge CAMetalLayer no-attach probe: pointer_returned=false")
    println("cjgui native bridge CAMetalLayer no-attach probe: public_api_modified=false")
    if (success) {
        println("cjgui native bridge CAMetalLayer no-attach probe: success=true reason=none")
        return 0
    }
    println("cjgui native bridge CAMetalLayer no-attach probe: success=false reason=value_mismatch")
    return 1
}
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_NO_ATTACH_PROBE
echo "cjgui native bridge CAMetalLayer no-attach probe: output=$OUTPUT_DIR"
echo "cjgui native bridge CAMetalLayer no-attach probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge CAMetalLayer no-attach probe: compiling production bridge"
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
  -lcjgui_native_bridge_cametallayer_no_attach_probe \
  --link-options "-framework AppKit -framework QuartzCore -framework Metal -lobjc" \
  -o "$PROBE_EXECUTABLE"
if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
  export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
fi
"$PROBE_EXECUTABLE"
