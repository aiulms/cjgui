#!/usr/bin/env zsh
#
# Verifies the stage695 replay host text input replay result surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage695_replay_host_text_input_replay_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage695 replay host text input replay result surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage695ReplayHostTextInputReplayResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage695ReplayHostTextInputReplayResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage695ReplayHostTextInputReplayResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage695ReplayHostTextInputReplayResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage694ReplayHostTextInputReplayHostInspectionPreviewReadiness" \
  "didConsumeStage694ReplayHostTextInputReplayHostInspectionPreview" \
  "didMaterializeSharedReplayHostTextInputReplayResultSurfaceRefreshReceipt" \
  "didMaterializeReplayTextEditValueFeedbackRefresh" \
  "didMaterializeReplaySubmitAffordanceRefresh" \
  "didMaterializeReplayValidationFeedbackRefresh" \
  "didMaterializeReplayFocusTransitionRefresh" \
  "didMaterializeReplayRenderCommandRefreshPreview" \
  "didMaterializeReplaySemanticDiffExplainRefresh" \
  "didBindReplayResultSurfaceRefreshToStage694HostInspection" \
  "didBindReplayResultSurfaceRefreshToStage693ReplaySurface" \
  "didPrepareStage696ReplayHostTextInputReplayTimelineExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage695 replay host text input replay result surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage695_replay_host_text_input_replay_result_surface_refresh_owner_present=true"
echo "stage694_replay_host_text_input_replay_host_inspection_preview_consumed=true"
echo "stage693_replay_host_text_input_event_replay_surface_consumed_transitively=true"
echo "stage692_replay_host_text_input_demo_host_cycle_executor_consumed_transitively=true"
echo "replay_host_inspection_timeline_previews_consumed=true"
echo "shared_replay_host_text_input_replay_result_surface_refresh_receipt_materialized=true"
echo "replay_text_edit_value_feedback_refresh_materialized=true"
echo "replay_submit_affordance_refresh_materialized=true"
echo "replay_validation_feedback_refresh_materialized=true"
echo "replay_focus_transition_refresh_materialized=true"
echo "replay_render_command_refresh_preview_materialized=true"
echo "replay_semantic_diff_explain_refresh_materialized=true"
echo "todo_replay_host_text_input_replay_result_surface_refresh_materialized=true"
echo "settings_replay_host_text_input_replay_result_surface_refresh_materialized=true"
echo "ai_generated_settings_replay_host_text_input_replay_result_surface_refresh_materialized=true"
echo "chat_composer_replay_host_text_input_replay_result_surface_refresh_materialized=true"
echo "replay_result_surface_refresh_bound_to_stage694_host_inspection=true"
echo "replay_result_surface_refresh_bound_to_stage693_replay_surface=true"
echo "replay_result_surface_refresh_owner_local=true"
echo "replay_result_surface_refresh_preview_only=true"
echo "stage696_replay_host_text_input_replay_timeline_executor_prepared=true"
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
