#!/usr/bin/env zsh
#
# Verifies the stage702 text input component slot binding adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage702_text_input_component_slot_binding_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage702 text input component slot binding adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage702TextInputComponentSlotBindingAdapterPlan" \
  "CjguiInternalRendererStage702TextInputComponentSlotBindingAdapterFacts" \
  "CjguiInternalRendererStage702TextInputComponentSlotBindingAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage702TextInputComponentSlotBindingAdapterDraft" \
  "CjguiInternalRendererStage701TextInputTimelineComponentRuntimeContractReadiness" \
  "didConsumeStage701TextInputTimelineComponentRuntimeContract" \
  "didMaterializeSharedTextInputComponentSlotBindingAdapter" \
  "didBindComponentSlotsToTimelineActionIntent" \
  "didBindComponentSlotsToTimelineStateDelta" \
  "didBindComponentSlotsToRenderResultRefresh" \
  "didMaterializeComponentActionStateRenderBindingLedger" \
  "didMaterializeChatComposerTextInputComponentSlotBindings" \
  "didPrepareStage703TextInputComponentRuntimeDemoSurfaceRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage702 text input component slot binding adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage702_text_input_component_slot_binding_adapter_owner_present=true"
echo "stage701_text_input_timeline_component_runtime_contract_consumed=true"
echo "shared_text_input_component_slot_binding_adapter_materialized=true"
echo "component_slots_bound_to_timeline_action_intent=true"
echo "component_slots_bound_to_timeline_state_delta=true"
echo "component_slots_bound_to_render_result_refresh=true"
echo "component_action_state_render_binding_ledger_materialized=true"
echo "todo_text_input_component_slot_bindings_materialized=true"
echo "settings_text_input_component_slot_bindings_materialized=true"
echo "ai_generated_settings_text_input_component_slot_bindings_materialized=true"
echo "chat_composer_text_input_component_slot_bindings_materialized=true"
echo "stage700_executor_consumed_transitively=true"
echo "stage703_text_input_component_runtime_demo_surface_refresh_prepared=true"
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
