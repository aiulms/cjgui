#!/usr/bin/env zsh
#
# Owner: production native bridge no-resource symbol probe。
# Truth: 只验证 production skeleton object 中 no-resource callable C ABI 符号存在且 allowlist 收敛。
# Stop-line: 不修改源码或 build config，不接 cjpm / FFI，不执行 callable，不创建 native 对象。
# Same-shape Boundary Brake: symbol probe 只是 native surface evidence，不是 runtime-call、FFI、backend-ready 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-no-resource-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked|cjgui_native_bridge_cametallayer_allocation_feasible|cjgui_native_bridge_cametallayer_allocation_requires_main_thread|cjgui_native_bridge_cametallayer_allocation_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_device_binding_blocked|cjgui_native_bridge_cametallayer_allocation_feasibility_probe|cjgui_native_bridge_cametallayer_table_capacity|cjgui_native_bridge_cametallayer_table_enabled|cjgui_native_bridge_cametallayer_table_empty|cjgui_native_bridge_cametallayer_table_token_classify|cjgui_native_bridge_cametallayer_table_allocation_still_blocked|cjgui_native_bridge_cametallayer_table_destroy_still_blocked|cjgui_native_bridge_cametallayer_create|cjgui_native_bridge_cametallayer_destroy|cjgui_native_bridge_cametallayer_token_classify|cjgui_native_bridge_cametallayer_table_occupied_count|cjgui_native_bridge_cametallayer_double_destroy_classify|cjgui_native_bridge_cametallayer_destroy_requires_main_thread|cjgui_native_bridge_cametallayer_attach_to_nsview|cjgui_native_bridge_cametallayer_detach_from_nsview|cjgui_native_bridge_cametallayer_attachment_classify|cjgui_native_bridge_cametallayer_double_detach_classify|cjgui_native_bridge_cametallayer_attach_requires_main_thread|cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked|cjgui_native_bridge_metal_import_available|cjgui_native_bridge_metal_default_device_available|cjgui_native_bridge_metal_device_no_command_queue_admission|cjgui_native_bridge_metal_device_creation_still_blocked|cjgui_native_bridge_metal_device_table_capacity|cjgui_native_bridge_metal_device_table_enabled|cjgui_native_bridge_metal_device_table_occupied_count|cjgui_native_bridge_metal_default_device_create|cjgui_native_bridge_metal_device_destroy|cjgui_native_bridge_metal_device_token_classify|cjgui_native_bridge_metal_device_double_destroy_classify|cjgui_native_bridge_metal_device_create_requires_main_thread|cjgui_native_bridge_metal_device_destroy_requires_main_thread|cjgui_native_bridge_metal_device_command_queue_still_blocked|cjgui_native_bridge_cametallayer_bind_metal_device|cjgui_native_bridge_cametallayer_unbind_metal_device|cjgui_native_bridge_cametallayer_device_binding_classify|cjgui_native_bridge_cametallayer_double_unbind_device_classify|cjgui_native_bridge_cametallayer_device_binding_requires_main_thread|cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked|cjgui_native_bridge_command_queue_table_capacity|cjgui_native_bridge_command_queue_table_enabled|cjgui_native_bridge_command_queue_table_occupied_count|cjgui_native_bridge_command_queue_create|cjgui_native_bridge_command_queue_destroy|cjgui_native_bridge_command_queue_token_classify|cjgui_native_bridge_command_queue_double_destroy_classify|cjgui_native_bridge_command_queue_create_requires_main_thread|cjgui_native_bridge_command_queue_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_creation_still_blocked|cjgui_native_bridge_command_buffer_table_capacity|cjgui_native_bridge_command_buffer_table_enabled|cjgui_native_bridge_command_buffer_table_occupied_count|cjgui_native_bridge_command_buffer_create|cjgui_native_bridge_command_buffer_destroy|cjgui_native_bridge_command_buffer_token_classify|cjgui_native_bridge_command_buffer_double_destroy_classify|cjgui_native_bridge_command_buffer_create_requires_main_thread|cjgui_native_bridge_command_buffer_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_commit_still_blocked|cjgui_native_bridge_command_buffer_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_table_capacity|cjgui_native_bridge_render_pass_descriptor_table_enabled|cjgui_native_bridge_render_pass_descriptor_table_occupied_count|cjgui_native_bridge_render_pass_descriptor_create|cjgui_native_bridge_render_pass_descriptor_destroy|cjgui_native_bridge_render_pass_descriptor_token_classify|cjgui_native_bridge_render_pass_descriptor_double_destroy_classify|cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked|cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked)$'
EXPECTED_SYMBOLS=(
  "cjgui_native_bridge_surface_version"
  "cjgui_native_bridge_surface_capabilities"
  "cjgui_native_bridge_status_ok"
  "cjgui_native_bridge_no_resource_admission"
  "cjgui_native_bridge_is_main_thread"
  "cjgui_native_bridge_token_invalid"
  "cjgui_native_bridge_token_table_capacity"
  "cjgui_native_bridge_token_table_enabled"
  "cjgui_native_bridge_token_classify"
  "cjgui_native_bridge_token_issue"
  "cjgui_native_bridge_token_revoke"
  "cjgui_native_bridge_teardown_admission"
  "cjgui_native_bridge_destroy_not_supported"
  "cjgui_native_bridge_revoke_before_destroy_required"
  "cjgui_native_bridge_double_destroy_classify"
  "cjgui_native_bridge_appkit_import_available"
  "cjgui_native_bridge_appkit_no_object_admission"
  "cjgui_native_bridge_platform_object_create_still_blocked"
  "cjgui_native_bridge_appkit_nswindow_class_available"
  "cjgui_native_bridge_appkit_nsview_class_available"
  "cjgui_native_bridge_appkit_class_lookup_no_object_admission"
  "cjgui_native_bridge_platform_object_allocation_still_blocked"
  "cjgui_native_bridge_appkit_platform_object_main_thread_required"
  "cjgui_native_bridge_appkit_platform_object_main_thread_admitted"
  "cjgui_native_bridge_appkit_platform_object_background_thread_denied"
  "cjgui_native_bridge_appkit_platform_object_creation_still_blocked"
  "cjgui_native_bridge_platform_object_create_no_object_admission"
  "cjgui_native_bridge_platform_object_create_requires_main_thread"
  "cjgui_native_bridge_platform_object_create_requires_token_contract"
  "cjgui_native_bridge_platform_object_create_allocation_blocked"
  "cjgui_native_bridge_nsview_table_capacity"
  "cjgui_native_bridge_nsview_table_enabled"
  "cjgui_native_bridge_nsview_table_empty"
  "cjgui_native_bridge_nsview_table_token_classify"
  "cjgui_native_bridge_nsview_table_allocation_still_blocked"
  "cjgui_native_bridge_nsview_table_destroy_still_blocked"
  "cjgui_native_bridge_nsview_create"
  "cjgui_native_bridge_nsview_destroy"
  "cjgui_native_bridge_nsview_token_classify"
  "cjgui_native_bridge_nsview_table_occupied_count"
  "cjgui_native_bridge_nsview_double_destroy_classify"
  "cjgui_native_bridge_nsview_destroy_requires_main_thread"
  "cjgui_native_bridge_quartzcore_import_available"
  "cjgui_native_bridge_cametallayer_class_available"
  "cjgui_native_bridge_cametallayer_no_attach_admission"
  "cjgui_native_bridge_cametallayer_allocation_still_blocked"
  "cjgui_native_bridge_cametallayer_device_binding_still_blocked"
  "cjgui_native_bridge_cametallayer_allocation_feasible"
  "cjgui_native_bridge_cametallayer_allocation_requires_main_thread"
  "cjgui_native_bridge_cametallayer_allocation_no_attach_admission"
  "cjgui_native_bridge_cametallayer_allocation_device_binding_blocked"
  "cjgui_native_bridge_cametallayer_allocation_feasibility_probe"
  "cjgui_native_bridge_cametallayer_table_capacity"
  "cjgui_native_bridge_cametallayer_table_enabled"
  "cjgui_native_bridge_cametallayer_table_empty"
  "cjgui_native_bridge_cametallayer_table_token_classify"
  "cjgui_native_bridge_cametallayer_table_allocation_still_blocked"
  "cjgui_native_bridge_cametallayer_table_destroy_still_blocked"
  "cjgui_native_bridge_cametallayer_create"
  "cjgui_native_bridge_cametallayer_destroy"
  "cjgui_native_bridge_cametallayer_token_classify"
  "cjgui_native_bridge_cametallayer_table_occupied_count"
  "cjgui_native_bridge_cametallayer_double_destroy_classify"
  "cjgui_native_bridge_cametallayer_destroy_requires_main_thread"
  "cjgui_native_bridge_cametallayer_attach_to_nsview"
  "cjgui_native_bridge_cametallayer_detach_from_nsview"
  "cjgui_native_bridge_cametallayer_attachment_classify"
  "cjgui_native_bridge_cametallayer_double_detach_classify"
  "cjgui_native_bridge_cametallayer_attach_requires_main_thread"
  "cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked"
)
PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_pipeline_descriptor_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|configure_requires_main_thread|configure_no_draw|color_pixel_format_classify|sample_count_classify|shader_library_still_blocked|vertex_function_still_blocked|fragment_function_still_blocked|blending_still_blocked|encoder_binding_still_blocked)|cjgui_native_bridge_pipeline_state_creation_still_blocked)$'
SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_shader_(source_contract_available|library_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread)|function_(table_capacity|table_enabled|table_occupied_count|lookup_vertex|lookup_fragment|destroy|token_classify|double_destroy_classify|lookup_requires_main_thread|destroy_requires_main_thread|missing_classify)|pipeline_state_creation_still_blocked|encoder_binding_still_blocked|draw_still_blocked)|cjgui_native_bridge_pipeline_state_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|encoder_binding_still_blocked|draw_still_blocked))$'
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge no-resource symbols: macOS is required for Objective-C symbol probe" >&2
  exit 2
fi
if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge no-resource symbols: missing production native skeleton" >&2
  exit 3
fi
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource symbols: production skeleton must not import Cocoa / Metal frameworks" >&2
  exit 4
fi
if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSWindow|NSApplication|CALayer)[[:space:]]+(alloc|new)\]|(NSWindow|NSApplication|CALayer)[[:space:]]*\*|nextDrawable|commit\]|presentDrawable|present\]|\[[^]]+[[:space:]]+(retain|release)\]|CFRelease|CFRetain' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource symbols: production skeleton contains forbidden runtime/native behavior token" >&2
  exit 5
fi
while IFS= read -r callable_name; do
  if [[ -n "$callable_name" && ! "$callable_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$callable_name" =~ $SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
    echo "cjgui native bridge no-resource symbols: callable is outside allowlist: $callable_name" >&2
    exit 6
  fi
done < <(grep -Eoh 'cjgui_native_bridge_[A-Za-z0-9_]+[[:space:]]*\(' "$HEADER_FILE" "$SOURCE_FILE" 2>/dev/null | sed -E 's/[[:space:]]*[(]$//')
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
  echo "cjgui native bridge no-resource symbols: clang not found" >&2
  exit 7
fi
if [[ -z "${SDKROOT_VALUE:-}" || ! -d "$SDKROOT_VALUE" ]]; then
  echo "cjgui native bridge no-resource symbols: SDKROOT not found; set SDKROOT or install macOS SDK" >&2
  exit 8
fi
echo "cjgui native bridge no-resource symbols: source=$SOURCE_FILE"
echo "cjgui native bridge no-resource symbols: object=$OBJECT_FILE"
echo "cjgui native bridge no-resource symbols: sdkroot=$SDKROOT_VALUE"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$SDKROOT_VALUE" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"
if ! command -v nm >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource symbols: nm not found" >&2
  exit 9
fi
SYMBOL_LIST="$OUTPUT_DIR/cjgui_native_bridge.symbols"
while IFS= read -r symbol_name; do
  if [[ "$symbol_name" == _cjgui_* || "$symbol_name" == cjgui_* ]]; then
    if [[ ! "$symbol_name" =~ $ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$symbol_name" =~ $PIPELINE_DESCRIPTOR_ALLOWED_CALLABLE_SYMBOL_REGEX && ! "$symbol_name" =~ $SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX ]]; then
      echo "cjgui native bridge no-resource symbols: object exports forbidden symbol: $symbol_name" >&2
      exit 10
    fi
    echo "${symbol_name#_}" >> "$SYMBOL_LIST"
  fi
done < <(nm -g "$OBJECT_FILE" | awk '{print $NF}')
for expected_symbol in "${EXPECTED_SYMBOLS[@]}"; do
  if ! grep -Fx "$expected_symbol" "$SYMBOL_LIST" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource symbols: missing symbol $expected_symbol" >&2
    exit 11
  fi
done
echo "cjgui native bridge no-resource symbols: passed"
echo "cjgui native bridge no-resource symbols: no public API, no pointer return, no commit/present/render callable, no pointer-return public surface"
