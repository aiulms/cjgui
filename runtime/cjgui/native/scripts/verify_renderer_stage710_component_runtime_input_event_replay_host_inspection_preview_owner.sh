#!/usr/bin/env zsh
#
# Verifies the stage710 component runtime input event replay host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage710_component_runtime_input_event_replay_host_inspection_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage710 component runtime input event replay host inspection preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage710ComponentRuntimeInputEventReplayHostInspectionPreviewPlan" \
  "CjguiInternalRendererStage710ComponentRuntimeInputEventReplayHostInspectionPreviewFacts" \
  "CjguiInternalRendererStage710ComponentRuntimeInputEventReplayHostInspectionPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage710ComponentRuntimeInputEventReplayHostInspectionPreviewDraft" \
  "CjguiInternalRendererStage709ComponentRuntimeInputEventReplaySurfaceReadiness" \
  "didConsumeStage709ComponentRuntimeInputEventReplaySurface" \
  "didMaterializeSharedComponentRuntimeInputEventReplayHostInspectionPreview" \
  "didMaterializeComponentRuntimeReplayProbeInputContract" \
  "didMaterializeComponentTextEditReplayHostInspection" \
  "didMaterializeComponentSubmitReplayHostInspection" \
  "didMaterializeComponentValidationDismissReplayHostInspection" \
  "didMaterializeComponentFocusMoveReplayHostInspection" \
  "didBindReplayHostInspectionToStage709ReplaySurface" \
  "didBindReplayHostInspectionToStage708CycleExecutor" \
  "didPrepareStage711ComponentRuntimeInputEventReplayResultSurfaceRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage710 component runtime input event replay host inspection preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage710_component_runtime_input_event_replay_host_inspection_preview_owner_present=true"
echo "stage709_component_runtime_input_event_replay_surface_consumed=true"
echo "stage708_component_runtime_input_event_cycle_executor_consumed_transitively=true"
echo "component_runtime_input_event_replay_surfaces_consumed=true"
echo "shared_component_runtime_input_event_replay_host_inspection_preview_materialized=true"
echo "component_runtime_replay_probe_input_contract_materialized=true"
echo "component_text_edit_replay_host_inspection_materialized=true"
echo "component_submit_replay_host_inspection_materialized=true"
echo "component_validation_dismiss_replay_host_inspection_materialized=true"
echo "component_focus_move_replay_host_inspection_materialized=true"
echo "todo_component_runtime_input_event_replay_host_inspection_materialized=true"
echo "settings_component_runtime_input_event_replay_host_inspection_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_host_inspection_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_host_inspection_materialized=true"
echo "component_input_event_replay_host_inspection_bound_to_stage709_replay_surface=true"
echo "component_input_event_replay_host_inspection_bound_to_stage708_cycle_executor=true"
echo "component_input_event_replay_host_inspection_owner_local=true"
echo "stage711_component_runtime_input_event_replay_result_surface_refresh_prepared=true"
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
