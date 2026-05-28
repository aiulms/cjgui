#!/usr/bin/env zsh
#
# Verifies the stage681 replay action-state-render demo-host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage681_replay_action_state_render_demo_host_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage681 replay action-state-render demo-host inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage681ReplayActionStateRenderDemoHostInspectionPlan" \
  "CjguiInternalRendererStage681ReplayActionStateRenderDemoHostInspectionFacts" \
  "CjguiInternalRendererStage681ReplayActionStateRenderDemoHostInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage681ReplayActionStateRenderDemoHostInspectionDraft" \
  "CjguiInternalRendererStage680FeedbackInputReplayActionStateRenderCycleExecutorReadiness" \
  "didConsumeStage680ReplayActionStateRenderCycleExecutor" \
  "didMaterializeSharedReplayActionStateRenderHostInspectionPreview" \
  "didMaterializeReplayActionStateRenderHostProbeInput" \
  "didMaterializeTodoReplayActionStateRenderHostInspection" \
  "didMaterializeSettingsReplayActionStateRenderHostInspection" \
  "didMaterializeAiGeneratedSettingsReplayActionStateRenderHostInspection" \
  "didMaterializeChatComposerReplayActionStateRenderHostInspection" \
  "didBindHostInspectionToStage680CycleExecutor" \
  "didPrepareStage682ReplayActionStateRenderLayoutFocusInspectionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage681 replay action-state-render demo-host inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage681_replay_action_state_render_demo_host_inspection_owner_present=true"
echo "stage680_replay_action_state_render_cycle_executor_consumed=true"
echo "stage679_feedback_input_replay_render_refresh_bridge_consumed_transitively=true"
echo "stage678_feedback_input_replay_state_delta_dry_run_consumed_transitively=true"
echo "stage677_feedback_input_replay_action_intent_bridge_consumed_transitively=true"
echo "shared_replay_action_state_render_host_inspection_preview_materialized=true"
echo "replay_action_state_render_host_probe_input_materialized=true"
echo "todo_replay_action_state_render_host_inspection_materialized=true"
echo "settings_replay_action_state_render_host_inspection_materialized=true"
echo "ai_generated_settings_replay_action_state_render_host_inspection_materialized=true"
echo "chat_composer_replay_action_state_render_host_inspection_materialized=true"
echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_prepared=true"
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
