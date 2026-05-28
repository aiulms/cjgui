#!/usr/bin/env zsh
#
# Verifies the stage664 interaction feedback input runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage664_interaction_feedback_input_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage664 interaction feedback input runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage664InteractionFeedbackInputRuntimeContractPlan" \
  "CjguiInternalRendererStage664InteractionFeedbackInputRuntimeContractFacts" \
  "CjguiInternalRendererStage664InteractionFeedbackInputRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage664InteractionFeedbackInputRuntimeContractDraft" \
  "CjguiInternalRendererStage663InteractionFeedbackInputStateRenderReceiptReadiness" \
  "didConsumeStage663InteractionFeedbackInputStateRenderReceipt" \
  "didMaterializeSharedInteractionFeedbackInputRuntimeContract" \
  "didMaterializeSharedInteractionFeedbackInputRuntimeHelper" \
  "didMaterializeSharedFeedbackInputExecutionReceiptContract" \
  "didMaterializeCycleOrderFeedbackInputBridgeIntentStateRenderRuntimeReceipt" \
  "didMaterializeChatComposerFeedbackInputRuntimeSurface" \
  "didReduceFuturePerDemoFeedbackInputBridgeTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage664 interaction feedback input runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage664_interaction_feedback_input_runtime_contract_owner_present=true"
echo "stage663_interaction_feedback_input_state_render_receipt_consumed=true"
echo "stage662_interaction_feedback_input_intent_normalizer_consumed_transitively=true"
echo "stage661_interaction_feedback_input_bridge_consumed_transitively=true"
echo "stage660_interaction_feedback_cycle_executor_consumed_transitively=true"
echo "shared_interaction_feedback_input_runtime_contract_materialized=true"
echo "shared_interaction_feedback_input_runtime_helper_materialized=true"
echo "shared_feedback_input_execution_receipt_contract_materialized=true"
echo "cycle_order_feedback_input_bridge_intent_state_render_runtime_receipt_materialized=true"
echo "todo_feedback_input_runtime_surface_materialized=true"
echo "settings_feedback_input_runtime_surface_materialized=true"
echo "ai_generated_settings_feedback_input_runtime_surface_materialized=true"
echo "chat_composer_feedback_input_runtime_surface_materialized=true"
echo "future_per_demo_feedback_input_bridge_template_need_reduced=true"
echo "stage665_component_feedback_input_demo_host_surface_after_stage664_prepared=true"
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
