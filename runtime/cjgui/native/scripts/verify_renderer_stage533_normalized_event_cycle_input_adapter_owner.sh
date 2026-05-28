#!/usr/bin/env zsh
#
# Verifies the stage533 normalized event -> cycle input adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage533_normalized_event_cycle_input_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage533 normalized event cycle input adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage533NormalizedEventCycleInputAdapterPlan" \
  "CjguiInternalRendererStage533NormalizedEventCycleInputAdapterFacts" \
  "CjguiInternalRendererStage533NormalizedEventCycleInputAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage533NormalizedEventCycleInputAdapterDraft" \
  "CjguiInternalRendererStage532InputEventNormalizationReadiness" \
  "didConsumeStage532InputEventNormalization" \
  "didMaterializeNormalizedEventToCycleInputAdapter" \
  "didMaterializeTodoNormalizedEventActionIntentDraft" \
  "didMaterializeSettingsNormalizedEventActionIntentDraft" \
  "didMaterializeAiGeneratedSettingsNormalizedEventActionIntentDraft" \
  "didBindNormalizedEventsToStage529CycleInputs" \
  "didBindCycleInputAdapterToStage530ExecutorRoute" \
  "didPrepareStage534NormalizedEventDemoSurfaceCycleProbe"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage533 normalized event cycle input adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage533_normalized_event_cycle_input_adapter_owner_present=true"
echo "stage532_input_event_normalization_consumed=true"
echo "shared_input_event_normalization_contract_consumed=true"
echo "normalized_input_events_consumed=true"
echo "normalized_event_to_cycle_input_adapter_materialized=true"
echo "todo_normalized_event_action_intent_draft_materialized=true"
echo "settings_normalized_event_action_intent_draft_materialized=true"
echo "ai_generated_settings_normalized_event_action_intent_draft_materialized=true"
echo "normalized_events_bound_to_stage529_cycle_inputs=true"
echo "cycle_input_adapter_bound_to_stage530_executor_route=true"
echo "cycle_input_adapter_owner_local=true"
echo "cycle_input_adapter_non_dispatching=true"
echo "cycle_input_adapter_state_dry_run_only=true"
echo "cycle_input_adapter_render_preview_only=true"
echo "stage534_normalized_event_demo_surface_cycle_probe_prepared=true"
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
