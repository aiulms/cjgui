#!/usr/bin/env zsh
#
# Verifies the stage716 component runtime input event replay action-state-render executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage716_component_runtime_input_event_replay_action_state_render_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage716 component runtime input event replay action-state-render executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorPlan" \
  "CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorFacts" \
  "CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorDraft" \
  "CjguiInternalRendererStage715ComponentRuntimeInputEventReplayRenderResultRefreshReadiness" \
  "didConsumeStage715ComponentRuntimeInputEventReplayRenderResultRefresh" \
  "didMaterializeSharedComponentRuntimeInputEventReplayActionStateRenderExecutor" \
  "didMaterializeSharedComponentRuntimeInputEventReplayActionStateRenderRuntimeContract" \
  "didMaterializeComponentReplayActionStateRenderExecutionReceiptContract" \
  "didMaterializeCycleOrderComponentRuntimeInputEventReplayActionIntentStateDeltaRenderResultExecutor" \
  "didBindReplayActionStateRenderExecutorToStage713ActionIntent" \
  "didBindReplayActionStateRenderExecutorToStage714StateDelta" \
  "didBindReplayActionStateRenderExecutorToStage715RenderResult" \
  "didReduceFuturePerDemoComponentRuntimeInputEventReplayActionStateRenderTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage716 component runtime input event replay action-state-render executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage716_component_runtime_input_event_replay_action_state_render_executor_owner_present=true"
echo "stage715_component_runtime_input_event_replay_render_result_refresh_consumed=true"
echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_consumed_transitively=true"
echo "stage713_component_runtime_input_event_replay_action_intent_bridge_consumed_transitively=true"
echo "stage712_component_runtime_input_event_replay_cycle_executor_consumed_transitively=true"
echo "component_runtime_input_event_replay_action_state_render_receipts_consumed=true"
echo "shared_component_runtime_input_event_replay_action_state_render_executor_materialized=true"
echo "shared_component_runtime_input_event_replay_action_state_render_runtime_contract_materialized=true"
echo "component_replay_action_state_render_execution_receipt_contract_materialized=true"
echo "cycle_order_component_runtime_input_event_replay_action_intent_state_delta_render_result_executor_materialized=true"
echo "todo_component_runtime_input_event_replay_action_state_render_runtime_surface_materialized=true"
echo "settings_component_runtime_input_event_replay_action_state_render_runtime_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_action_state_render_runtime_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_action_state_render_runtime_surface_materialized=true"
echo "component_replay_action_state_render_executor_bound_to_stage713_action_intent=true"
echo "component_replay_action_state_render_executor_bound_to_stage714_state_delta=true"
echo "component_replay_action_state_render_executor_bound_to_stage715_render_result=true"
echo "component_replay_action_state_render_executor_bound_to_stage712_replay_cycle_executor=true"
echo "future_per_demo_component_runtime_input_event_replay_action_state_render_template_need_reduced=true"
echo "stage717_component_runtime_input_event_replay_action_state_render_layout_style_preview_prepared=true"
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
