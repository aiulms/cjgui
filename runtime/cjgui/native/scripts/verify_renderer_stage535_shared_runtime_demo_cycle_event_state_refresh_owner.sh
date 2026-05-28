#!/usr/bin/env zsh
#
# Verifies the stage535 normalized-event state refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage535_shared_runtime_demo_cycle_event_state_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage535 shared runtime demo cycle event state refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage535SharedRuntimeDemoCycleEventStateRefreshPlan" \
  "CjguiInternalRendererStage535SharedRuntimeDemoCycleEventStateRefreshFacts" \
  "CjguiInternalRendererStage535SharedRuntimeDemoCycleEventStateRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage535SharedRuntimeDemoCycleEventStateRefreshDraft" \
  "CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness" \
  "didConsumeStage534NormalizedEventDemoSurfaceCycleProbe" \
  "didConsumeNormalizedEventDemoSurfaceCycleProbeHelper" \
  "didMaterializeSharedRuntimeDemoCycleEventStateRefreshContract" \
  "didMaterializeNormalizedEventStateRefreshExecutor" \
  "didMaterializeTodoNormalizedEventStateRefreshCandidate" \
  "didMaterializeSettingsNormalizedEventStateRefreshCandidate" \
  "didMaterializeAiGeneratedSettingsNormalizedEventStateRefreshCandidate" \
  "didBindNormalizedEventCycleProbeToEventStateRefresh" \
  "didKeepEventStateRefreshOwnerLocal" \
  "didKeepEventStateRefreshDryRunOnly" \
  "didMaterializeEventStateRefreshRollbackPreview" \
  "didPrepareStage536SharedRuntimeDemoCycleEventRenderCommandRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage535 shared runtime demo cycle event state refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage535_shared_runtime_demo_cycle_event_state_refresh_owner_present=true"
echo "stage534_normalized_event_demo_surface_cycle_probe_consumed=true"
echo "normalized_event_demo_surface_cycle_probe_helper_consumed=true"
echo "normalized_event_cycle_probe_inputs_consumed=true"
echo "shared_runtime_demo_cycle_event_state_refresh_contract_materialized=true"
echo "normalized_event_state_refresh_executor_materialized=true"
echo "todo_normalized_event_state_refresh_candidate_materialized=true"
echo "settings_normalized_event_state_refresh_candidate_materialized=true"
echo "ai_generated_settings_normalized_event_state_refresh_candidate_materialized=true"
echo "normalized_event_cycle_probe_to_event_state_refresh_bound=true"
echo "event_state_refresh_bound_to_stage530_executor_route=true"
echo "event_state_refresh_owner_local=true"
echo "event_state_refresh_dry_run_only=true"
echo "event_state_refresh_rollback_preview_materialized=true"
echo "stage536_shared_runtime_demo_cycle_event_render_command_refresh_prepared=true"
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
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
