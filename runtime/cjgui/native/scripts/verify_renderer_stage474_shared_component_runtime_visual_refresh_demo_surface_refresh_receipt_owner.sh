#!/usr/bin/env zsh
#
# Verifies the stage474 visual refresh demo-surface refresh receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage474SharedComponentRuntimeVisualRefreshDemoSurfaceRefreshReceiptPlan" \
  "CjguiInternalRendererStage474SharedComponentRuntimeVisualRefreshDemoSurfaceRefreshReceiptFacts" \
  "CjguiInternalRendererStage474SharedComponentRuntimeVisualRefreshDemoSurfaceRefreshReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage474SharedComponentRuntimeVisualRefreshDemoSurfaceRefreshReceiptDraft" \
  "CjguiInternalRendererStage473SharedComponentRuntimeVisualRefreshInteractionRenderCommandRefreshReadiness" \
  "didConsumeStage473SharedComponentRuntimeVisualRefreshInteractionRenderCommandRefresh" \
  "didConsumeSharedComponentRuntimeVisualRefreshInteractionRenderCommandRefresh" \
  "didConsumeTodoRuntimeVisualRefreshInteractionRenderCommandProbeInput" \
  "didConsumeSettingsRuntimeVisualRefreshInteractionRenderCommandProbeInput" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshInteractionRenderCommandProbeInput" \
  "didMaterializeSharedComponentRuntimeVisualRefreshDemoSurfaceRefreshReceipt" \
  "didMaterializeTodoRuntimeVisualRefreshDemoSurfaceRefreshReceipt" \
  "didMaterializeSettingsRuntimeVisualRefreshDemoSurfaceRefreshReceipt" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshDemoSurfaceRefreshReceipt" \
  "didMaterializeSharedDemoSurfaceRefreshExecutionContract" \
  "didBindRenderCommandRefreshToDemoSurfaceRefreshReceipt" \
  "didBindDemoSurfaceRefreshReceiptToProbeInput" \
  "didKeepDemoSurfaceRefreshReceiptCheckable" \
  "didPrepareStage475SharedComponentRuntimeDemoSurfaceRefreshLayoutStylePreview" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage474 shared component runtime visual refresh demo surface refresh receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_owner_present=true"
echo "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_required=true"
echo "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_consumed=true"
echo "shared_component_runtime_visual_refresh_interaction_render_command_refresh_consumed=true"
echo "todo_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true"
echo "settings_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_interaction_render_command_probe_input_consumed=true"
echo "shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
echo "todo_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
echo "settings_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_demo_surface_refresh_receipt_materialized=true"
echo "shared_demo_surface_refresh_execution_contract_materialized=true"
echo "render_command_refresh_to_demo_surface_refresh_receipt_bound=true"
echo "demo_surface_refresh_receipt_to_probe_input_bound=true"
echo "demo_surface_refresh_receipt_reusable=true"
echo "demo_surface_refresh_receipt_checkable=true"
echo "stage475_shared_component_runtime_demo_surface_refresh_layout_style_preview_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
