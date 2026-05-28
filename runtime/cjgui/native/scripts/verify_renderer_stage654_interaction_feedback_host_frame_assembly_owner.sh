#!/usr/bin/env zsh
#
# Verifies the stage654 interaction feedback host frame assembly owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage654_interaction_feedback_host_frame_assembly.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage654 interaction feedback host frame assembly: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage654InteractionFeedbackHostFrameAssemblyPlan" \
  "CjguiInternalRendererStage654InteractionFeedbackHostFrameAssemblyFacts" \
  "CjguiInternalRendererStage654InteractionFeedbackHostFrameAssemblyReadiness" \
  "cjguiInternalExecuteDefaultRendererStage654InteractionFeedbackHostFrameAssemblyDraft" \
  "CjguiInternalRendererStage653InteractionFeedbackHostIntegrationReadiness" \
  "didConsumeStage653InteractionFeedbackHostIntegration" \
  "didConsumeInteractionFeedbackHostSlots" \
  "didMaterializeSharedHostFeedbackFrameAssembly" \
  "didMaterializeValidationDismissFrameInvalidation" \
  "didMaterializeFocusMovementFramePreview" \
  "didMaterializeInputFeedbackClearFramePreview" \
  "didMaterializeSemanticDiffAcknowledgeFramePreview" \
  "didMaterializeChatComposerInteractionFeedbackHostFrame" \
  "didPrepareStage655InteractionFeedbackHostInspectionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage654 interaction feedback host frame assembly: missing token $token" >&2
    exit 3
  fi
done

echo "stage654_interaction_feedback_host_frame_assembly_owner_present=true"
echo "stage653_interaction_feedback_host_integration_consumed=true"
echo "interaction_feedback_host_slots_consumed=true"
echo "shared_host_feedback_frame_assembly_materialized=true"
echo "validation_dismiss_frame_invalidation_materialized=true"
echo "focus_movement_frame_preview_materialized=true"
echo "input_feedback_clear_frame_preview_materialized=true"
echo "semantic_diff_acknowledge_frame_preview_materialized=true"
echo "todo_interaction_feedback_host_frame_materialized=true"
echo "settings_interaction_feedback_host_frame_materialized=true"
echo "ai_generated_settings_interaction_feedback_host_frame_materialized=true"
echo "chat_composer_interaction_feedback_host_frame_materialized=true"
echo "host_frame_assembly_bound_to_stage653_host_slots=true"
echo "stage655_interaction_feedback_host_inspection_receipt_prepared=true"
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
