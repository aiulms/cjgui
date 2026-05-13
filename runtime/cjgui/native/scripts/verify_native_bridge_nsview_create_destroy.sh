#!/usr/bin/env zsh
#
# Owner: platform object NSView create/destroy first-slice probe。
# Truth: 验证 production native bridge 只通过 opaque token 创建、持有、销毁固定容量
# NSView，并保持 fail-closed classification。
# Stop-line: 不修改源码或 build config，不返回 Class / id / pointer / handle，
# 不创建 NSWindow / NSApplication / CALayer / CAMetalLayer，不导入 Metal。
# Same-shape Boundary Brake: create/destroy probe 只证明 NSView token lifecycle
# 首片可执行，不是 backend-ready、render-ready、Metal layer 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-nsview-create-destroy-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
PROBE_SOURCE="$OUTPUT_DIR/nsview_create_destroy_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/nsview_create_destroy_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked|cjgui_native_bridge_cametallayer_allocation_feasible|cjgui_native_bridge_cametallayer_allocation_requires_main_thread|cjgui_native_bridge_cametallayer_allocation_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_device_binding_blocked|cjgui_native_bridge_cametallayer_allocation_feasibility_probe|cjgui_native_bridge_cametallayer_table_capacity|cjgui_native_bridge_cametallayer_table_enabled|cjgui_native_bridge_cametallayer_table_empty|cjgui_native_bridge_cametallayer_table_token_classify|cjgui_native_bridge_cametallayer_table_allocation_still_blocked|cjgui_native_bridge_cametallayer_table_destroy_still_blocked|cjgui_native_bridge_cametallayer_create|cjgui_native_bridge_cametallayer_destroy|cjgui_native_bridge_cametallayer_token_classify|cjgui_native_bridge_cametallayer_table_occupied_count|cjgui_native_bridge_cametallayer_double_destroy_classify|cjgui_native_bridge_cametallayer_destroy_requires_main_thread|cjgui_native_bridge_cametallayer_attach_to_nsview|cjgui_native_bridge_cametallayer_detach_from_nsview|cjgui_native_bridge_cametallayer_attachment_classify|cjgui_native_bridge_cametallayer_double_detach_classify|cjgui_native_bridge_cametallayer_attach_requires_main_thread|cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked|cjgui_native_bridge_metal_import_available|cjgui_native_bridge_metal_default_device_available|cjgui_native_bridge_metal_device_no_command_queue_admission|cjgui_native_bridge_metal_device_creation_still_blocked|cjgui_native_bridge_metal_device_table_capacity|cjgui_native_bridge_metal_device_table_enabled|cjgui_native_bridge_metal_device_table_occupied_count|cjgui_native_bridge_metal_default_device_create|cjgui_native_bridge_metal_device_destroy|cjgui_native_bridge_metal_device_token_classify|cjgui_native_bridge_metal_device_double_destroy_classify|cjgui_native_bridge_metal_device_create_requires_main_thread|cjgui_native_bridge_metal_device_destroy_requires_main_thread|cjgui_native_bridge_metal_device_command_queue_still_blocked|cjgui_native_bridge_cametallayer_bind_metal_device|cjgui_native_bridge_cametallayer_unbind_metal_device|cjgui_native_bridge_cametallayer_device_binding_classify|cjgui_native_bridge_cametallayer_double_unbind_device_classify|cjgui_native_bridge_cametallayer_device_binding_requires_main_thread|cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked|cjgui_native_bridge_command_queue_table_capacity|cjgui_native_bridge_command_queue_table_enabled|cjgui_native_bridge_command_queue_table_occupied_count|cjgui_native_bridge_command_queue_create|cjgui_native_bridge_command_queue_destroy|cjgui_native_bridge_command_queue_token_classify|cjgui_native_bridge_command_queue_double_destroy_classify|cjgui_native_bridge_command_queue_create_requires_main_thread|cjgui_native_bridge_command_queue_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_creation_still_blocked|cjgui_native_bridge_command_buffer_table_capacity|cjgui_native_bridge_command_buffer_table_enabled|cjgui_native_bridge_command_buffer_table_occupied_count|cjgui_native_bridge_command_buffer_create|cjgui_native_bridge_command_buffer_destroy|cjgui_native_bridge_command_buffer_token_classify|cjgui_native_bridge_command_buffer_double_destroy_classify|cjgui_native_bridge_command_buffer_create_requires_main_thread|cjgui_native_bridge_command_buffer_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_commit_still_blocked|cjgui_native_bridge_command_buffer_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_table_capacity|cjgui_native_bridge_render_pass_descriptor_table_enabled|cjgui_native_bridge_render_pass_descriptor_table_occupied_count|cjgui_native_bridge_render_pass_descriptor_create|cjgui_native_bridge_render_pass_descriptor_destroy|cjgui_native_bridge_render_pass_descriptor_token_classify|cjgui_native_bridge_render_pass_descriptor_double_destroy_classify|cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked|cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked)$'
PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_pipeline_descriptor_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|configure_requires_main_thread|configure_no_draw|color_pixel_format_classify|sample_count_classify|shader_library_still_blocked|vertex_function_still_blocked|fragment_function_still_blocked|blending_still_blocked|encoder_binding_still_blocked)|cjgui_native_bridge_pipeline_state_creation_still_blocked)$'
SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_shader_(source_contract_available|library_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread)|function_(table_capacity|table_enabled|table_occupied_count|lookup_vertex|lookup_fragment|destroy|token_classify|double_destroy_classify|lookup_requires_main_thread|destroy_requires_main_thread|missing_classify)|pipeline_state_creation_still_blocked|encoder_binding_still_blocked|draw_still_blocked)|cjgui_native_bridge_pipeline_state_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|encoder_binding_still_blocked|draw_still_blocked))$'
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge nsview create/destroy probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge nsview create/destroy probe: missing production native bridge" >&2
  exit 3
fi
for symbol in \
  "cjgui_native_bridge_nsview_create" \
  "cjgui_native_bridge_nsview_destroy" \
  "cjgui_native_bridge_nsview_token_classify" \
  "cjgui_native_bridge_nsview_table_occupied_count" \
  "cjgui_native_bridge_nsview_double_destroy_classify" \
  "cjgui_native_bridge_nsview_destroy_requires_main_thread"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge nsview create/destroy probe: missing callable $symbol" >&2
    exit 4
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview create/destroy probe: forbidden framework import" >&2
  exit 5
fi
if grep -E '\[[[:space:]]*(NSWindow|NSApplication|CALayer)[[:space:]]+(alloc|new|init)\]|^[[:space:]]*(Class|id|void[[:space:]]*\*|uintptr_t)[[:space:]]+cjgui_|nextDrawable|commit\]|presentDrawable|present\]|__bridge|CFBridging' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview create/destroy probe: forbidden object / pointer / GPU token found" >&2
  exit 6
fi
while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge nsview create/destroy probe: callable outside allowlist: $callable_name" >&2
    exit 7
  fi
done < <(grep -Eoh 'cjgui_native_bridge_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')
if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge nsview create/destroy probe: clang not found" >&2
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
  echo "cjgui native bridge nsview create/destroy probe: SDKROOT not found" >&2
  exit 9
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_NSVIEW_CREATE_DESTROY_PROBE'
#import <pthread.h>
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"
typedef struct BackgroundResult {
    int32_t status;
    int32_t classify_after_attempt;
    uint64_t token;
} BackgroundResult;
static void *background_create(void *context) {
    BackgroundResult *result = (BackgroundResult *)context;
    uint64_t token = 0;
    result->status = cjgui_native_bridge_nsview_create(&token);
    result->token = token;
    return NULL;
}
static void *background_destroy(void *context) {
    BackgroundResult *result = (BackgroundResult *)context;
    result->status = cjgui_native_bridge_nsview_destroy(result->token);
    result->classify_after_attempt =
        cjgui_native_bridge_nsview_token_classify(result->token);
    return NULL;
}
int main(void) {
    printf("cjgui native bridge nsview create/destroy probe: requested=true\n");
    uint64_t token = 0;
    uint32_t occupied_before = cjgui_native_bridge_nsview_table_occupied_count();
    int32_t create_status = cjgui_native_bridge_nsview_create(&token);
    uint32_t occupied_after_create =
        cjgui_native_bridge_nsview_table_occupied_count();
    int32_t valid_classification =
        cjgui_native_bridge_nsview_token_classify(token);
    int32_t invalid_destroy_status = cjgui_native_bridge_nsview_destroy(0);
    int32_t requires_main_thread =
        cjgui_native_bridge_nsview_destroy_requires_main_thread();
    BackgroundResult background_destroy_result = {
        0,
        0,
        token
    };
    pthread_t destroy_thread;
    pthread_create(&destroy_thread, NULL, background_destroy,
        &background_destroy_result);
    pthread_join(destroy_thread, NULL);
    int32_t destroy_status = cjgui_native_bridge_nsview_destroy(token);
    uint32_t occupied_after_destroy =
        cjgui_native_bridge_nsview_table_occupied_count();
    int32_t destroyed_classification =
        cjgui_native_bridge_nsview_token_classify(token);
    int32_t double_destroy_status = cjgui_native_bridge_nsview_destroy(token);
    int32_t double_destroy_classification =
        cjgui_native_bridge_nsview_double_destroy_classify(token);
    BackgroundResult background_create_result = {
        0,
        0,
        0
    };
    pthread_t create_thread;
    pthread_create(&create_thread, NULL, background_create,
        &background_create_result);
    pthread_join(create_thread, NULL);
    int pointer_like_token = token >= 0x100000000ULL;
    int create_observed = create_status == 0 && token != 0;
    int valid_observed = valid_classification == 40;
    int occupied_observed =
        occupied_before == 0 && occupied_after_create == 1 &&
        occupied_after_destroy == 0;
    int background_destroy_denied =
        background_destroy_result.status == -41 &&
        background_destroy_result.classify_after_attempt == 40;
    int destroy_observed = destroy_status == 0;
    int destroyed_observed = destroyed_classification == -43;
    int double_destroy_observed =
        double_destroy_status == -46 &&
        double_destroy_classification == -46;
    int invalid_token_observed = invalid_destroy_status == -42;
    int background_create_denied =
        background_create_result.status == -40 &&
        background_create_result.token == 0;
    int requires_main_thread_observed = requires_main_thread == -41;
    int token_not_pointer_observed = pointer_like_token == 0;
    printf("cjgui native bridge nsview create/destroy probe: main_thread_create_observed=%s\n", create_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: token_classify_valid_observed=%s\n", valid_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: occupied_count_observed=%s\n", occupied_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: background_destroy_denied_observed=%s\n", background_destroy_denied ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: destroy_observed=%s\n", destroy_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: destroyed_stale_observed=%s\n", destroyed_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: double_destroy_fail_closed_observed=%s\n", double_destroy_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: invalid_token_fail_closed_observed=%s\n", invalid_token_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: background_create_denied_observed=%s\n", background_create_denied ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: destroy_requires_main_thread_observed=%s\n", requires_main_thread_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: token_not_pointer_observed=%s\n", token_not_pointer_observed ? "true" : "false");
    printf("cjgui native bridge nsview create/destroy probe: window_created=false\n");
    printf("cjgui native bridge nsview create/destroy probe: application_created=false\n");
    printf("cjgui native bridge nsview create/destroy probe: layer_created=false\n");
    printf("cjgui native bridge nsview create/destroy probe: metal_import_allowed=true\n");
    printf("cjgui native bridge nsview create/destroy probe: pointer_returned=false\n");
    printf("cjgui native bridge nsview create/destroy probe: native_handle_returned=false\n");
    int success = create_observed &&
        valid_observed &&
        occupied_observed &&
        background_destroy_denied &&
        destroy_observed &&
        destroyed_observed &&
        double_destroy_observed &&
        invalid_token_observed &&
        background_create_denied &&
        requires_main_thread_observed &&
        token_not_pointer_observed;
    if (success) {
        printf("cjgui native bridge nsview create/destroy probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge nsview create/destroy probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_NSVIEW_CREATE_DESTROY_PROBE
echo "cjgui native bridge nsview create/destroy probe: output=$OUTPUT_DIR"
echo "cjgui native bridge nsview create/destroy probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge nsview create/destroy probe: compiling production bridge"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -I "$NATIVE_DIR" \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -I "$NATIVE_DIR" \
  "$PROBE_SOURCE" \
  "$OBJECT_FILE" \
  -framework AppKit \
  -framework QuartzCore \
  -framework Metal \
  -o "$PROBE_EXECUTABLE"
"$PROBE_EXECUTABLE"
