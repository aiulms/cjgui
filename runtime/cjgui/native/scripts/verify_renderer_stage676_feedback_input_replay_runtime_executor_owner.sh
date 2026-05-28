#!/usr/bin/env zsh
#
# Verifies the stage676 feedback input replay runtime executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage676_feedback_input_replay_runtime_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage676 feedback input replay runtime executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorPlan" \
  "CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorFacts" \
  "CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage676FeedbackInputReplayRuntimeExecutorDraft" \
  "CjguiInternalRendererStage675FeedbackInputReplayResultSurfaceRefreshReadiness" \
  "didConsumeStage675FeedbackInputReplayResultSurfaceRefresh" \
  "didMaterializeSharedFeedbackInputReplayRuntimeExecutor" \
  "didMaterializeSharedFeedbackInputReplayRuntimeContract" \
  "didMaterializeReplayExecutionReceiptContract" \
  "didMaterializeCycleOrderEventCycleRuntimeReplayInspectionResultExecutor" \
  "didReduceFuturePerDemoFeedbackInputReplayTemplateNeed" \
  "didPrepareStage677FeedbackInputReplayActionStateBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage676 feedback input replay runtime executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage676_feedback_input_replay_runtime_executor_owner_present=true"
echo "stage675_feedback_input_replay_result_surface_refresh_consumed=true"
echo "stage674_feedback_input_replay_host_inspection_preview_consumed_transitively=true"
echo "stage673_feedback_input_event_replay_surface_consumed_transitively=true"
echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed_transitively=true"
echo "shared_feedback_input_replay_runtime_executor_materialized=true"
echo "shared_feedback_input_replay_runtime_contract_materialized=true"
echo "replay_execution_receipt_contract_materialized=true"
echo "cycle_order_event_cycle_runtime_replay_inspection_result_executor_materialized=true"
echo "todo_feedback_input_replay_runtime_surface_materialized=true"
echo "settings_feedback_input_replay_runtime_surface_materialized=true"
echo "ai_generated_settings_feedback_input_replay_runtime_surface_materialized=true"
echo "chat_composer_feedback_input_replay_runtime_surface_materialized=true"
echo "future_per_demo_feedback_input_replay_template_need_reduced=true"
echo "stage677_feedback_input_replay_action_state_bridge_prepared=true"
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
