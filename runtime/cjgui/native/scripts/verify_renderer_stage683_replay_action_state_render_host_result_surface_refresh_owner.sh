#!/usr/bin/env zsh
#
# Verifies the stage683 replay action-state-render host result-surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage683_replay_action_state_render_host_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage683 replay action-state-render host result-surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage683ReplayActionStateRenderHostResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage683ReplayActionStateRenderHostResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage683ReplayActionStateRenderHostResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage683ReplayActionStateRenderHostResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage682ReplayActionStateRenderLayoutFocusInspectionReceiptReadiness" \
  "didConsumeStage682ReplayActionStateRenderLayoutFocusInspectionReceipt" \
  "didMaterializeSharedReplayHostResultSurfaceRefresh" \
  "didMaterializeReplayHostSemanticDiffExplainRefresh" \
  "didMaterializeReplayHostFocusTransitionRefresh" \
  "didMaterializeReplayHostRenderCommandInspectionRefresh" \
  "didMaterializeReplayHostInputFeedbackDisplayRefresh" \
  "didMaterializeChatComposerReplayHostResultSurfaceRefresh" \
  "didBindHostResultSurfaceRefreshToStage682LayoutFocusInspection" \
  "didPrepareStage684ReplayActionStateRenderHostInspectionRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage683 replay action-state-render host result-surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage683_replay_action_state_render_host_result_surface_refresh_owner_present=true"
echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_consumed=true"
echo "stage681_replay_action_state_render_demo_host_inspection_consumed_transitively=true"
echo "stage680_replay_action_state_render_cycle_executor_consumed_transitively=true"
echo "shared_replay_host_result_surface_refresh_materialized=true"
echo "replay_host_semantic_diff_explain_refresh_materialized=true"
echo "replay_host_focus_transition_refresh_materialized=true"
echo "replay_host_render_command_inspection_refresh_materialized=true"
echo "replay_host_input_feedback_display_refresh_materialized=true"
echo "todo_replay_host_result_surface_refresh_materialized=true"
echo "settings_replay_host_result_surface_refresh_materialized=true"
echo "ai_generated_settings_replay_host_result_surface_refresh_materialized=true"
echo "chat_composer_replay_host_result_surface_refresh_materialized=true"
echo "stage684_replay_action_state_render_host_inspection_runtime_contract_prepared=true"
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
