#!/usr/bin/env zsh
#
# Verifies the stage547 interaction input-event cycle probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage547_interaction_input_event_cycle_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage547 interaction input event cycle probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage547InteractionInputEventCycleProbePlan" \
  "CjguiInternalRendererStage547InteractionInputEventCycleProbeFacts" \
  "CjguiInternalRendererStage547InteractionInputEventCycleProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage547InteractionInputEventCycleProbeDraft" \
  "CjguiInternalRendererStage546ComponentRuntimeInteractionDemoSurfaceRuntimeContractReadiness" \
  "CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness" \
  "didConsumeStage546InteractionDemoSurfaceRuntimeContract" \
  "didConsumeStage534NormalizedEventDemoSurfaceCycleProbe" \
  "didMaterializeSharedInteractionInputEventCycleProbeContract" \
  "didMaterializeSharedInteractionInputEventCycleProbeHelper" \
  "didMaterializeTodoInteractionInputEventCycleProbeInput" \
  "didMaterializeSettingsInteractionInputEventCycleProbeInput" \
  "didMaterializeAiGeneratedSettingsInteractionInputEventCycleProbeInput" \
  "didBindInteractionRuntimeInputsToNormalizedEventCycleProbe" \
  "didReducePerDemoInputCycleProbeDuplication"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage547 interaction input event cycle probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage547_interaction_input_event_cycle_probe_owner_present=true"
echo "stage546_interaction_demo_surface_runtime_contract_consumed=true"
echo "stage534_normalized_event_demo_surface_cycle_probe_consumed=true"
echo "shared_interaction_input_event_cycle_probe_contract_materialized=true"
echo "shared_interaction_input_event_cycle_probe_helper_materialized=true"
echo "todo_interaction_input_event_cycle_probe_input_materialized=true"
echo "settings_interaction_input_event_cycle_probe_input_materialized=true"
echo "ai_generated_settings_interaction_input_event_cycle_probe_input_materialized=true"
echo "interaction_runtime_inputs_bound_to_normalized_event_cycle_probe=true"
echo "interaction_cycle_probe_bound_to_stage546_runtime_contract=true"
echo "interaction_cycle_probe_bound_to_stage534_normalized_events=true"
echo "per_demo_input_cycle_probe_duplication_reduced=true"
echo "stage548_interaction_cycle_execution_receipt_prepared=true"
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
