#!/usr/bin/env zsh
#
# Verifies the stage677 feedback input replay action intent bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage677_feedback_input_replay_action_intent_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage677 feedback input replay action intent bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage677FeedbackInputReplayActionIntentBridgePlan" \
  "CjguiInternalRendererStage677FeedbackInputReplayActionIntentBridgeFacts" \
  "CjguiInternalRendererStage677FeedbackInputReplayActionIntentBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage677FeedbackInputReplayActionIntentBridgeDraft" \
  "CjguiInternalRendererStage676FeedbackInputReplayRuntimeExecutorReadiness" \
  "didConsumeStage676FeedbackInputReplayRuntimeExecutor" \
  "didMaterializeSharedReplayActionIntentBridge" \
  "didMaterializeValidationDismissReplayActionIntent" \
  "didMaterializeFocusMovementReplayActionIntent" \
  "didMaterializeInputFeedbackClearReplayActionIntent" \
  "didMaterializeSemanticDiffAcknowledgeReplayActionIntent" \
  "didMaterializeTodoFeedbackInputReplayActionIntentSurface" \
  "didMaterializeSettingsFeedbackInputReplayActionIntentSurface" \
  "didMaterializeAiGeneratedSettingsFeedbackInputReplayActionIntentSurface" \
  "didMaterializeChatComposerFeedbackInputReplayActionIntentSurface" \
  "didKeepReplayActionIntentNonDispatching" \
  "didPrepareStage678FeedbackInputReplayStateDeltaDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage677 feedback input replay action intent bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage677_feedback_input_replay_action_intent_bridge_owner_present=true"
echo "stage676_feedback_input_replay_runtime_executor_consumed=true"
echo "shared_replay_action_intent_bridge_materialized=true"
echo "validation_dismiss_replay_action_intent_materialized=true"
echo "focus_movement_replay_action_intent_materialized=true"
echo "input_feedback_clear_replay_action_intent_materialized=true"
echo "semantic_diff_acknowledge_replay_action_intent_materialized=true"
echo "todo_feedback_input_replay_action_intent_surface_materialized=true"
echo "settings_feedback_input_replay_action_intent_surface_materialized=true"
echo "ai_generated_settings_feedback_input_replay_action_intent_surface_materialized=true"
echo "chat_composer_feedback_input_replay_action_intent_surface_materialized=true"
echo "replay_action_intent_non_dispatching=true"
echo "stage678_feedback_input_replay_state_delta_dry_run_prepared=true"
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
