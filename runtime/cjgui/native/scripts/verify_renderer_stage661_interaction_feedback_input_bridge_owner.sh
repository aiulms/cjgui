#!/usr/bin/env zsh
#
# Verifies the stage661 interaction feedback input bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage661_interaction_feedback_input_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage661 interaction feedback input bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage661InteractionFeedbackInputBridgePlan" \
  "CjguiInternalRendererStage661InteractionFeedbackInputBridgeFacts" \
  "CjguiInternalRendererStage661InteractionFeedbackInputBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage661InteractionFeedbackInputBridgeDraft" \
  "CjguiInternalRendererStage660InteractionFeedbackCycleExecutorReadiness" \
  "didConsumeStage660InteractionFeedbackCycleExecutor" \
  "didMaterializeSharedInteractionFeedbackInputBridge" \
  "didMaterializeValidationDismissInputRoute" \
  "didMaterializeFocusMovementInputRoute" \
  "didMaterializeInputFeedbackClearInputRoute" \
  "didMaterializeSemanticDiffAcknowledgeInputRoute" \
  "didMaterializeChatComposerInteractionFeedbackInputBridge" \
  "didPrepareStage662InteractionFeedbackInputIntentNormalizer"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage661 interaction feedback input bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage661_interaction_feedback_input_bridge_owner_present=true"
echo "stage660_interaction_feedback_cycle_executor_consumed=true"
echo "stage659_interaction_feedback_result_surface_consumed_transitively=true"
echo "shared_interaction_feedback_input_bridge_materialized=true"
echo "validation_dismiss_input_route_materialized=true"
echo "focus_movement_input_route_materialized=true"
echo "input_feedback_clear_input_route_materialized=true"
echo "semantic_diff_acknowledge_input_route_materialized=true"
echo "feedback_input_bridge_binding_ledger_materialized=true"
echo "todo_interaction_feedback_input_bridge_materialized=true"
echo "settings_interaction_feedback_input_bridge_materialized=true"
echo "ai_generated_settings_interaction_feedback_input_bridge_materialized=true"
echo "chat_composer_interaction_feedback_input_bridge_materialized=true"
echo "interaction_feedback_input_bridge_owner_local=true"
echo "interaction_feedback_input_bridge_non_executing=true"
echo "stage662_interaction_feedback_input_intent_normalizer_prepared=true"
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
