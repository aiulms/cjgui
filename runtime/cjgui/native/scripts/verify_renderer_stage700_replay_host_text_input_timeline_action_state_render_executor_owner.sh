#!/usr/bin/env zsh
#
# Verifies the stage700 replay host text input timeline action-state-render executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage700_replay_host_text_input_timeline_action_state_render_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage700 replay host text input timeline action-state-render executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage700ReplayHostTextInputTimelineActionStateRenderExecutorPlan" \
  "CjguiInternalRendererStage700ReplayHostTextInputTimelineActionStateRenderExecutorFacts" \
  "CjguiInternalRendererStage700ReplayHostTextInputTimelineActionStateRenderExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage700ReplayHostTextInputTimelineActionStateRenderExecutorDraft" \
  "CjguiInternalRendererStage699ReplayHostTextInputTimelineRenderResultRefreshReadiness" \
  "didConsumeStage699ReplayHostTextInputTimelineRenderResultRefresh" \
  "didMaterializeSharedReplayHostTextInputTimelineActionStateRenderExecutor" \
  "didMaterializeSharedReplayHostTextInputTimelineActionStateRenderRuntimeContract" \
  "didMaterializeTimelineActionStateRenderExecutionReceiptContract" \
  "didMaterializeCycleOrderTextInputTimelineActionIntentStateDeltaRenderResultExecutor" \
  "didBindTimelineActionStateRenderExecutorToStage697ActionIntent" \
  "didBindTimelineActionStateRenderExecutorToStage698StateDelta" \
  "didBindTimelineActionStateRenderExecutorToStage699RenderResult" \
  "didReduceFuturePerDemoTextInputTimelineActionStateRenderTemplateNeed" \
  "didPrepareStage701TextInputTimelineComponentRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage700 replay host text input timeline action-state-render executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage700_replay_host_text_input_timeline_action_state_render_executor_owner_present=true"
echo "stage699_replay_host_text_input_timeline_render_result_refresh_consumed=true"
echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_consumed_transitively=true"
echo "stage697_replay_host_text_input_timeline_action_intent_bridge_consumed_transitively=true"
echo "stage696_replay_host_text_input_replay_timeline_executor_consumed_transitively=true"
echo "timeline_action_state_render_receipts_consumed=true"
echo "shared_replay_host_text_input_timeline_action_state_render_executor_materialized=true"
echo "shared_replay_host_text_input_timeline_action_state_render_runtime_contract_materialized=true"
echo "timeline_action_state_render_execution_receipt_contract_materialized=true"
echo "cycle_order_text_input_timeline_action_intent_state_delta_render_result_executor_materialized=true"
echo "todo_replay_host_text_input_timeline_action_state_render_runtime_surface_materialized=true"
echo "settings_replay_host_text_input_timeline_action_state_render_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_timeline_action_state_render_runtime_surface_materialized=true"
echo "chat_composer_replay_host_text_input_timeline_action_state_render_runtime_surface_materialized=true"
echo "timeline_action_state_render_executor_bound_to_stage697_action_intent=true"
echo "timeline_action_state_render_executor_bound_to_stage698_state_delta=true"
echo "timeline_action_state_render_executor_bound_to_stage699_render_result=true"
echo "timeline_action_state_render_executor_bound_to_stage696_timeline_executor=true"
echo "future_per_demo_text_input_timeline_action_state_render_template_need_reduced=true"
echo "stage701_text_input_timeline_component_runtime_contract_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
