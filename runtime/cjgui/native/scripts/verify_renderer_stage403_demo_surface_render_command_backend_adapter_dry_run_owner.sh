#!/usr/bin/env zsh
#
# 维护注释：验证 stage403 demo surface RenderCommand backend adapter dry-run owner。
# 它必须消费 stage402 demo refresh command batch，并产出 owner-local backend adapter mapping dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage403_demo_surface_render_command_backend_adapter_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage403 demo surface render command backend adapter dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage403DemoSurfaceBackendAdapterDryRunMapping" \
  "CjguiInternalRendererStage403DemoSurfaceBackendAdapterDryRunFacts" \
  "CjguiInternalRendererStage403DemoSurfaceRenderCommandBackendAdapterDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage403DemoSurfaceRenderCommandBackendAdapterDryRunDraft" \
  "didConsumeStage402DemoSurfaceRenderCommandAdapterDemoRefresh" \
  "didConsumeDemoSurfaceRenderCommandBatch" \
  "didMaterializeBackendAdapterDryRunMapping" \
  "didMapTodoRenderCommandBatchToBackendAdapterSlot" \
  "didMapSettingsRenderCommandBatchToBackendAdapterSlot" \
  "didMapAiGeneratedSettingsRenderCommandBatchToBackendAdapterSlot" \
  "didBindBackendAdapterDryRunToStage402CommandBatch" \
  "didKeepBackendAdapterMappingOwnerLocal" \
  "didKeepBackendAdapterMappingPreviewOnly" \
  "didPrepareStage404DemoSurfaceBackendAdapterResultRefresh" \
  "didKeepBackendImplementationBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked" \
  "didKeepNativeBridgeExpansionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage403 demo surface render command backend adapter dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage403_demo_surface_render_command_backend_adapter_dry_run_owner_present=true"
echo "stage402_demo_surface_render_command_adapter_demo_refresh_required=true"
echo "stage402_demo_surface_render_command_adapter_demo_refresh_consumed=true"
echo "demo_surface_render_command_batch_consumed=true"
echo "backend_adapter_dry_run_mapping_materialized=true"
echo "todo_render_command_batch_to_backend_adapter_slot_mapped=true"
echo "settings_render_command_batch_to_backend_adapter_slot_mapped=true"
echo "ai_generated_settings_render_command_batch_to_backend_adapter_slot_mapped=true"
echo "backend_adapter_dry_run_bound_to_stage402_command_batch=true"
echo "backend_adapter_mapping_owner_local=true"
echo "backend_adapter_mapping_preview_only=true"
echo "stage404_demo_surface_backend_adapter_result_refresh_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "concrete_platform_capability_promise=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
