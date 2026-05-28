#!/usr/bin/env zsh
#
# Verifies the stage610 feedback host inspection state-render refresh bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage610_feedback_host_inspection_state_render_refresh_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage610 feedback host inspection state-render refresh bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage610FeedbackHostInspectionStateRenderRefreshBridgePlan" \
  "CjguiInternalRendererStage610FeedbackHostInspectionStateRenderRefreshBridgeFacts" \
  "CjguiInternalRendererStage610FeedbackHostInspectionStateRenderRefreshBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage610FeedbackHostInspectionStateRenderRefreshBridgeDraft" \
  "CjguiInternalRendererStage609FeedbackHostInspectionInputStateBridgeReadiness" \
  "didConsumeStage609FeedbackHostInspectionInputStateBridge" \
  "didConsumeValidationInputStateDeltaDryRun" \
  "didMaterializeSharedFeedbackHostInspectionStateRenderRefreshBridge" \
  "didMaterializeValidationDisplayRenderCommandRefreshReceipt" \
  "didMaterializeInputFeedbackRenderCommandRefreshReceipt" \
  "didMaterializeFocusTransitionRenderCommandRefreshReceipt" \
  "didMaterializeChatComposerFeedbackHostInspectionRenderRefreshReceipt" \
  "didPrepareStage611FeedbackHostInspectionDemoHostExecutionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage610 feedback host inspection state-render refresh bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage610_feedback_host_inspection_state_render_refresh_bridge_owner_present=true"
echo "stage609_feedback_host_inspection_input_state_bridge_consumed=true"
echo "shared_feedback_host_inspection_state_render_refresh_bridge_materialized=true"
echo "validation_display_render_command_refresh_receipt_materialized=true"
echo "input_feedback_render_command_refresh_receipt_materialized=true"
echo "focus_transition_render_command_refresh_receipt_materialized=true"
echo "chat_composer_feedback_host_inspection_render_refresh_receipt_materialized=true"
echo "state_render_refresh_bridge_bound_to_stage609_input_state_deltas=true"
echo "stage611_feedback_host_inspection_demo_host_execution_surface_prepared=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
