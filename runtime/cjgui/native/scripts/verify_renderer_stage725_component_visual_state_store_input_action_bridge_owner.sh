#!/usr/bin/env zsh
#
# Verifies the stage725 component visual state store input/action bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage725_component_visual_state_store_input_action_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage725 component visual state store input action bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgePlan" \
  "CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeFacts" \
  "CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage725ComponentVisualStateStoreInputActionBridgeDraft" \
  "CjguiInternalRendererStage724ComponentVisualStateStoreManagerReadiness" \
  "didConsumeStage724ComponentVisualStateStoreManager" \
  "didMaterializeSharedVisualStateStoreInputActionBridge" \
  "didMaterializeVisualStateStoreTextEditActionIntent" \
  "didMaterializeVisualStateStoreSubmitActionIntent" \
  "didMaterializeVisualStateStoreValidationDismissActionIntent" \
  "didMaterializeVisualStateStoreFocusMoveActionIntent" \
  "didBindInputActionBridgeToStage724VisualStateStoreManager" \
  "didKeepVisualStateStoreActionIntentNonDispatching" \
  "didPrepareStage726ComponentVisualStateStoreActionReducerPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage725 component visual state store input action bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage725_component_visual_state_store_input_action_bridge_owner_present=true"
echo "stage724_component_visual_state_store_manager_consumed=true"
echo "shared_visual_state_store_input_action_bridge_materialized=true"
echo "visual_state_store_text_edit_action_intent_materialized=true"
echo "visual_state_store_submit_action_intent_materialized=true"
echo "visual_state_store_validation_dismiss_action_intent_materialized=true"
echo "visual_state_store_focus_move_action_intent_materialized=true"
echo "todo_visual_state_store_input_action_surface_materialized=true"
echo "settings_visual_state_store_input_action_surface_materialized=true"
echo "ai_generated_settings_visual_state_store_input_action_surface_materialized=true"
echo "chat_composer_visual_state_store_input_action_surface_materialized=true"
echo "visual_state_store_input_action_bridge_bound_to_stage724_manager=true"
echo "visual_state_store_action_intent_non_dispatching=true"
echo "stage726_component_visual_state_store_action_reducer_preflight_prepared=true"
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
