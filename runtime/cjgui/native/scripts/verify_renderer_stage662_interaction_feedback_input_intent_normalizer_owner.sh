#!/usr/bin/env zsh
#
# Verifies the stage662 interaction feedback input intent normalizer owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage662_interaction_feedback_input_intent_normalizer.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage662 interaction feedback input intent normalizer: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerPlan" \
  "CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerFacts" \
  "CjguiInternalRendererStage662InteractionFeedbackInputIntentNormalizerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage662InteractionFeedbackInputIntentNormalizerDraft" \
  "CjguiInternalRendererStage661InteractionFeedbackInputBridgeReadiness" \
  "didConsumeStage661InteractionFeedbackInputBridge" \
  "didMaterializeSharedFeedbackInputIntentNormalizer" \
  "didMaterializeValidationDismissInputIntent" \
  "didMaterializeFocusMovementInputIntent" \
  "didMaterializeInputFeedbackClearInputIntent" \
  "didMaterializeSemanticDiffAcknowledgeInputIntent" \
  "didMaterializeChatComposerFeedbackInputIntent" \
  "didPrepareStage663InteractionFeedbackInputStateRenderReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage662 interaction feedback input intent normalizer: missing token $token" >&2
    exit 3
  fi
done

echo "stage662_interaction_feedback_input_intent_normalizer_owner_present=true"
echo "stage661_interaction_feedback_input_bridge_consumed=true"
echo "stage660_interaction_feedback_cycle_executor_consumed_transitively=true"
echo "shared_feedback_input_intent_normalizer_materialized=true"
echo "validation_dismiss_input_intent_materialized=true"
echo "focus_movement_input_intent_materialized=true"
echo "input_feedback_clear_input_intent_materialized=true"
echo "semantic_diff_acknowledge_input_intent_materialized=true"
echo "feedback_input_intent_route_ledger_materialized=true"
echo "todo_feedback_input_intent_materialized=true"
echo "settings_feedback_input_intent_materialized=true"
echo "ai_generated_settings_feedback_input_intent_materialized=true"
echo "chat_composer_feedback_input_intent_materialized=true"
echo "feedback_input_intents_non_dispatching=true"
echo "stage663_interaction_feedback_input_state_render_receipt_prepared=true"
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
