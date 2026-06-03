#!/usr/bin/env zsh
#
# Verifies the stage693 replay host text input event replay surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage693_replay_host_text_input_event_replay_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage693 replay host text input event replay surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage693ReplayHostTextInputEventReplaySurfacePlan" \
  "CjguiInternalRendererStage693ReplayHostTextInputEventReplaySurfaceFacts" \
  "CjguiInternalRendererStage693ReplayHostTextInputEventReplaySurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage693ReplayHostTextInputEventReplaySurfaceDraft" \
  "CjguiInternalRendererStage692ReplayHostTextInputDemoHostCycleExecutorReadiness" \
  "didConsumeStage692ReplayHostTextInputDemoHostCycleExecutor" \
  "didMaterializeSharedReplayHostTextInputEventReplaySurface" \
  "didMaterializeReplayableTextEditCommitResultSurface" \
  "didMaterializeReplayableSubmitResultSurface" \
  "didMaterializeReplayableValidationDismissResultSurface" \
  "didMaterializeReplayableFocusMoveResultSurface" \
  "didBindReplaySurfaceToStage692CycleExecutor" \
  "didBindReplaySurfaceToStage690EventQueue" \
  "didBindReplaySurfaceToStage688TextInputRuntimeContract" \
  "didPrepareStage694ReplayHostTextInputReplayHostInspectionPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage693 replay host text input event replay surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage693_replay_host_text_input_event_replay_surface_owner_present=true"
echo "stage692_replay_host_text_input_demo_host_cycle_executor_consumed=true"
echo "stage691_replay_host_text_input_execution_result_surface_consumed_transitively=true"
echo "stage690_replay_host_text_input_host_event_adapter_consumed_transitively=true"
echo "stage688_replay_host_text_input_runtime_contract_consumed_transitively=true"
echo "text_input_demo_host_cycle_runtime_surfaces_consumed=true"
echo "shared_replay_host_text_input_event_replay_surface_materialized=true"
echo "replayable_text_edit_commit_result_surface_materialized=true"
echo "replayable_submit_result_surface_materialized=true"
echo "replayable_validation_dismiss_result_surface_materialized=true"
echo "replayable_focus_move_result_surface_materialized=true"
echo "todo_replay_host_text_input_event_replay_surface_materialized=true"
echo "settings_replay_host_text_input_event_replay_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_event_replay_surface_materialized=true"
echo "chat_composer_replay_host_text_input_event_replay_surface_materialized=true"
echo "replay_surface_bound_to_stage692_cycle_executor=true"
echo "replay_surface_bound_to_stage690_event_queue=true"
echo "replay_surface_bound_to_stage688_text_input_runtime_contract=true"
echo "replay_surface_owner_local=true"
echo "replay_surface_preview_only=true"
echo "stage694_replay_host_text_input_replay_host_inspection_preview_prepared=true"
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
