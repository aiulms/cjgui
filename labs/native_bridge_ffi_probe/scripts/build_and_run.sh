#!/usr/bin/env zsh
#
# Owner: native bridge isolated no-resource C ABI FFI probe。
# Truth: 只验证仓颉 foreign 声明、direct cjc link 与 no-resource callable 的 deterministic result；production surface 可含已封账的 internal resource C ABI，但本 probe 不调用。
# Stop-line: 不修改 runtime/cjgui/cjpm.toml，不接 runtime FFI，不调用 resource callable，不创建 native object / command queue。
# Same-shape Boundary Brake: probe success 只是 FFI syntax/link evidence，不是 runtime bridge、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROBE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$PROBE_DIR/../.." && pwd)"
source "$SCRIPT_DIR/env.sh"

NATIVE_HEADER="$REPO_DIR/runtime/cjgui/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$REPO_DIR/runtime/cjgui/native/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-ffi-probe-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
STATIC_LIB="$OUTPUT_DIR/libcjgui_native_bridge_probe.a"
EXECUTABLE="$OUTPUT_DIR/native_bridge_ffi_probe"
# 维护说明：descriptor C ABI 只进入 isolated FFI 符号收敛清单，本 probe 仍只调用 no-resource callable。
ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_surface_version|cjgui_native_bridge_surface_capabilities|cjgui_native_bridge_status_ok|cjgui_native_bridge_no_resource_admission|cjgui_native_bridge_is_main_thread|cjgui_native_bridge_token_invalid|cjgui_native_bridge_token_table_capacity|cjgui_native_bridge_token_table_enabled|cjgui_native_bridge_token_classify|cjgui_native_bridge_token_issue|cjgui_native_bridge_token_revoke|cjgui_native_bridge_teardown_admission|cjgui_native_bridge_destroy_not_supported|cjgui_native_bridge_revoke_before_destroy_required|cjgui_native_bridge_double_destroy_classify|cjgui_native_bridge_appkit_import_available|cjgui_native_bridge_appkit_no_object_admission|cjgui_native_bridge_platform_object_create_still_blocked|cjgui_native_bridge_appkit_nswindow_class_available|cjgui_native_bridge_appkit_nsview_class_available|cjgui_native_bridge_appkit_class_lookup_no_object_admission|cjgui_native_bridge_platform_object_allocation_still_blocked|cjgui_native_bridge_appkit_platform_object_main_thread_required|cjgui_native_bridge_appkit_platform_object_main_thread_admitted|cjgui_native_bridge_appkit_platform_object_background_thread_denied|cjgui_native_bridge_appkit_platform_object_creation_still_blocked|cjgui_native_bridge_platform_object_create_no_object_admission|cjgui_native_bridge_platform_object_create_requires_main_thread|cjgui_native_bridge_platform_object_create_requires_token_contract|cjgui_native_bridge_platform_object_create_allocation_blocked|cjgui_native_bridge_nsview_table_capacity|cjgui_native_bridge_nsview_table_enabled|cjgui_native_bridge_nsview_table_empty|cjgui_native_bridge_nsview_table_token_classify|cjgui_native_bridge_nsview_table_allocation_still_blocked|cjgui_native_bridge_nsview_table_destroy_still_blocked|cjgui_native_bridge_nsview_create|cjgui_native_bridge_nsview_destroy|cjgui_native_bridge_nsview_token_classify|cjgui_native_bridge_nsview_table_occupied_count|cjgui_native_bridge_nsview_double_destroy_classify|cjgui_native_bridge_nsview_destroy_requires_main_thread|cjgui_native_bridge_quartzcore_import_available|cjgui_native_bridge_cametallayer_class_available|cjgui_native_bridge_cametallayer_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_still_blocked|cjgui_native_bridge_cametallayer_device_binding_still_blocked|cjgui_native_bridge_cametallayer_allocation_feasible|cjgui_native_bridge_cametallayer_allocation_requires_main_thread|cjgui_native_bridge_cametallayer_allocation_no_attach_admission|cjgui_native_bridge_cametallayer_allocation_device_binding_blocked|cjgui_native_bridge_cametallayer_allocation_feasibility_probe|cjgui_native_bridge_cametallayer_table_capacity|cjgui_native_bridge_cametallayer_table_enabled|cjgui_native_bridge_cametallayer_table_empty|cjgui_native_bridge_cametallayer_table_token_classify|cjgui_native_bridge_cametallayer_table_allocation_still_blocked|cjgui_native_bridge_cametallayer_table_destroy_still_blocked|cjgui_native_bridge_cametallayer_create|cjgui_native_bridge_cametallayer_destroy|cjgui_native_bridge_cametallayer_token_classify|cjgui_native_bridge_cametallayer_table_occupied_count|cjgui_native_bridge_cametallayer_double_destroy_classify|cjgui_native_bridge_cametallayer_destroy_requires_main_thread|cjgui_native_bridge_cametallayer_attach_to_nsview|cjgui_native_bridge_cametallayer_detach_from_nsview|cjgui_native_bridge_cametallayer_attachment_classify|cjgui_native_bridge_cametallayer_double_detach_classify|cjgui_native_bridge_cametallayer_attach_requires_main_thread|cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked|cjgui_native_bridge_metal_import_available|cjgui_native_bridge_metal_default_device_available|cjgui_native_bridge_metal_device_no_command_queue_admission|cjgui_native_bridge_metal_device_creation_still_blocked|cjgui_native_bridge_metal_device_table_capacity|cjgui_native_bridge_metal_device_table_enabled|cjgui_native_bridge_metal_device_table_occupied_count|cjgui_native_bridge_metal_default_device_create|cjgui_native_bridge_metal_device_destroy|cjgui_native_bridge_metal_device_token_classify|cjgui_native_bridge_metal_device_double_destroy_classify|cjgui_native_bridge_metal_device_create_requires_main_thread|cjgui_native_bridge_metal_device_destroy_requires_main_thread|cjgui_native_bridge_metal_device_command_queue_still_blocked|cjgui_native_bridge_cametallayer_bind_metal_device|cjgui_native_bridge_cametallayer_unbind_metal_device|cjgui_native_bridge_cametallayer_device_binding_classify|cjgui_native_bridge_cametallayer_double_unbind_device_classify|cjgui_native_bridge_cametallayer_device_binding_requires_main_thread|cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked|cjgui_native_bridge_command_queue_table_capacity|cjgui_native_bridge_command_queue_table_enabled|cjgui_native_bridge_command_queue_table_occupied_count|cjgui_native_bridge_command_queue_create|cjgui_native_bridge_command_queue_destroy|cjgui_native_bridge_command_queue_token_classify|cjgui_native_bridge_command_queue_double_destroy_classify|cjgui_native_bridge_command_queue_create_requires_main_thread|cjgui_native_bridge_command_queue_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_creation_still_blocked|cjgui_native_bridge_command_buffer_table_capacity|cjgui_native_bridge_command_buffer_table_enabled|cjgui_native_bridge_command_buffer_table_occupied_count|cjgui_native_bridge_command_buffer_create|cjgui_native_bridge_command_buffer_destroy|cjgui_native_bridge_command_buffer_token_classify|cjgui_native_bridge_command_buffer_double_destroy_classify|cjgui_native_bridge_command_buffer_create_requires_main_thread|cjgui_native_bridge_command_buffer_destroy_requires_main_thread|cjgui_native_bridge_command_buffer_commit_still_blocked|cjgui_native_bridge_command_buffer_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_table_capacity|cjgui_native_bridge_render_pass_descriptor_table_enabled|cjgui_native_bridge_render_pass_descriptor_table_occupied_count|cjgui_native_bridge_render_pass_descriptor_create|cjgui_native_bridge_render_pass_descriptor_destroy|cjgui_native_bridge_render_pass_descriptor_token_classify|cjgui_native_bridge_render_pass_descriptor_double_destroy_classify|cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread|cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked|cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked|cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked|cjgui_native_bridge_pipeline_descriptor_table_capacity|cjgui_native_bridge_pipeline_descriptor_table_enabled|cjgui_native_bridge_pipeline_descriptor_table_occupied_count|cjgui_native_bridge_pipeline_descriptor_create|cjgui_native_bridge_pipeline_descriptor_destroy|cjgui_native_bridge_pipeline_descriptor_token_classify|cjgui_native_bridge_pipeline_descriptor_double_destroy_classify|cjgui_native_bridge_pipeline_descriptor_create_requires_main_thread|cjgui_native_bridge_pipeline_descriptor_destroy_requires_main_thread|cjgui_native_bridge_pipeline_descriptor_configure_requires_main_thread|cjgui_native_bridge_pipeline_descriptor_configure_no_draw|cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify|cjgui_native_bridge_pipeline_descriptor_sample_count_classify|cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked|cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked|cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked|cjgui_native_bridge_pipeline_descriptor_blending_still_blocked|cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked|cjgui_native_bridge_pipeline_state_creation_still_blocked)$'
SHADER_LIBRARY_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_shader_(source_contract_available|library_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread)|function_(table_capacity|table_enabled|table_occupied_count|lookup_vertex|lookup_fragment|destroy|token_classify|double_destroy_classify|lookup_requires_main_thread|destroy_requires_main_thread|missing_classify)|pipeline_state_creation_still_blocked|encoder_binding_still_blocked|draw_still_blocked))'
# 维护说明：pipeline state C ABI 已封账为 no-draw lifecycle；本 isolated probe 只允许符号存在，不调用 pipeline state resource path。
PIPELINE_STATE_ALLOWED_CALLABLE_SYMBOL_REGEX='^_?(cjgui_native_bridge_pipeline_state_(table_capacity|table_enabled|table_occupied_count|create|destroy|token_classify|double_destroy_classify|create_requires_main_thread|destroy_requires_main_thread|encoder_binding_still_blocked|draw_still_blocked))'

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge ffi probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$NATIVE_HEADER" || ! -f "$NATIVE_SOURCE" ]]; then
  echo "cjgui native bridge ffi probe: missing production native skeleton" >&2
  exit 3
fi

# This source is now the real, narrow AppKit/Metal bridge used by CJGUI, so a
# blanket ban on framework imports or resource-oriented symbols would only
# reject the production implementation it is supposed to link.  The safety
# boundary here is instead positive and executable: `src/main.cj` imports and
# invokes only the five no-resource query functions below.  Their link and
# deterministic return values are checked after compiling this exact source;
# resource creation, queues, drawables, and app launch remain out of scope.
for required_symbol in \
  cjgui_native_bridge_surface_version \
  cjgui_native_bridge_surface_capabilities \
  cjgui_native_bridge_status_ok \
  cjgui_native_bridge_no_resource_admission \
  cjgui_native_bridge_is_main_thread; do
  if ! grep -Eq "${required_symbol}[[:space:]]*\\(" "$NATIVE_HEADER" ||
      ! grep -Eq "${required_symbol}[[:space:]]*\\(" "$NATIVE_SOURCE"; then
    echo "cjgui native bridge ffi probe: missing required no-resource symbol: $required_symbol" >&2
    exit 4
  fi
done

# Historical source-wide symbol lists above describe the former skeleton
# audit.  They cannot correctly classify a bridge that now intentionally
# owns bounded resource lifecycle APIs, and are not a security gate for this
# isolated probe.  The required-symbol check plus the direct foreign calls
# below are its maintained replacement.

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi

if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge ffi probe: clang not found" >&2
  exit 7
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge ffi probe: SDKROOT not found" >&2
  exit 8
fi

echo "cjgui native bridge ffi probe: output=$OUTPUT_DIR"
echo "cjgui native bridge ffi probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge ffi probe: compiling production skeleton object"

"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$NATIVE_SOURCE" \
  -o "$OBJECT_FILE"

ar rcs "$STATIC_LIB" "$OBJECT_FILE"

if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui native bridge ffi probe: cjc not found" >&2
  exit 9
fi

echo "cjgui native bridge ffi probe: compiling Cangjie foreign caller"

cjc "$PROBE_DIR/src/main.cj" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$OUTPUT_DIR" \
  -lcjgui_native_bridge_probe \
  --link-options "-framework AppKit -framework QuartzCore -framework Metal -lobjc" \
  -o "$EXECUTABLE"

"$EXECUTABLE"
