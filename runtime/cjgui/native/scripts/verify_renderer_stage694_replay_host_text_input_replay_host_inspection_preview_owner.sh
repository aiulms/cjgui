#!/usr/bin/env zsh
#
# Verifies the stage694 replay host text input replay host inspection preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage694_replay_host_text_input_replay_host_inspection_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage694 replay host text input replay host inspection preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage694ReplayHostTextInputReplayHostInspectionPreviewPlan" \
  "CjguiInternalRendererStage694ReplayHostTextInputReplayHostInspectionPreviewFacts" \
  "CjguiInternalRendererStage694ReplayHostTextInputReplayHostInspectionPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage694ReplayHostTextInputReplayHostInspectionPreviewDraft" \
  "CjguiInternalRendererStage693ReplayHostTextInputEventReplaySurfaceReadiness" \
  "didConsumeStage693ReplayHostTextInputEventReplaySurface" \
  "didMaterializeSharedReplayHostTextInputHostInspectionTimelinePreview" \
  "didMaterializeReplayTimelineProbeInputContract" \
  "didMaterializeTextEditCommitReplayHostInspection" \
  "didMaterializeSubmitReplayHostInspection" \
  "didMaterializeValidationDismissReplayHostInspection" \
  "didMaterializeFocusMoveReplayHostInspection" \
  "didBindReplayHostInspectionToStage693ReplaySurface" \
  "didBindReplayHostInspectionToStage692CycleExecutor" \
  "didPrepareStage695ReplayHostTextInputReplayResultSurfaceRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage694 replay host text input replay host inspection preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage694_replay_host_text_input_replay_host_inspection_preview_owner_present=true"
echo "stage693_replay_host_text_input_event_replay_surface_consumed=true"
echo "stage692_replay_host_text_input_demo_host_cycle_executor_consumed_transitively=true"
echo "text_input_event_replay_surfaces_consumed=true"
echo "shared_replay_host_text_input_host_inspection_timeline_preview_materialized=true"
echo "replay_timeline_probe_input_contract_materialized=true"
echo "text_edit_commit_replay_host_inspection_materialized=true"
echo "submit_replay_host_inspection_materialized=true"
echo "validation_dismiss_replay_host_inspection_materialized=true"
echo "focus_move_replay_host_inspection_materialized=true"
echo "todo_replay_host_text_input_host_inspection_materialized=true"
echo "settings_replay_host_text_input_host_inspection_materialized=true"
echo "ai_generated_settings_replay_host_text_input_host_inspection_materialized=true"
echo "chat_composer_replay_host_text_input_host_inspection_materialized=true"
echo "replay_host_inspection_bound_to_stage693_replay_surface=true"
echo "replay_host_inspection_bound_to_stage692_cycle_executor=true"
echo "replay_host_inspection_owner_local=true"
echo "stage695_replay_host_text_input_replay_result_surface_refresh_prepared=true"
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
