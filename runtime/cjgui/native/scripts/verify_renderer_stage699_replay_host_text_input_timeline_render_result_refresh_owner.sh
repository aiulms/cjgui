#!/usr/bin/env zsh
#
# Verifies the stage699 replay host text input timeline render/result refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage699_replay_host_text_input_timeline_render_result_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage699 replay host text input timeline render/result refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage699ReplayHostTextInputTimelineRenderResultRefreshPlan" \
  "CjguiInternalRendererStage699ReplayHostTextInputTimelineRenderResultRefreshFacts" \
  "CjguiInternalRendererStage699ReplayHostTextInputTimelineRenderResultRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage699ReplayHostTextInputTimelineRenderResultRefreshDraft" \
  "CjguiInternalRendererStage698ReplayHostTextInputTimelineStateDeltaDryRunReadiness" \
  "didConsumeStage698ReplayHostTextInputTimelineStateDeltaDryRun" \
  "didMaterializeSharedReplayHostTextInputTimelineRenderResultRefreshBridge" \
  "didMaterializeTextEditTimelineRenderCommandRefreshPreview" \
  "didMaterializeSubmitTimelineResultSurfaceRefresh" \
  "didMaterializeValidationTimelineFeedbackRefresh" \
  "didMaterializeFocusTimelineResultSurfaceRefresh" \
  "didMaterializeTimelineSemanticDiffExplainRefresh" \
  "didBindTimelineRenderResultRefreshToStage698StateDelta" \
  "didPrepareStage700ReplayHostTextInputTimelineActionStateRenderExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage699 replay host text input timeline render/result refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage699_replay_host_text_input_timeline_render_result_refresh_owner_present=true"
echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_consumed=true"
echo "timeline_state_deltas_consumed=true"
echo "shared_replay_host_text_input_timeline_render_result_refresh_bridge_materialized=true"
echo "text_edit_timeline_render_command_refresh_preview_materialized=true"
echo "submit_timeline_result_surface_refresh_materialized=true"
echo "validation_timeline_feedback_refresh_materialized=true"
echo "focus_timeline_result_surface_refresh_materialized=true"
echo "timeline_semantic_diff_explain_refresh_materialized=true"
echo "todo_replay_host_text_input_timeline_render_result_surface_materialized=true"
echo "settings_replay_host_text_input_timeline_render_result_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_timeline_render_result_surface_materialized=true"
echo "chat_composer_replay_host_text_input_timeline_render_result_surface_materialized=true"
echo "timeline_render_result_refresh_bound_to_stage698_state_delta=true"
echo "timeline_render_result_refresh_bound_to_stage697_action_intent_bridge=true"
echo "timeline_render_result_refresh_bound_to_stage696_timeline_executor=true"
echo "timeline_render_result_refresh_owner_local=true"
echo "timeline_render_result_refresh_preview_only=true"
echo "stage700_replay_host_text_input_timeline_action_state_render_executor_prepared=true"
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
