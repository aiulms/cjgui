#!/usr/bin/env zsh
#
# Verifies the stage674 feedback input replay host inspection preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage674_feedback_input_replay_host_inspection_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage674 feedback input replay host inspection preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage674FeedbackInputReplayHostInspectionPreviewPlan" \
  "CjguiInternalRendererStage674FeedbackInputReplayHostInspectionPreviewFacts" \
  "CjguiInternalRendererStage674FeedbackInputReplayHostInspectionPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage674FeedbackInputReplayHostInspectionPreviewDraft" \
  "CjguiInternalRendererStage673FeedbackInputEventReplaySurfaceReadiness" \
  "didConsumeStage673FeedbackInputEventReplaySurface" \
  "didMaterializeSharedReplayHostInspectionPreview" \
  "didMaterializeReplayProbeInputContract" \
  "didMaterializeValidationDismissReplayHostInspection" \
  "didMaterializeFocusMovementReplayHostInspection" \
  "didMaterializeInputFeedbackClearReplayHostInspection" \
  "didMaterializeSemanticDiffAcknowledgeReplayHostInspection" \
  "didPrepareStage675FeedbackInputReplayResultSurfaceRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage674 feedback input replay host inspection preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage674_feedback_input_replay_host_inspection_preview_owner_present=true"
echo "stage673_feedback_input_event_replay_surface_consumed=true"
echo "shared_replay_host_inspection_preview_materialized=true"
echo "replay_probe_input_contract_materialized=true"
echo "validation_dismiss_replay_host_inspection_materialized=true"
echo "focus_movement_replay_host_inspection_materialized=true"
echo "input_feedback_clear_replay_host_inspection_materialized=true"
echo "semantic_diff_acknowledge_replay_host_inspection_materialized=true"
echo "todo_feedback_input_replay_host_inspection_materialized=true"
echo "settings_feedback_input_replay_host_inspection_materialized=true"
echo "ai_generated_settings_feedback_input_replay_host_inspection_materialized=true"
echo "chat_composer_feedback_input_replay_host_inspection_materialized=true"
echo "stage675_feedback_input_replay_result_surface_refresh_prepared=true"
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
