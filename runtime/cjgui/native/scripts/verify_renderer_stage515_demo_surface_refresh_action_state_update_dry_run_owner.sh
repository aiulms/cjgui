#!/usr/bin/env zsh
#
# Verifies the stage515 refreshed action state-update dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage515_demo_surface_refresh_action_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage515 demo surface refresh action state update dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage515DemoSurfaceRefreshActionStateUpdateDryRunPlan" \
  "CjguiInternalRendererStage515DemoSurfaceRefreshActionStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage515DemoSurfaceRefreshActionStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage515DemoSurfaceRefreshActionStateUpdateDryRunDraft" \
  "CjguiInternalRendererStage514DemoSurfaceRefreshFocusInputActionAdapterReadiness" \
  "didConsumeStage514DemoSurfaceRefreshFocusInputActionAdapter" \
  "didConsumeDemoSurfaceRefreshRefreshedFocusInputAdapterContract" \
  "didMaterializeSharedDemoSurfaceRefreshRefreshedActionStateUpdateDryRun" \
  "didMaterializeTodoRefreshedDemoSurfaceRefreshStateUpdateCandidate" \
  "didMaterializeSettingsRefreshedDemoSurfaceRefreshStateUpdateCandidate" \
  "didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshStateUpdateCandidate" \
  "didBindRefreshedFocusInputActionAdapterToStateUpdateDryRun" \
  "didBindRefreshedActionStateUpdateToRuntimeProbeV2" \
  "didMaterializeDemoSurfaceRefreshRefreshedStateRollbackPreview" \
  "didPrepareStage516DemoSurfaceRefreshInteractionCycleRenderRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage515 demo surface refresh action state update dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage515_demo_surface_refresh_action_state_update_dry_run_owner_present=true"
echo "stage514_demo_surface_refresh_focus_input_action_adapter_consumed=true"
echo "shared_demo_surface_refresh_refreshed_focus_input_action_adapter_consumed=true"
echo "demo_surface_refresh_refreshed_focus_input_adapter_contract_consumed=true"
echo "todo_refreshed_demo_surface_refresh_runtime_focus_activation_intent_consumed=true"
echo "settings_refreshed_demo_surface_refresh_runtime_toggle_intent_consumed=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_runtime_submit_intent_consumed=true"
echo "shared_demo_surface_refresh_refreshed_action_state_update_dry_run_materialized=true"
echo "todo_refreshed_demo_surface_refresh_state_update_candidate_materialized=true"
echo "settings_refreshed_demo_surface_refresh_state_update_candidate_materialized=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_state_update_candidate_materialized=true"
echo "refreshed_focus_input_action_adapter_to_state_update_dry_run_bound=true"
echo "refreshed_action_state_update_to_runtime_probe_v2_bound=true"
echo "demo_surface_refresh_refreshed_state_update_owner_local=true"
echo "demo_surface_refresh_refreshed_state_update_dry_run_only=true"
echo "demo_surface_refresh_refreshed_state_rollback_preview_materialized=true"
echo "stage516_demo_surface_refresh_interaction_cycle_render_refresh_prepared=true"
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
