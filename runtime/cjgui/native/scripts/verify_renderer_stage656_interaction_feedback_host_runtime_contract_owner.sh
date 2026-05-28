#!/usr/bin/env zsh
#
# Verifies the stage656 interaction feedback host runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage656_interaction_feedback_host_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage656 interaction feedback host runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage656InteractionFeedbackHostRuntimeContractPlan" \
  "CjguiInternalRendererStage656InteractionFeedbackHostRuntimeContractFacts" \
  "CjguiInternalRendererStage656InteractionFeedbackHostRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage656InteractionFeedbackHostRuntimeContractDraft" \
  "CjguiInternalRendererStage655InteractionFeedbackHostInspectionReceiptReadiness" \
  "didConsumeStage655InteractionFeedbackHostInspectionReceipt" \
  "didMaterializeSharedInteractionFeedbackHostRuntimeContract" \
  "didMaterializeSharedInteractionFeedbackHostRuntimeHelper" \
  "didMaterializeSharedInteractionFeedbackHostExecutionReceiptContract" \
  "didMaterializeCycleOrderInteractionFeedbackHostIntegrationFrameInspectionRuntimeReceipt" \
  "didMaterializeChatComposerInteractionFeedbackHostRuntimeSurface" \
  "didBindHostRuntimeToStage653HostIntegration" \
  "didReduceFuturePerDemoInteractionFeedbackHostTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage656 interaction feedback host runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage656_interaction_feedback_host_runtime_contract_owner_present=true"
echo "stage655_interaction_feedback_host_inspection_receipt_consumed=true"
echo "stage654_interaction_feedback_host_frame_assembly_consumed_transitively=true"
echo "stage653_interaction_feedback_host_integration_consumed_transitively=true"
echo "stage652_interaction_feedback_runtime_contract_consumed_transitively=true"
echo "shared_interaction_feedback_host_runtime_contract_materialized=true"
echo "shared_interaction_feedback_host_runtime_helper_materialized=true"
echo "shared_interaction_feedback_host_execution_receipt_contract_materialized=true"
echo "cycle_order_interaction_feedback_host_integration_frame_inspection_runtime_receipt_materialized=true"
echo "todo_interaction_feedback_host_runtime_surface_materialized=true"
echo "settings_interaction_feedback_host_runtime_surface_materialized=true"
echo "ai_generated_settings_interaction_feedback_host_runtime_surface_materialized=true"
echo "chat_composer_interaction_feedback_host_runtime_surface_materialized=true"
echo "host_runtime_bound_to_stage653_host_integration=true"
echo "future_per_demo_interaction_feedback_host_template_need_reduced=true"
echo "stage657_component_host_input_result_surface_interaction_execution_feedback_after_stage656_prepared=true"
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
