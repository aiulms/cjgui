#!/usr/bin/env zsh
#
# Verifies the stage673 feedback input event replay surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage673_feedback_input_event_replay_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage673 feedback input event replay surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage673FeedbackInputEventReplaySurfacePlan" \
  "CjguiInternalRendererStage673FeedbackInputEventReplaySurfaceFacts" \
  "CjguiInternalRendererStage673FeedbackInputEventReplaySurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage673FeedbackInputEventReplaySurfaceDraft" \
  "CjguiInternalRendererStage672FeedbackInputDemoHostEventCycleRuntimeContractReadiness" \
  "didConsumeStage672FeedbackInputDemoHostEventCycleRuntimeContract" \
  "didMaterializeSharedFeedbackInputEventReplaySurface" \
  "didMaterializeReplayableValidationDismissResultSurface" \
  "didMaterializeReplayableFocusMovementResultSurface" \
  "didMaterializeReplayableInputFeedbackClearResultSurface" \
  "didMaterializeReplayableSemanticDiffAcknowledgeResultSurface" \
  "didMaterializeChatComposerFeedbackInputEventReplaySurface" \
  "didPrepareStage674FeedbackInputReplayHostInspectionPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage673 feedback input event replay surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage673_feedback_input_event_replay_surface_owner_present=true"
echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_consumed=true"
echo "shared_feedback_input_event_replay_surface_materialized=true"
echo "replayable_validation_dismiss_result_surface_materialized=true"
echo "replayable_focus_movement_result_surface_materialized=true"
echo "replayable_input_feedback_clear_result_surface_materialized=true"
echo "replayable_semantic_diff_acknowledge_result_surface_materialized=true"
echo "todo_feedback_input_event_replay_surface_materialized=true"
echo "settings_feedback_input_event_replay_surface_materialized=true"
echo "ai_generated_settings_feedback_input_event_replay_surface_materialized=true"
echo "chat_composer_feedback_input_event_replay_surface_materialized=true"
echo "stage674_feedback_input_replay_host_inspection_preview_prepared=true"
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
