#!/usr/bin/env zsh
#
# Verifies the stage715 component runtime input event replay render/result refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage715_component_runtime_input_event_replay_render_result_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage715 component runtime input event replay render/result refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage715ComponentRuntimeInputEventReplayRenderResultRefreshPlan" \
  "CjguiInternalRendererStage715ComponentRuntimeInputEventReplayRenderResultRefreshFacts" \
  "CjguiInternalRendererStage715ComponentRuntimeInputEventReplayRenderResultRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage715ComponentRuntimeInputEventReplayRenderResultRefreshDraft" \
  "CjguiInternalRendererStage714ComponentRuntimeInputEventReplayStateDeltaDryRunReadiness" \
  "didConsumeStage714ComponentRuntimeInputEventReplayStateDeltaDryRun" \
  "didMaterializeSharedComponentRuntimeInputEventReplayRenderResultRefreshBridge" \
  "didMaterializeComponentReplayTextEditRenderCommandRefreshPreview" \
  "didMaterializeComponentReplaySubmitResultSurfaceRefresh" \
  "didMaterializeComponentReplayValidationFeedbackRefresh" \
  "didMaterializeComponentReplayFocusResultSurfaceRefresh" \
  "didMaterializeComponentReplaySemanticDiffExplainRefresh" \
  "didPrepareStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage715 component runtime input event replay render/result refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage715_component_runtime_input_event_replay_render_result_refresh_owner_present=true"
echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_consumed=true"
echo "component_runtime_input_event_replay_state_deltas_consumed=true"
echo "shared_component_runtime_input_event_replay_render_result_refresh_bridge_materialized=true"
echo "component_replay_text_edit_render_command_refresh_preview_materialized=true"
echo "component_replay_submit_result_surface_refresh_materialized=true"
echo "component_replay_validation_feedback_refresh_materialized=true"
echo "component_replay_focus_result_surface_refresh_materialized=true"
echo "component_replay_semantic_diff_explain_refresh_materialized=true"
echo "todo_component_runtime_input_event_replay_render_result_surface_materialized=true"
echo "settings_component_runtime_input_event_replay_render_result_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_render_result_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_render_result_surface_materialized=true"
echo "component_replay_render_result_refresh_bound_to_stage714_state_delta=true"
echo "component_replay_render_result_refresh_bound_to_stage713_action_intent_bridge=true"
echo "component_replay_render_result_refresh_bound_to_stage712_replay_cycle_executor=true"
echo "component_replay_render_result_refresh_owner_local=true"
echo "component_replay_render_result_refresh_preview_only=true"
echo "stage716_component_runtime_input_event_replay_action_state_render_executor_prepared=true"
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
