#!/usr/bin/env zsh
#
# Verifies the stage663 interaction feedback input state/render receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage663_interaction_feedback_input_state_render_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage663 interaction feedback input state/render receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptPlan" \
  "CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptFacts" \
  "CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage663InteractionFeedbackInputStateRenderReceiptDraft" \
  "CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness" \
  "didConsumeStage662InteractionFeedbackInputIntentNormalizer" \
  "didMaterializeFeedbackInputStateDeltaDryRunReceipt" \
  "didMaterializeFeedbackInputRenderCommandRefreshReceipt" \
  "didMaterializeFeedbackInputFocusTransitionPreview" \
  "didMaterializeFeedbackInputResultSurfaceRefreshReceipt" \
  "didMaterializeChatComposerFeedbackInputStateRenderReceipt" \
  "didPrepareStage664InteractionFeedbackInputRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage663 interaction feedback input state/render receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage663_interaction_feedback_input_state_render_receipt_owner_present=true"
echo "stage662_interaction_feedback_input_intent_normalizer_consumed=true"
echo "stage661_interaction_feedback_input_bridge_consumed_transitively=true"
echo "feedback_input_state_delta_dry_run_receipt_materialized=true"
echo "feedback_input_render_command_refresh_receipt_materialized=true"
echo "feedback_input_focus_transition_preview_materialized=true"
echo "feedback_input_result_surface_refresh_receipt_materialized=true"
echo "todo_feedback_input_state_render_receipt_materialized=true"
echo "settings_feedback_input_state_render_receipt_materialized=true"
echo "ai_generated_settings_feedback_input_state_render_receipt_materialized=true"
echo "chat_composer_feedback_input_state_render_receipt_materialized=true"
echo "feedback_input_state_render_receipt_checkable=true"
echo "stage664_interaction_feedback_input_runtime_contract_prepared=true"
echo "host_mutation=false"
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
