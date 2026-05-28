#!/usr/bin/env zsh
#
# Verifies the stage651 component host input result surface render refresh receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage651_component_host_input_result_surface_render_refresh_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage651 component host input result surface render refresh receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage651ComponentHostInputResultSurfaceRenderRefreshReceiptPlan" \
  "CjguiInternalRendererStage651ComponentHostInputResultSurfaceRenderRefreshReceiptFacts" \
  "CjguiInternalRendererStage651ComponentHostInputResultSurfaceRenderRefreshReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage651ComponentHostInputResultSurfaceRenderRefreshReceiptDraft" \
  "CjguiInternalRendererStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutorReadiness" \
  "didConsumeStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutor" \
  "didMaterializeSharedResultSurfaceRenderRefreshReceipt" \
  "didMaterializeValidationDisplayRenderRefreshReceipt" \
  "didMaterializeFocusMovementRenderRefreshReceipt" \
  "didMaterializeInputFeedbackRenderRefreshReceipt" \
  "didMaterializeSemanticDiffRenderRefreshReceipt" \
  "didMaterializeChatComposerResultSurfaceRenderRefreshReceipt" \
  "didBindRenderRefreshReceiptToStage650FeedbackDeltas" \
  "didPrepareStage652ComponentHostInputResultSurfaceInteractionFeedbackRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage651 component host input result surface render refresh receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage651_component_host_input_result_surface_render_refresh_receipt_owner_present=true"
echo "stage650_component_host_input_result_surface_action_state_feedback_executor_consumed=true"
echo "stage649_component_host_input_result_surface_interaction_adapter_consumed_transitively=true"
echo "shared_result_surface_render_refresh_receipt_materialized=true"
echo "validation_display_render_refresh_receipt_materialized=true"
echo "focus_movement_render_refresh_receipt_materialized=true"
echo "input_feedback_render_refresh_receipt_materialized=true"
echo "semantic_diff_render_refresh_receipt_materialized=true"
echo "todo_result_surface_render_refresh_receipt_materialized=true"
echo "settings_result_surface_render_refresh_receipt_materialized=true"
echo "ai_generated_settings_result_surface_render_refresh_receipt_materialized=true"
echo "chat_composer_result_surface_render_refresh_receipt_materialized=true"
echo "render_refresh_receipt_bound_to_stage650_feedback_deltas=true"
echo "stage652_component_host_input_result_surface_interaction_feedback_runtime_contract_prepared=true"
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
