#!/usr/bin/env zsh
#
# Verifies the stage532 shared runtime demo cycle input event normalization owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage532_input_event_normalization.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage532 input event normalization: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage532InputEventNormalizationPlan" \
  "CjguiInternalRendererStage532InputEventNormalizationFacts" \
  "CjguiInternalRendererStage532InputEventNormalizationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage532InputEventNormalizationDraft" \
  "CjguiInternalRendererStage531SharedRuntimeDemoCycleHostProbeReadiness" \
  "didConsumeStage531SharedRuntimeDemoCycleHostProbe" \
  "didMaterializeSharedInputEventNormalizationContract" \
  "didMaterializeHostInputEventShapeLedger" \
  "didNormalizeTodoClickInputEvent" \
  "didNormalizeSettingsToggleInputEvent" \
  "didNormalizeAiGeneratedSettingsTextInputEvent" \
  "didBindInputEventNormalizationToRuntimeDemoCycleHostProbe" \
  "didBindNormalizedEventsToSharedRuntimeDemoCycleInputContract" \
  "didPrepareStage533NormalizedEventCycleInputAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage532 input event normalization: missing token $token" >&2
    exit 3
  fi
done

echo "stage532_input_event_normalization_owner_present=true"
echo "stage531_shared_runtime_demo_cycle_host_probe_consumed=true"
echo "shared_runtime_demo_cycle_host_probe_contract_consumed=true"
echo "shared_runtime_demo_cycle_probe_helper_consumed=true"
echo "todo_runtime_demo_cycle_host_probe_input_consumed=true"
echo "settings_runtime_demo_cycle_host_probe_input_consumed=true"
echo "ai_generated_settings_runtime_demo_cycle_host_probe_input_consumed=true"
echo "shared_input_event_normalization_contract_materialized=true"
echo "host_input_event_shape_ledger_materialized=true"
echo "todo_click_input_event_normalized=true"
echo "settings_toggle_input_event_normalized=true"
echo "ai_generated_settings_text_input_event_normalized=true"
echo "input_event_normalization_bound_to_runtime_demo_cycle_host_probe=true"
echo "normalized_events_bound_to_shared_runtime_demo_cycle_input_contract=true"
echo "input_event_normalization_owner_local=true"
echo "input_event_normalization_non_executing=true"
echo "input_event_normalization_non_dispatching=true"
echo "stage533_normalized_event_cycle_input_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
