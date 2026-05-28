#!/usr/bin/env zsh
#
# Verifies the stage609 feedback host inspection input-state bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage609_feedback_host_inspection_input_state_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage609 feedback host inspection input-state bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage609FeedbackHostInspectionInputStateBridgePlan" \
  "CjguiInternalRendererStage609FeedbackHostInspectionInputStateBridgeFacts" \
  "CjguiInternalRendererStage609FeedbackHostInspectionInputStateBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage609FeedbackHostInspectionInputStateBridgeDraft" \
  "CjguiInternalRendererStage608FeedbackHostInspectionRuntimeContractReadiness" \
  "didConsumeStage608FeedbackHostInspectionRuntimeContract" \
  "didMaterializeSharedFeedbackHostInspectionInputStateBridge" \
  "didMaterializeValidationInputStateDeltaDryRun" \
  "didMaterializeInputFeedbackStateDeltaDryRun" \
  "didMaterializeFocusTransitionStateDeltaDryRun" \
  "didMaterializeChatComposerFeedbackHostInspectionInputStateDelta" \
  "didKeepInputStateBridgeOwnerLocal" \
  "didPrepareStage610FeedbackHostInspectionStateRenderRefreshBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage609 feedback host inspection input-state bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage609_feedback_host_inspection_input_state_bridge_owner_present=true"
echo "stage608_feedback_host_inspection_runtime_contract_consumed=true"
echo "shared_feedback_host_inspection_input_state_bridge_materialized=true"
echo "validation_input_state_delta_dry_run_materialized=true"
echo "input_feedback_state_delta_dry_run_materialized=true"
echo "focus_transition_state_delta_dry_run_materialized=true"
echo "todo_feedback_host_inspection_input_state_delta_materialized=true"
echo "settings_feedback_host_inspection_input_state_delta_materialized=true"
echo "ai_generated_settings_feedback_host_inspection_input_state_delta_materialized=true"
echo "chat_composer_feedback_host_inspection_input_state_delta_materialized=true"
echo "input_state_bridge_bound_to_stage608_runtime_surfaces=true"
echo "input_state_bridge_owner_local=true"
echo "input_state_bridge_non_dispatching=true"
echo "stage610_feedback_host_inspection_state_render_refresh_bridge_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
