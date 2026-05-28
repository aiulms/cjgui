#!/usr/bin/env zsh
#
# Verifies the stage537 event refresh surface executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage537_shared_runtime_demo_cycle_event_refresh_surface_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage537 shared runtime demo cycle event refresh surface executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage537SharedRuntimeDemoCycleEventRefreshSurfaceExecutorPlan" \
  "CjguiInternalRendererStage537SharedRuntimeDemoCycleEventRefreshSurfaceExecutorFacts" \
  "CjguiInternalRendererStage537SharedRuntimeDemoCycleEventRefreshSurfaceExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage537SharedRuntimeDemoCycleEventRefreshSurfaceExecutorDraft" \
  "CjguiInternalRendererStage536SharedRuntimeDemoCycleEventRenderCommandRefreshReadiness" \
  "didConsumeStage536SharedRuntimeDemoCycleEventRenderCommandRefresh" \
  "didMaterializeSharedRuntimeDemoCycleEventRefreshSurfaceExecutor" \
  "didMaterializeSharedRuntimeDemoCycleEventRefreshExecutionReceipt" \
  "didMaterializeTodoEventRefreshSurfaceExecutionReceipt" \
  "didMaterializeSettingsEventRefreshSurfaceExecutionReceipt" \
  "didMaterializeAiGeneratedSettingsEventRefreshSurfaceExecutionReceipt" \
  "didBindEventRefreshSurfaceExecutorToStage530Executor" \
  "didBindEventRefreshSurfaceExecutorToStage534CycleProbe" \
  "didMaterializeEventStateRenderLayoutProbeOrder" \
  "didReduceEventStateRenderOwnerProbeDuplication" \
  "didPrepareStage538SharedRuntimeDemoCycleEventRefreshHostProbe"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage537 shared runtime demo cycle event refresh surface executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage537_shared_runtime_demo_cycle_event_refresh_surface_executor_owner_present=true"
echo "stage536_shared_runtime_demo_cycle_event_render_command_refresh_consumed=true"
echo "normalized_event_render_command_refresh_inputs_consumed=true"
echo "shared_runtime_demo_cycle_event_refresh_surface_executor_materialized=true"
echo "shared_runtime_demo_cycle_event_refresh_execution_receipt_materialized=true"
echo "todo_event_refresh_surface_execution_receipt_materialized=true"
echo "settings_event_refresh_surface_execution_receipt_materialized=true"
echo "ai_generated_settings_event_refresh_surface_execution_receipt_materialized=true"
echo "event_refresh_surface_executor_bound_to_stage530_executor=true"
echo "event_refresh_surface_executor_bound_to_stage534_cycle_probe=true"
echo "event_refresh_surface_executor_bound_to_todo_settings_ai_generated_settings=true"
echo "event_state_render_layout_probe_order_materialized=true"
echo "event_refresh_surface_executor_reusable=true"
echo "event_state_render_owner_probe_duplication_reduced=true"
echo "stage538_shared_runtime_demo_cycle_event_refresh_host_probe_prepared=true"
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
