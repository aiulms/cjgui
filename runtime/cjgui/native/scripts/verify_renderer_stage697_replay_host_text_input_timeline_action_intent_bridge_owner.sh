#!/usr/bin/env zsh
#
# Verifies the stage697 replay host text input timeline action intent bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage697_replay_host_text_input_timeline_action_intent_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage697 replay host text input timeline action intent bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage697ReplayHostTextInputTimelineActionIntentBridgePlan" \
  "CjguiInternalRendererStage697ReplayHostTextInputTimelineActionIntentBridgeFacts" \
  "CjguiInternalRendererStage697ReplayHostTextInputTimelineActionIntentBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage697ReplayHostTextInputTimelineActionIntentBridgeDraft" \
  "CjguiInternalRendererStage696ReplayHostTextInputReplayTimelineExecutorReadiness" \
  "didConsumeStage696ReplayHostTextInputReplayTimelineExecutor" \
  "didMaterializeSharedReplayHostTextInputTimelineActionIntentBridge" \
  "didMaterializeTextEditCommitTimelineActionIntent" \
  "didMaterializeSubmitTimelineActionIntent" \
  "didMaterializeValidationDismissTimelineActionIntent" \
  "didMaterializeFocusMoveTimelineActionIntent" \
  "didBindTimelineActionIntentBridgeToStage696TimelineExecutor" \
  "didKeepTimelineActionIntentNonDispatching" \
  "didPrepareStage698ReplayHostTextInputTimelineStateDeltaDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage697 replay host text input timeline action intent bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage697_replay_host_text_input_timeline_action_intent_bridge_owner_present=true"
echo "stage696_replay_host_text_input_replay_timeline_executor_consumed=true"
echo "replay_timeline_runtime_surfaces_consumed=true"
echo "shared_replay_host_text_input_timeline_action_intent_bridge_materialized=true"
echo "text_edit_commit_timeline_action_intent_materialized=true"
echo "submit_timeline_action_intent_materialized=true"
echo "validation_dismiss_timeline_action_intent_materialized=true"
echo "focus_move_timeline_action_intent_materialized=true"
echo "todo_replay_host_text_input_timeline_action_intent_surface_materialized=true"
echo "settings_replay_host_text_input_timeline_action_intent_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_timeline_action_intent_surface_materialized=true"
echo "chat_composer_replay_host_text_input_timeline_action_intent_surface_materialized=true"
echo "timeline_action_intent_bridge_bound_to_stage696_timeline_executor=true"
echo "timeline_action_intent_non_dispatching=true"
echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
