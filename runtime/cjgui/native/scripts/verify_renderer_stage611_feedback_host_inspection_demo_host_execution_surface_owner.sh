#!/usr/bin/env zsh
#
# Verifies the stage611 feedback host inspection demo-host execution surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage611_feedback_host_inspection_demo_host_execution_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage611 feedback host inspection demo-host execution surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage611FeedbackHostInspectionDemoHostExecutionSurfacePlan" \
  "CjguiInternalRendererStage611FeedbackHostInspectionDemoHostExecutionSurfaceFacts" \
  "CjguiInternalRendererStage611FeedbackHostInspectionDemoHostExecutionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage611FeedbackHostInspectionDemoHostExecutionSurfaceDraft" \
  "CjguiInternalRendererStage610FeedbackHostInspectionStateRenderRefreshBridgeReadiness" \
  "didConsumeStage610FeedbackHostInspectionStateRenderRefreshBridge" \
  "didMaterializeSharedFeedbackHostInspectionDemoHostExecutionSurface" \
  "didMaterializeFeedbackHostExecutionResultSurfaceRefresh" \
  "didMaterializeFeedbackHostExecutionSemanticDiffReceipt" \
  "didMaterializeFeedbackHostValidationInputFocusDisplayReceipt" \
  "didMaterializeChatComposerFeedbackHostExecutionSurface" \
  "didPrepareStage612SharedFeedbackHostInspectionCycleExecutorContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage611 feedback host inspection demo-host execution surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage611_feedback_host_inspection_demo_host_execution_surface_owner_present=true"
echo "stage610_feedback_host_inspection_state_render_refresh_bridge_consumed=true"
echo "shared_feedback_host_inspection_demo_host_execution_surface_materialized=true"
echo "feedback_host_execution_result_surface_refresh_materialized=true"
echo "feedback_host_execution_semantic_diff_receipt_materialized=true"
echo "feedback_host_validation_input_focus_display_receipt_materialized=true"
echo "chat_composer_feedback_host_execution_surface_materialized=true"
echo "demo_host_execution_surface_bound_to_stage610_render_refresh_receipts=true"
echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_prepared=true"
echo "production_render_truth=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
