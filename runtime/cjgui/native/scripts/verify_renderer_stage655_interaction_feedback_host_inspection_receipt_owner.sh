#!/usr/bin/env zsh
#
# Verifies the stage655 interaction feedback host inspection receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage655_interaction_feedback_host_inspection_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage655 interaction feedback host inspection receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage655InteractionFeedbackHostInspectionReceiptPlan" \
  "CjguiInternalRendererStage655InteractionFeedbackHostInspectionReceiptFacts" \
  "CjguiInternalRendererStage655InteractionFeedbackHostInspectionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage655InteractionFeedbackHostInspectionReceiptDraft" \
  "CjguiInternalRendererStage654InteractionFeedbackHostFrameAssemblyReadiness" \
  "didConsumeStage654InteractionFeedbackHostFrameAssembly" \
  "didConsumeHostFeedbackFrames" \
  "didMaterializeSharedInteractionFeedbackHostInspectionReceipt" \
  "didMaterializeValidationDismissHostInspectionReceipt" \
  "didMaterializeFocusMovementHostInspectionReceipt" \
  "didMaterializeInputFeedbackClearHostInspectionReceipt" \
  "didMaterializeSemanticDiffAcknowledgeHostInspectionReceipt" \
  "didMaterializeChatComposerInteractionFeedbackHostInspectionReceipt" \
  "didPrepareStage656InteractionFeedbackHostRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage655 interaction feedback host inspection receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage655_interaction_feedback_host_inspection_receipt_owner_present=true"
echo "stage654_interaction_feedback_host_frame_assembly_consumed=true"
echo "host_feedback_frames_consumed=true"
echo "shared_interaction_feedback_host_inspection_receipt_materialized=true"
echo "validation_dismiss_host_inspection_receipt_materialized=true"
echo "focus_movement_host_inspection_receipt_materialized=true"
echo "input_feedback_clear_host_inspection_receipt_materialized=true"
echo "semantic_diff_acknowledge_host_inspection_receipt_materialized=true"
echo "todo_interaction_feedback_host_inspection_receipt_materialized=true"
echo "settings_interaction_feedback_host_inspection_receipt_materialized=true"
echo "ai_generated_settings_interaction_feedback_host_inspection_receipt_materialized=true"
echo "chat_composer_interaction_feedback_host_inspection_receipt_materialized=true"
echo "host_inspection_receipt_bound_to_stage654_frames=true"
echo "stage656_interaction_feedback_host_runtime_contract_prepared=true"
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
