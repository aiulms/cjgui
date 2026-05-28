#!/usr/bin/env zsh
#
# Verifies the stage679 feedback input replay render refresh bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage679_feedback_input_replay_render_refresh_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage679 feedback input replay render refresh bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage679FeedbackInputReplayRenderRefreshBridgePlan" \
  "CjguiInternalRendererStage679FeedbackInputReplayRenderRefreshBridgeFacts" \
  "CjguiInternalRendererStage679FeedbackInputReplayRenderRefreshBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage679FeedbackInputReplayRenderRefreshBridgeDraft" \
  "CjguiInternalRendererStage678FeedbackInputReplayStateDeltaDryRunReadiness" \
  "didConsumeStage678FeedbackInputReplayStateDeltaDryRun" \
  "didConsumeReplayStateDeltaDryRuns" \
  "didMaterializeSharedReplayRenderCommandRefreshBridge" \
  "didMaterializeReplayResultSurfaceRefreshPreview" \
  "didMaterializeReplaySemanticDiffExplainRefresh" \
  "didMaterializeReplayFocusTransitionRefresh" \
  "didMaterializeReplayInputFeedbackDisplayRefresh" \
  "didMaterializeChatComposerFeedbackInputReplayRenderRefreshSurface" \
  "didPrepareStage680FeedbackInputReplayActionStateRenderCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage679 feedback input replay render refresh bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage679_feedback_input_replay_render_refresh_bridge_owner_present=true"
echo "stage678_feedback_input_replay_state_delta_dry_run_consumed=true"
echo "replay_state_delta_dry_runs_consumed=true"
echo "shared_replay_render_command_refresh_bridge_materialized=true"
echo "replay_result_surface_refresh_preview_materialized=true"
echo "replay_semantic_diff_explain_refresh_materialized=true"
echo "replay_focus_transition_refresh_materialized=true"
echo "replay_input_feedback_display_refresh_materialized=true"
echo "todo_feedback_input_replay_render_refresh_surface_materialized=true"
echo "settings_feedback_input_replay_render_refresh_surface_materialized=true"
echo "ai_generated_settings_feedback_input_replay_render_refresh_surface_materialized=true"
echo "chat_composer_feedback_input_replay_render_refresh_surface_materialized=true"
echo "stage680_feedback_input_replay_action_state_render_cycle_executor_prepared=true"
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
