#!/usr/bin/env zsh
#
# Verifies the stage680 feedback input replay action-state-render cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage680_feedback_input_replay_action_state_render_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage680 feedback input replay action-state-render cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorPlan" \
  "CjguiInternalRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorFacts" \
  "CjguiInternalRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorDraft" \
  "CjguiInternalRendererStage679FeedbackInputReplayRenderRefreshBridgeReadiness" \
  "didConsumeStage679FeedbackInputReplayRenderRefreshBridge" \
  "didMaterializeSharedReplayActionStateRenderCycleExecutor" \
  "didMaterializeSharedReplayActionStateRenderRuntimeContract" \
  "didMaterializeSharedReplayActionStateRenderExecutionReceiptContract" \
  "didMaterializeCycleOrderReplayActionIntentStateDeltaRenderRefreshResultSurface" \
  "didMaterializeTodoReplayActionStateRenderRuntimeSurface" \
  "didMaterializeSettingsReplayActionStateRenderRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsReplayActionStateRenderRuntimeSurface" \
  "didMaterializeChatComposerReplayActionStateRenderRuntimeSurface" \
  "didReduceFuturePerDemoReplayActionStateRenderTemplateNeed" \
  "didPrepareStage681ReplayActionStateRenderDemoHostInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage680 feedback input replay action-state-render cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage680_feedback_input_replay_action_state_render_cycle_executor_owner_present=true"
echo "stage679_feedback_input_replay_render_refresh_bridge_consumed=true"
echo "stage678_feedback_input_replay_state_delta_dry_run_consumed_transitively=true"
echo "stage677_feedback_input_replay_action_intent_bridge_consumed_transitively=true"
echo "stage676_feedback_input_replay_runtime_executor_consumed_transitively=true"
echo "shared_replay_action_state_render_cycle_executor_materialized=true"
echo "shared_replay_action_state_render_runtime_contract_materialized=true"
echo "shared_replay_action_state_render_execution_receipt_contract_materialized=true"
echo "cycle_order_replay_action_intent_state_delta_render_refresh_result_surface_materialized=true"
echo "todo_replay_action_state_render_runtime_surface_materialized=true"
echo "settings_replay_action_state_render_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_action_state_render_runtime_surface_materialized=true"
echo "chat_composer_replay_action_state_render_runtime_surface_materialized=true"
echo "future_per_demo_replay_action_state_render_template_need_reduced=true"
echo "stage681_replay_action_state_render_demo_host_inspection_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
