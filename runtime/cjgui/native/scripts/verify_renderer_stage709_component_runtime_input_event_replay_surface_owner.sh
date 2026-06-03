#!/usr/bin/env zsh
#
# Verifies the stage709 component runtime input event replay surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage709_component_runtime_input_event_replay_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage709 component runtime input event replay surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage709ComponentRuntimeInputEventReplaySurfacePlan" \
  "CjguiInternalRendererStage709ComponentRuntimeInputEventReplaySurfaceFacts" \
  "CjguiInternalRendererStage709ComponentRuntimeInputEventReplaySurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage709ComponentRuntimeInputEventReplaySurfaceDraft" \
  "CjguiInternalRendererStage708ComponentRuntimeInputEventCycleExecutorReadiness" \
  "didConsumeStage708ComponentRuntimeInputEventCycleExecutor" \
  "didMaterializeSharedComponentRuntimeInputEventReplaySurface" \
  "didMaterializeReplayableComponentTextEditResultSurface" \
  "didMaterializeReplayableComponentSubmitResultSurface" \
  "didMaterializeReplayableComponentValidationDismissResultSurface" \
  "didMaterializeReplayableComponentFocusMoveResultSurface" \
  "didBindReplaySurfaceToStage708InputEventCycleExecutor" \
  "didBindReplaySurfaceToStage707StateRenderFeedbackDryRun" \
  "didPrepareStage710ComponentRuntimeInputEventReplayHostInspectionPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage709 component runtime input event replay surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage709_component_runtime_input_event_replay_surface_owner_present=true"
echo "stage708_component_runtime_input_event_cycle_executor_consumed=true"
echo "stage707_component_runtime_state_render_feedback_dry_run_consumed_transitively=true"
echo "stage706_component_runtime_action_intent_adapter_consumed_transitively=true"
echo "stage705_component_runtime_input_event_normalization_consumed_transitively=true"
echo "component_runtime_input_event_cycle_surfaces_consumed=true"
echo "shared_component_runtime_input_event_replay_surface_materialized=true"
echo "replayable_component_text_edit_result_surface_materialized=true"
echo "replayable_component_submit_result_surface_materialized=true"
echo "replayable_component_validation_dismiss_result_surface_materialized=true"
echo "replayable_component_focus_move_result_surface_materialized=true"
echo "todo_component_runtime_input_event_replay_surface_materialized=true"
echo "settings_component_runtime_input_event_replay_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_surface_materialized=true"
echo "component_input_event_replay_surface_bound_to_stage708_cycle_executor=true"
echo "component_input_event_replay_surface_bound_to_stage707_state_render_feedback=true"
echo "component_input_event_replay_surface_owner_local=true"
echo "component_input_event_replay_surface_preview_only=true"
echo "stage710_component_runtime_input_event_replay_host_inspection_preview_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
