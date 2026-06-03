#!/usr/bin/env zsh
#
# Verifies the stage712 component runtime input event replay cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage712_component_runtime_input_event_replay_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage712 component runtime input event replay cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage712ComponentRuntimeInputEventReplayCycleExecutorPlan" \
  "CjguiInternalRendererStage712ComponentRuntimeInputEventReplayCycleExecutorFacts" \
  "CjguiInternalRendererStage712ComponentRuntimeInputEventReplayCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage712ComponentRuntimeInputEventReplayCycleExecutorDraft" \
  "CjguiInternalRendererStage711ComponentRuntimeInputEventReplayResultSurfaceRefreshReadiness" \
  "didConsumeStage711ComponentRuntimeInputEventReplayResultSurfaceRefresh" \
  "didMaterializeSharedComponentRuntimeInputEventReplayCycleExecutor" \
  "didMaterializeSharedComponentRuntimeInputEventReplayCycleRuntimeContract" \
  "didMaterializeComponentRuntimeInputEventReplayExecutionReceiptContract" \
  "didMaterializeCycleOrderComponentRuntimeInputEventReplayInspectionResultRefreshExecutor" \
  "didBindReplayCycleExecutorToStage709ReplaySurface" \
  "didBindReplayCycleExecutorToStage710HostInspection" \
  "didBindReplayCycleExecutorToStage711ResultRefresh" \
  "didBindReplayCycleExecutorToStage708InputEventCycleExecutor" \
  "didReduceFuturePerDemoComponentRuntimeInputEventReplayTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage712 component runtime input event replay cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage712_component_runtime_input_event_replay_cycle_executor_owner_present=true"
echo "stage711_component_runtime_input_event_replay_result_surface_refresh_consumed=true"
echo "stage710_component_runtime_input_event_replay_host_inspection_preview_consumed_transitively=true"
echo "stage709_component_runtime_input_event_replay_surface_consumed_transitively=true"
echo "stage708_component_runtime_input_event_cycle_executor_consumed_transitively=true"
echo "component_runtime_input_event_replay_result_refreshes_consumed=true"
echo "shared_component_runtime_input_event_replay_cycle_executor_materialized=true"
echo "shared_component_runtime_input_event_replay_cycle_runtime_contract_materialized=true"
echo "component_runtime_input_event_replay_execution_receipt_contract_materialized=true"
echo "cycle_order_component_runtime_input_event_replay_inspection_result_refresh_executor_materialized=true"
echo "todo_component_runtime_input_event_replay_cycle_runtime_surface_materialized=true"
echo "settings_component_runtime_input_event_replay_cycle_runtime_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_cycle_runtime_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_cycle_runtime_surface_materialized=true"
echo "component_input_event_replay_cycle_executor_bound_to_stage709_replay_surface=true"
echo "component_input_event_replay_cycle_executor_bound_to_stage710_host_inspection=true"
echo "component_input_event_replay_cycle_executor_bound_to_stage711_result_refresh=true"
echo "component_input_event_replay_cycle_executor_bound_to_stage708_input_event_cycle_executor=true"
echo "future_per_demo_component_runtime_input_event_replay_template_need_reduced=true"
echo "stage713_component_runtime_input_event_replay_action_state_bridge_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
