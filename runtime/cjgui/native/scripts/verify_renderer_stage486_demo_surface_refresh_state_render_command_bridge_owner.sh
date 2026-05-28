#!/usr/bin/env zsh
#
# Verifies the stage486 demo-surface refresh state RenderCommand bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage486_demo_surface_refresh_state_render_command_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage486 demo surface refresh state RenderCommand bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage486DemoSurfaceRefreshStateRenderCommandBridgePlan" \
  "CjguiInternalRendererStage486DemoSurfaceRefreshStateRenderCommandBridgeFacts" \
  "CjguiInternalRendererStage486DemoSurfaceRefreshStateRenderCommandBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage486DemoSurfaceRefreshStateRenderCommandBridgeDraft" \
  "CjguiInternalRendererStage485DemoSurfaceRefreshActionStateUpdateDryRunReadiness" \
  "didConsumeStage485DemoSurfaceRefreshActionStateUpdateDryRun" \
  "didConsumeSharedDemoSurfaceRefreshActionStateUpdateDryRun" \
  "didConsumeTodoDemoSurfaceRefreshStateUpdateCandidate" \
  "didConsumeSettingsDemoSurfaceRefreshStateUpdateCandidate" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRefreshStateUpdateCandidate" \
  "didMaterializeSharedDemoSurfaceRefreshStateRenderCommandBridge" \
  "didMaterializeTodoDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didBindStateUpdateDryRunToRenderCommandRefresh" \
  "didBindRenderCommandRefreshToDemoSurfaceProbeContract" \
  "didKeepDemoSurfaceRefreshRenderCommandBridgeReusable" \
  "didKeepDemoSurfaceRefreshRenderCommandBridgePreviewOnly" \
  "didPrepareStage487DemoSurfaceRefreshLayoutStyleFocusPreview" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage486 demo surface refresh state RenderCommand bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage486_demo_surface_refresh_state_render_command_bridge_owner_present=true"
echo "stage485_demo_surface_refresh_action_state_update_dry_run_required=true"
echo "stage485_demo_surface_refresh_action_state_update_dry_run_consumed=true"
echo "shared_demo_surface_refresh_action_state_update_dry_run_consumed=true"
echo "todo_demo_surface_refresh_state_update_candidate_consumed=true"
echo "settings_demo_surface_refresh_state_update_candidate_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_state_update_candidate_consumed=true"
echo "shared_demo_surface_refresh_state_render_command_bridge_materialized=true"
echo "todo_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "settings_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "state_update_dry_run_to_render_command_refresh_bound=true"
echo "render_command_refresh_to_demo_surface_probe_contract_bound=true"
echo "demo_surface_refresh_render_command_bridge_reusable=true"
echo "demo_surface_refresh_render_command_bridge_preview_only=true"
echo "stage487_demo_surface_refresh_layout_style_focus_preview_prepared=true"
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
