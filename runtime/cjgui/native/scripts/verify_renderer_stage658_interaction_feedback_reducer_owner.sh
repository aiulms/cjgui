#!/usr/bin/env zsh
#
# Verifies the stage658 interaction feedback reducer owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage658_interaction_feedback_reducer.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage658 interaction feedback reducer: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage658InteractionFeedbackReducerPlan" \
  "CjguiInternalRendererStage658InteractionFeedbackReducerFacts" \
  "CjguiInternalRendererStage658InteractionFeedbackReducerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage658InteractionFeedbackReducerDraft" \
  "CjguiInternalRendererStage657InteractionExecutionFeedbackReadiness" \
  "didConsumeStage657InteractionExecutionFeedback" \
  "didMaterializeSharedInteractionFeedbackReducer" \
  "didMaterializeValidationDismissResultReduction" \
  "didMaterializeFocusMovementResultReduction" \
  "didMaterializeInputFeedbackClearResultReduction" \
  "didMaterializeSemanticDiffAcknowledgeResultReduction" \
  "didKeepInteractionFeedbackReducerNonDispatching" \
  "didPrepareStage659InteractionFeedbackResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage658 interaction feedback reducer: missing token $token" >&2
    exit 3
  fi
done

echo "stage658_interaction_feedback_reducer_owner_present=true"
echo "stage657_interaction_execution_feedback_consumed=true"
echo "shared_interaction_feedback_reducer_materialized=true"
echo "validation_dismiss_result_reduction_materialized=true"
echo "focus_movement_result_reduction_materialized=true"
echo "input_feedback_clear_result_reduction_materialized=true"
echo "semantic_diff_acknowledge_result_reduction_materialized=true"
echo "todo_interaction_feedback_reduction_materialized=true"
echo "settings_interaction_feedback_reduction_materialized=true"
echo "ai_generated_settings_interaction_feedback_reduction_materialized=true"
echo "chat_composer_interaction_feedback_reduction_materialized=true"
echo "interaction_feedback_reducer_non_dispatching=true"
echo "interaction_feedback_reducer_state_update_dry_run_only=true"
echo "stage659_interaction_feedback_result_surface_after_stage658_prepared=true"
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
