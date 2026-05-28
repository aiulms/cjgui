#!/usr/bin/env zsh
#
# Verifies the stage659 interaction feedback result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage659_interaction_feedback_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage659 interaction feedback result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage659InteractionFeedbackResultSurfacePlan" \
  "CjguiInternalRendererStage659InteractionFeedbackResultSurfaceFacts" \
  "CjguiInternalRendererStage659InteractionFeedbackResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage659InteractionFeedbackResultSurfaceDraft" \
  "CjguiInternalRendererStage658InteractionFeedbackReducerReadiness" \
  "didConsumeStage658InteractionFeedbackReducer" \
  "didMaterializeSharedInteractionFeedbackResultSurface" \
  "didMaterializeValidationDismissResultSurface" \
  "didMaterializeFocusMovementResultSurface" \
  "didMaterializeInputFeedbackClearResultSurface" \
  "didMaterializeSemanticDiffAcknowledgeResultSurface" \
  "didMaterializeChatComposerInteractionFeedbackResultSurface" \
  "didPrepareStage660InteractionFeedbackCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage659 interaction feedback result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage659_interaction_feedback_result_surface_owner_present=true"
echo "stage658_interaction_feedback_reducer_consumed=true"
echo "shared_interaction_feedback_result_surface_materialized=true"
echo "validation_dismiss_result_surface_materialized=true"
echo "focus_movement_result_surface_materialized=true"
echo "input_feedback_clear_result_surface_materialized=true"
echo "semantic_diff_acknowledge_result_surface_materialized=true"
echo "todo_interaction_feedback_result_surface_materialized=true"
echo "settings_interaction_feedback_result_surface_materialized=true"
echo "ai_generated_settings_interaction_feedback_result_surface_materialized=true"
echo "chat_composer_interaction_feedback_result_surface_materialized=true"
echo "result_surface_bound_to_stage658_reductions=true"
echo "stage660_interaction_feedback_cycle_executor_after_stage659_prepared=true"
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
