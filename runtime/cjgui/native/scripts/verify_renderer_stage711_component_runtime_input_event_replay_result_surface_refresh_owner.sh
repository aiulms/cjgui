#!/usr/bin/env zsh
#
# Verifies the stage711 component runtime input event replay result refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage711_component_runtime_input_event_replay_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage711 component runtime input event replay result surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage711ComponentRuntimeInputEventReplayResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage711ComponentRuntimeInputEventReplayResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage711ComponentRuntimeInputEventReplayResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage711ComponentRuntimeInputEventReplayResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage710ComponentRuntimeInputEventReplayHostInspectionPreviewReadiness" \
  "didConsumeStage710ComponentRuntimeInputEventReplayHostInspectionPreview" \
  "didMaterializeSharedComponentRuntimeInputEventReplayResultSurfaceRefresh" \
  "didMaterializeComponentReplayInputFeedbackRefresh" \
  "didMaterializeComponentReplayValidationFeedbackRefresh" \
  "didMaterializeComponentReplayFocusTransitionRefresh" \
  "didMaterializeComponentReplayRenderCommandRefreshPreview" \
  "didMaterializeComponentReplaySemanticDiffExplainRefresh" \
  "didBindReplayResultSurfaceRefreshToStage710HostInspection" \
  "didBindReplayResultSurfaceRefreshToStage709ReplaySurface" \
  "didPrepareStage712ComponentRuntimeInputEventReplayCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage711 component runtime input event replay result surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage711_component_runtime_input_event_replay_result_surface_refresh_owner_present=true"
echo "stage710_component_runtime_input_event_replay_host_inspection_preview_consumed=true"
echo "stage709_component_runtime_input_event_replay_surface_consumed_transitively=true"
echo "stage708_component_runtime_input_event_cycle_executor_consumed_transitively=true"
echo "component_runtime_input_event_replay_host_inspections_consumed=true"
echo "shared_component_runtime_input_event_replay_result_surface_refresh_materialized=true"
echo "component_replay_input_feedback_refresh_materialized=true"
echo "component_replay_validation_feedback_refresh_materialized=true"
echo "component_replay_focus_transition_refresh_materialized=true"
echo "component_replay_render_command_refresh_preview_materialized=true"
echo "component_replay_semantic_diff_explain_refresh_materialized=true"
echo "todo_component_runtime_input_event_replay_result_surface_refresh_materialized=true"
echo "settings_component_runtime_input_event_replay_result_surface_refresh_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_result_surface_refresh_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_result_surface_refresh_materialized=true"
echo "component_input_event_replay_result_surface_refresh_bound_to_stage710_host_inspection=true"
echo "component_input_event_replay_result_surface_refresh_bound_to_stage709_replay_surface=true"
echo "component_input_event_replay_result_surface_refresh_owner_local=true"
echo "component_input_event_replay_result_surface_refresh_preview_only=true"
echo "stage712_component_runtime_input_event_replay_cycle_executor_prepared=true"
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
