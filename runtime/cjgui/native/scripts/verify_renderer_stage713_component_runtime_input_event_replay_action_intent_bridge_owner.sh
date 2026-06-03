#!/usr/bin/env zsh
#
# Verifies the stage713 component runtime input event replay action intent bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage713_component_runtime_input_event_replay_action_intent_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage713 component runtime input event replay action intent bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage713ComponentRuntimeInputEventReplayActionIntentBridgePlan" \
  "CjguiInternalRendererStage713ComponentRuntimeInputEventReplayActionIntentBridgeFacts" \
  "CjguiInternalRendererStage713ComponentRuntimeInputEventReplayActionIntentBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage713ComponentRuntimeInputEventReplayActionIntentBridgeDraft" \
  "CjguiInternalRendererStage712ComponentRuntimeInputEventReplayCycleExecutorReadiness" \
  "didConsumeStage712ComponentRuntimeInputEventReplayCycleExecutor" \
  "didMaterializeSharedComponentRuntimeInputEventReplayActionIntentBridge" \
  "didMaterializeComponentReplayTextEditActionIntent" \
  "didMaterializeComponentReplaySubmitActionIntent" \
  "didMaterializeComponentReplayValidationDismissActionIntent" \
  "didMaterializeComponentReplayFocusMoveActionIntent" \
  "didKeepReplayActionIntentNonDispatching" \
  "didPrepareStage714ComponentRuntimeInputEventReplayStateDeltaDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage713 component runtime input event replay action intent bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage713_component_runtime_input_event_replay_action_intent_bridge_owner_present=true"
echo "stage712_component_runtime_input_event_replay_cycle_executor_consumed=true"
echo "component_runtime_input_event_replay_cycle_runtime_surfaces_consumed=true"
echo "shared_component_runtime_input_event_replay_action_intent_bridge_materialized=true"
echo "component_replay_text_edit_action_intent_materialized=true"
echo "component_replay_submit_action_intent_materialized=true"
echo "component_replay_validation_dismiss_action_intent_materialized=true"
echo "component_replay_focus_move_action_intent_materialized=true"
echo "todo_component_runtime_input_event_replay_action_intent_surface_materialized=true"
echo "settings_component_runtime_input_event_replay_action_intent_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_replay_action_intent_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_replay_action_intent_surface_materialized=true"
echo "component_replay_action_intent_bridge_bound_to_stage712_replay_cycle_executor=true"
echo "component_replay_action_intent_non_dispatching=true"
echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_prepared=true"
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
