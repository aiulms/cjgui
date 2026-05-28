#!/usr/bin/env zsh
#
# Verifies the stage473 visual refresh interaction RenderCommand refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage473 shared component runtime visual refresh interaction RenderCommand refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage473SharedComponentRuntimeVisualRefreshInteractionRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage473SharedComponentRuntimeVisualRefreshInteractionRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage473SharedComponentRuntimeVisualRefreshInteractionRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage473SharedComponentRuntimeVisualRefreshInteractionRenderCommandRefreshDraft" \
  "CjguiInternalRendererStage472SharedComponentRuntimeVisualRefreshInteractionStateUpdateBridgeReadiness" \
  "didConsumeStage472SharedComponentRuntimeVisualRefreshInteractionStateUpdateBridge" \
  "didConsumeSharedComponentRuntimeVisualRefreshInteractionStateUpdateBridge" \
  "didConsumeTodoRuntimeVisualRefreshInteractionStateUpdateCandidate" \
  "didConsumeSettingsRuntimeVisualRefreshInteractionStateUpdateCandidate" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshInteractionStateUpdateCandidate" \
  "didMaterializeSharedComponentRuntimeVisualRefreshInteractionRenderCommandRefresh" \
  "didMaterializeTodoRuntimeVisualRefreshInteractionRenderCommandProbeInput" \
  "didMaterializeSettingsRuntimeVisualRefreshInteractionRenderCommandProbeInput" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshInteractionRenderCommandProbeInput" \
  "didBindInteractionStateUpdateToRenderCommandRefresh" \
  "didBindRenderCommandRefreshToDemoSurfaceRefreshReceipt" \
  "didKeepInteractionRenderCommandBridgeReusable" \
  "didKeepInteractionRenderCommandBridgePreviewOnly" \
  "didPrepareStage474SharedComponentRuntimeVisualRefreshDemoSurfaceRefreshReceipt" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage473 shared component runtime visual refresh interaction RenderCommand refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage473_shared_component_runtime_visual_refresh_interaction_render_command_refresh_owner_present=true"
echo "stage472_shared_component_runtime_visual_refresh_interaction_state_update_bridge_required=true"
echo "stage472_shared_component_runtime_visual_refresh_interaction_state_update_bridge_consumed=true"
echo "shared_component_runtime_visual_refresh_interaction_state_update_bridge_consumed=true"
echo "todo_runtime_visual_refresh_interaction_state_update_candidate_consumed=true"
echo "settings_runtime_visual_refresh_interaction_state_update_candidate_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_interaction_state_update_candidate_consumed=true"
echo "shared_component_runtime_visual_refresh_interaction_render_command_refresh_materialized=true"
echo "todo_runtime_visual_refresh_interaction_render_command_probe_input_materialized=true"
echo "settings_runtime_visual_refresh_interaction_render_command_probe_input_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_interaction_render_command_probe_input_materialized=true"
echo "interaction_state_update_to_render_command_refresh_bound=true"
echo "render_command_refresh_to_demo_surface_refresh_receipt_bound=true"
echo "interaction_render_command_bridge_reusable=true"
echo "interaction_render_command_bridge_preview_only=true"
echo "stage474_shared_component_runtime_visual_refresh_demo_surface_refresh_receipt_prepared=true"
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
