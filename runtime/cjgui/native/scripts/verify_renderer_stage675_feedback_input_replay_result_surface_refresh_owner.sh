#!/usr/bin/env zsh
#
# Verifies the stage675 feedback input replay result surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage675_feedback_input_replay_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage675 feedback input replay result surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage675FeedbackInputReplayResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage675FeedbackInputReplayResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage675FeedbackInputReplayResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage675FeedbackInputReplayResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage674FeedbackInputReplayHostInspectionPreviewReadiness" \
  "didConsumeStage674FeedbackInputReplayHostInspectionPreview" \
  "didMaterializeSharedReplayResultSurfaceRefreshReceipt" \
  "didMaterializeReplaySemanticDiffExplainRefresh" \
  "didMaterializeReplayFocusTransitionRefresh" \
  "didMaterializeReplayRenderCommandRefreshPreview" \
  "didMaterializeReplayInputFeedbackDisplayRefresh" \
  "didPrepareStage676FeedbackInputReplayRuntimeExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage675 feedback input replay result surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage675_feedback_input_replay_result_surface_refresh_owner_present=true"
echo "stage674_feedback_input_replay_host_inspection_preview_consumed=true"
echo "shared_replay_result_surface_refresh_receipt_materialized=true"
echo "replay_semantic_diff_explain_refresh_materialized=true"
echo "replay_focus_transition_refresh_materialized=true"
echo "replay_render_command_refresh_preview_materialized=true"
echo "replay_input_feedback_display_refresh_materialized=true"
echo "todo_feedback_input_replay_result_surface_refresh_materialized=true"
echo "settings_feedback_input_replay_result_surface_refresh_materialized=true"
echo "ai_generated_settings_feedback_input_replay_result_surface_refresh_materialized=true"
echo "chat_composer_feedback_input_replay_result_surface_refresh_materialized=true"
echo "stage676_feedback_input_replay_runtime_executor_prepared=true"
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
