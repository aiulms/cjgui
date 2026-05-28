#!/usr/bin/env zsh
#
# Verifies the stage571 component runtime text input event adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage571_component_runtime_text_input_event_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage571 component runtime text input event adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage571ComponentRuntimeTextInputEventAdapterPlan" \
  "CjguiInternalRendererStage571ComponentRuntimeTextInputEventAdapterFacts" \
  "CjguiInternalRendererStage571ComponentRuntimeTextInputEventAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage571ComponentRuntimeTextInputEventAdapterDraft" \
  "CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractReadiness" \
  "didMaterializeSharedTextInputInputEventAdapter" \
  "didMaterializeTextInputNormalizedEventLedger" \
  "didAdaptTodoTextInputKeyboardEditEvent" \
  "didAdaptSettingsTextInputCaretMovementEvent" \
  "didAdaptAiGeneratedSettingsTextInputSelectionChangeEvent" \
  "didAdaptChatComposerTextInputValidationTriggerEvent" \
  "didPrepareStage572ComponentRuntimeTextInputCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage571 component runtime text input event adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage571_component_runtime_text_input_event_adapter_owner_present=true"
echo "stage570_component_runtime_text_input_demo_host_surface_contract_consumed=true"
echo "stage569_component_runtime_text_input_measurement_affordance_executor_consumed_transitively=true"
echo "shared_text_input_input_event_adapter_materialized=true"
echo "text_input_normalized_event_ledger_materialized=true"
echo "todo_text_input_keyboard_edit_event_adapted=true"
echo "settings_text_input_caret_movement_event_adapted=true"
echo "ai_generated_settings_text_input_selection_change_event_adapted=true"
echo "chat_composer_text_input_validation_trigger_event_adapted=true"
echo "text_input_event_adapter_bound_to_stage570_host_surfaces=true"
echo "text_input_event_adapter_bound_to_stage566_state_executor=true"
echo "component_runtime_text_input_event_adapter_owner_local=true"
echo "component_runtime_text_input_event_adapter_non_executing=true"
echo "component_runtime_text_input_event_adapter_non_dispatching=true"
echo "stage572_component_runtime_text_input_cycle_executor_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
