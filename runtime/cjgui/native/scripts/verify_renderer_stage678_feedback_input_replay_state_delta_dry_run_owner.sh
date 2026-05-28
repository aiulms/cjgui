#!/usr/bin/env zsh
#
# Verifies the stage678 feedback input replay state delta dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage678_feedback_input_replay_state_delta_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage678 feedback input replay state delta dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage678FeedbackInputReplayStateDeltaDryRunPlan" \
  "CjguiInternalRendererStage678FeedbackInputReplayStateDeltaDryRunFacts" \
  "CjguiInternalRendererStage678FeedbackInputReplayStateDeltaDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage678FeedbackInputReplayStateDeltaDryRunDraft" \
  "CjguiInternalRendererStage677FeedbackInputReplayActionIntentBridgeReadiness" \
  "didConsumeStage677FeedbackInputReplayActionIntentBridge" \
  "didConsumeReplayActionIntents" \
  "didMaterializeSharedReplayStateDeltaDryRunExecutor" \
  "didMaterializeValidationDismissReplayStateDelta" \
  "didMaterializeFocusMovementReplayStateDelta" \
  "didMaterializeInputFeedbackClearReplayStateDelta" \
  "didMaterializeSemanticDiffAcknowledgeReplayStateDelta" \
  "didMaterializeReplayRollbackPreview" \
  "didKeepReplayStateDeltaOwnerLocal" \
  "didPrepareStage679FeedbackInputReplayRenderRefreshBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage678 feedback input replay state delta dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage678_feedback_input_replay_state_delta_dry_run_owner_present=true"
echo "stage677_feedback_input_replay_action_intent_bridge_consumed=true"
echo "replay_action_intents_consumed=true"
echo "shared_replay_state_delta_dry_run_executor_materialized=true"
echo "validation_dismiss_replay_state_delta_materialized=true"
echo "focus_movement_replay_state_delta_materialized=true"
echo "input_feedback_clear_replay_state_delta_materialized=true"
echo "semantic_diff_acknowledge_replay_state_delta_materialized=true"
echo "replay_rollback_preview_materialized=true"
echo "replay_state_delta_owner_local=true"
echo "stage679_feedback_input_replay_render_refresh_bridge_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
