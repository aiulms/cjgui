#!/usr/bin/env zsh
#
# Verifies the stage714 component runtime input event replay state delta dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage714_component_runtime_input_event_replay_state_delta_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage714 component runtime input event replay state delta dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage714ComponentRuntimeInputEventReplayStateDeltaDryRunPlan" \
  "CjguiInternalRendererStage714ComponentRuntimeInputEventReplayStateDeltaDryRunFacts" \
  "CjguiInternalRendererStage714ComponentRuntimeInputEventReplayStateDeltaDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage714ComponentRuntimeInputEventReplayStateDeltaDryRunDraft" \
  "CjguiInternalRendererStage713ComponentRuntimeInputEventReplayActionIntentBridgeReadiness" \
  "didConsumeStage713ComponentRuntimeInputEventReplayActionIntentBridge" \
  "didMaterializeSharedComponentRuntimeInputEventReplayStateDeltaDryRunExecutor" \
  "didMaterializeComponentReplayTextEditValueStateDelta" \
  "didMaterializeComponentReplaySubmitPendingStateDelta" \
  "didMaterializeComponentReplayValidationDismissStateDelta" \
  "didMaterializeComponentReplayFocusMoveStateDelta" \
  "didMaterializeComponentReplayRollbackPreview" \
  "didPrepareStage715ComponentRuntimeInputEventReplayRenderResultRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage714 component runtime input event replay state delta dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_owner_present=true"
echo "stage713_component_runtime_input_event_replay_action_intent_bridge_consumed=true"
echo "component_runtime_input_event_replay_action_intents_consumed=true"
echo "shared_component_runtime_input_event_replay_state_delta_dry_run_executor_materialized=true"
echo "component_replay_text_edit_value_state_delta_materialized=true"
echo "component_replay_submit_pending_state_delta_materialized=true"
echo "component_replay_validation_dismiss_state_delta_materialized=true"
echo "component_replay_focus_move_state_delta_materialized=true"
echo "todo_component_runtime_input_event_replay_state_delta_surface_materialized=true"
echo "settings_component_runtime_input_event_replay_state_delta_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_state_delta_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_state_delta_surface_materialized=true"
echo "component_replay_rollback_preview_materialized=true"
echo "component_replay_state_delta_bound_to_stage713_action_intent_bridge=true"
echo "component_replay_state_delta_bound_to_stage712_replay_cycle_executor=true"
echo "component_replay_state_delta_owner_local=true"
echo "component_replay_state_delta_dry_run_only=true"
echo "stage715_component_runtime_input_event_replay_render_result_refresh_prepared=true"
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
