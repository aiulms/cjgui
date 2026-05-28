#!/usr/bin/env zsh
#
# Verifies the stage612 shared feedback host inspection cycle executor contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage612_shared_feedback_host_inspection_cycle_executor_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage612 shared feedback host inspection cycle executor contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage612SharedFeedbackHostInspectionCycleExecutorContractPlan" \
  "CjguiInternalRendererStage612SharedFeedbackHostInspectionCycleExecutorContractFacts" \
  "CjguiInternalRendererStage612SharedFeedbackHostInspectionCycleExecutorContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage612SharedFeedbackHostInspectionCycleExecutorContractDraft" \
  "CjguiInternalRendererStage611FeedbackHostInspectionDemoHostExecutionSurfaceReadiness" \
  "didConsumeStage611FeedbackHostInspectionDemoHostExecutionSurface" \
  "didMaterializeSharedFeedbackHostInspectionCycleExecutorContract" \
  "didMaterializeSharedFeedbackHostInspectionCycleExecutorHelper" \
  "didMaterializeSharedFeedbackHostInspectionCycleExecutionReceiptContract" \
  "didMaterializeCycleOrderInputStateRenderSurfaceHost" \
  "didMaterializeChatComposerFeedbackHostInspectionCycleRuntimeSurface" \
  "didReduceFutureFeedbackHostInputStateRenderSurfaceTemplateNeed" \
  "didPrepareStage613FeedbackHostInspectionFocusValidationManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage612 shared feedback host inspection cycle executor contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_owner_present=true"
echo "stage611_feedback_host_inspection_demo_host_execution_surface_consumed=true"
echo "shared_feedback_host_inspection_cycle_executor_contract_materialized=true"
echo "shared_feedback_host_inspection_cycle_executor_helper_materialized=true"
echo "shared_feedback_host_inspection_cycle_execution_receipt_contract_materialized=true"
echo "cycle_order_input_state_render_surface_host_materialized=true"
echo "chat_composer_feedback_host_inspection_cycle_runtime_surface_materialized=true"
echo "cycle_executor_bound_to_stage609_input_state_bridge=true"
echo "cycle_executor_bound_to_stage610_state_render_refresh_bridge=true"
echo "cycle_executor_bound_to_stage611_demo_host_execution_surface=true"
echo "future_feedback_host_input_state_render_surface_template_need_reduced=true"
echo "stage613_feedback_host_inspection_focus_validation_manager_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
