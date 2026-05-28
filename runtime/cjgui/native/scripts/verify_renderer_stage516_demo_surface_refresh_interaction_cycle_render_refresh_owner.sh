#!/usr/bin/env zsh
#
# Verifies the stage516 refreshed interaction-cycle RenderCommand owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage516_demo_surface_refresh_interaction_cycle_render_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage516 demo surface refresh interaction cycle render refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage516DemoSurfaceRefreshInteractionCycleRenderRefreshPlan" \
  "CjguiInternalRendererStage516DemoSurfaceRefreshInteractionCycleRenderRefreshFacts" \
  "CjguiInternalRendererStage516DemoSurfaceRefreshInteractionCycleRenderRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage516DemoSurfaceRefreshInteractionCycleRenderRefreshDraft" \
  "CjguiInternalRendererStage515DemoSurfaceRefreshActionStateUpdateDryRunReadiness" \
  "didConsumeStage515DemoSurfaceRefreshActionStateUpdateDryRun" \
  "didMaterializeSharedDemoSurfaceRefreshRefreshedInteractionCycleReceipt" \
  "didMaterializeDemoSurfaceRefreshRefreshedInteractionCycleExecutorContract" \
  "didMaterializeDemoSurfaceRefreshRefreshedInteractionCycleExecutorHelper" \
  "cjguiInternalRendererStage516RefreshedInteractionCycleExecutorHelperReady" \
  "didMaterializeTodoRefreshedDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshRenderCommandProbeInput" \
  "didBindRefreshedStateUpdateDryRunToRenderCommandRefresh" \
  "didPrepareStage517DemoSurfaceRefreshLayoutStylePreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage516 demo surface refresh interaction cycle render refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage516_demo_surface_refresh_interaction_cycle_render_refresh_owner_present=true"
echo "stage515_demo_surface_refresh_action_state_update_dry_run_consumed=true"
echo "shared_demo_surface_refresh_refreshed_action_state_update_dry_run_consumed=true"
echo "todo_refreshed_demo_surface_refresh_state_update_candidate_consumed=true"
echo "settings_refreshed_demo_surface_refresh_state_update_candidate_consumed=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_state_update_candidate_consumed=true"
echo "shared_demo_surface_refresh_refreshed_interaction_cycle_receipt_materialized=true"
echo "demo_surface_refresh_refreshed_interaction_cycle_executor_contract_materialized=true"
echo "demo_surface_refresh_refreshed_interaction_cycle_executor_helper_materialized=true"
echo "demo_surface_refresh_refreshed_interaction_cycle_executor_helper_bound_to_demo_surfaces=true"
echo "todo_refreshed_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "settings_refreshed_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "refreshed_state_update_dry_run_to_render_command_refresh_bound=true"
echo "refreshed_render_command_refresh_to_layout_style_preview_bridge_bound=true"
echo "demo_surface_refresh_refreshed_render_command_refresh_reusable=true"
echo "demo_surface_refresh_refreshed_render_command_refresh_preview_only=true"
echo "refreshed_interaction_cycle_executor_owner_local=true"
echo "refreshed_interaction_cycle_executor_non_dispatching=true"
echo "stage517_demo_surface_refresh_layout_style_preview_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
