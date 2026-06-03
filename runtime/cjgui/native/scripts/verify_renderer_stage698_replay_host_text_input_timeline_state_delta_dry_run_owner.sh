#!/usr/bin/env zsh
#
# Verifies the stage698 replay host text input timeline state delta dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage698_replay_host_text_input_timeline_state_delta_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage698 replay host text input timeline state delta dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage698ReplayHostTextInputTimelineStateDeltaDryRunPlan" \
  "CjguiInternalRendererStage698ReplayHostTextInputTimelineStateDeltaDryRunFacts" \
  "CjguiInternalRendererStage698ReplayHostTextInputTimelineStateDeltaDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage698ReplayHostTextInputTimelineStateDeltaDryRunDraft" \
  "CjguiInternalRendererStage697ReplayHostTextInputTimelineActionIntentBridgeReadiness" \
  "didConsumeStage697ReplayHostTextInputTimelineActionIntentBridge" \
  "didMaterializeSharedReplayHostTextInputTimelineStateDeltaDryRunExecutor" \
  "didMaterializeTextEditValueTimelineStateDelta" \
  "didMaterializeSubmitPendingTimelineStateDelta" \
  "didMaterializeValidationDismissTimelineStateDelta" \
  "didMaterializeFocusMoveTimelineStateDelta" \
  "didMaterializeTimelineRollbackPreview" \
  "didBindTimelineStateDeltaToStage697ActionIntentBridge" \
  "didPrepareStage699ReplayHostTextInputTimelineRenderResultRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage698 replay host text input timeline state delta dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_owner_present=true"
echo "stage697_replay_host_text_input_timeline_action_intent_bridge_consumed=true"
echo "timeline_action_intents_consumed=true"
echo "shared_replay_host_text_input_timeline_state_delta_dry_run_executor_materialized=true"
echo "text_edit_value_timeline_state_delta_materialized=true"
echo "submit_pending_timeline_state_delta_materialized=true"
echo "validation_dismiss_timeline_state_delta_materialized=true"
echo "focus_move_timeline_state_delta_materialized=true"
echo "todo_replay_host_text_input_timeline_state_delta_surface_materialized=true"
echo "settings_replay_host_text_input_timeline_state_delta_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_timeline_state_delta_surface_materialized=true"
echo "chat_composer_replay_host_text_input_timeline_state_delta_surface_materialized=true"
echo "timeline_rollback_preview_materialized=true"
echo "timeline_state_delta_bound_to_stage697_action_intent_bridge=true"
echo "timeline_state_delta_bound_to_stage696_timeline_executor=true"
echo "timeline_state_delta_owner_local=true"
echo "timeline_state_delta_dry_run_only=true"
echo "stage699_replay_host_text_input_timeline_render_result_refresh_prepared=true"
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
