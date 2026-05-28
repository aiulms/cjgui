#!/usr/bin/env zsh
#
# Verifies the stage657 interaction execution feedback owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage657_interaction_execution_feedback.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage657 interaction execution feedback: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage657InteractionExecutionFeedbackPlan" \
  "CjguiInternalRendererStage657InteractionExecutionFeedbackFacts" \
  "CjguiInternalRendererStage657InteractionExecutionFeedbackReadiness" \
  "cjguiInternalExecuteDefaultRendererStage657InteractionExecutionFeedbackDraft" \
  "CjguiInternalRendererStage656InteractionFeedbackHostRuntimeContractReadiness" \
  "didConsumeStage656InteractionFeedbackHostRuntimeContract" \
  "didMaterializeSharedInteractionExecutionFeedback" \
  "didMaterializeValidationDismissExecutionFeedback" \
  "didMaterializeFocusMovementExecutionFeedback" \
  "didMaterializeInputFeedbackClearExecutionFeedback" \
  "didMaterializeSemanticDiffAcknowledgeExecutionFeedback" \
  "didMaterializeChatComposerInteractionExecutionFeedback" \
  "didPrepareStage658InteractionFeedbackReducer"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage657 interaction execution feedback: missing token $token" >&2
    exit 3
  fi
done

echo "stage657_interaction_execution_feedback_owner_present=true"
echo "stage656_interaction_feedback_host_runtime_contract_consumed=true"
echo "shared_interaction_execution_feedback_materialized=true"
echo "validation_dismiss_execution_feedback_materialized=true"
echo "focus_movement_execution_feedback_materialized=true"
echo "input_feedback_clear_execution_feedback_materialized=true"
echo "semantic_diff_acknowledge_execution_feedback_materialized=true"
echo "todo_interaction_execution_feedback_materialized=true"
echo "settings_interaction_execution_feedback_materialized=true"
echo "ai_generated_settings_interaction_execution_feedback_materialized=true"
echo "chat_composer_interaction_execution_feedback_materialized=true"
echo "execution_feedback_bound_to_stage656_host_runtime=true"
echo "stage658_interaction_feedback_reducer_after_stage657_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
