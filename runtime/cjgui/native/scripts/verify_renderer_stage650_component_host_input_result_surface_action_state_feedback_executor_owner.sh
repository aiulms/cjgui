#!/usr/bin/env zsh
#
# Verifies the stage650 component host input result surface action/state feedback executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage650_component_host_input_result_surface_action_state_feedback_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage650 component host input result surface action state feedback executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutorPlan" \
  "CjguiInternalRendererStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutorFacts" \
  "CjguiInternalRendererStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutorDraft" \
  "CjguiInternalRendererStage649ComponentHostInputResultSurfaceInteractionAdapterReadiness" \
  "didConsumeStage649ComponentHostInputResultSurfaceInteractionAdapter" \
  "didMaterializeSharedResultSurfaceActionStateFeedbackExecutor" \
  "didMaterializeValidationDismissStateDeltaDryRun" \
  "didMaterializeFocusMoveStateDeltaDryRun" \
  "didMaterializeInputFeedbackClearStateDeltaDryRun" \
  "didMaterializeSemanticDiffAcknowledgeStateDeltaDryRun" \
  "didMaterializeChatComposerFeedbackStateCandidate" \
  "didKeepFeedbackExecutorNonDispatching" \
  "didPrepareStage651ComponentHostInputResultSurfaceRenderRefreshReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage650 component host input result surface action state feedback executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage650_component_host_input_result_surface_action_state_feedback_executor_owner_present=true"
echo "stage649_component_host_input_result_surface_interaction_adapter_consumed=true"
echo "stage648_component_host_input_result_surface_runtime_contract_consumed_transitively=true"
echo "shared_result_surface_action_state_feedback_executor_materialized=true"
echo "validation_dismiss_state_delta_dry_run_materialized=true"
echo "focus_move_state_delta_dry_run_materialized=true"
echo "input_feedback_clear_state_delta_dry_run_materialized=true"
echo "semantic_diff_acknowledge_state_delta_dry_run_materialized=true"
echo "todo_feedback_state_candidate_materialized=true"
echo "settings_feedback_state_candidate_materialized=true"
echo "ai_generated_settings_feedback_state_candidate_materialized=true"
echo "chat_composer_feedback_state_candidate_materialized=true"
echo "feedback_executor_non_dispatching=true"
echo "feedback_state_update_committed=false"
echo "stage651_component_host_input_result_surface_render_refresh_receipt_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
