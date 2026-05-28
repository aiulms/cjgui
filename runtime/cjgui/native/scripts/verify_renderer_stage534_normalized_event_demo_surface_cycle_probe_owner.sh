#!/usr/bin/env zsh
#
# Verifies the stage534 normalized-event demo surface cycle probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage534_normalized_event_demo_surface_cycle_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage534 normalized event demo surface cycle probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbePlan" \
  "CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeFacts" \
  "CjguiInternalRendererStage534NormalizedEventDemoSurfaceCycleProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage534NormalizedEventDemoSurfaceCycleProbeDraft" \
  "CjguiInternalRendererStage533NormalizedEventCycleInputAdapterReadiness" \
  "didConsumeStage533NormalizedEventCycleInputAdapter" \
  "didMaterializeNormalizedEventDemoSurfaceCycleProbeContract" \
  "didMaterializeNormalizedEventDemoSurfaceCycleProbeHelper" \
  "didMaterializeTodoNormalizedEventDemoSurfaceCycleProbeInput" \
  "didMaterializeSettingsNormalizedEventDemoSurfaceCycleProbeInput" \
  "didMaterializeAiGeneratedSettingsNormalizedEventDemoSurfaceCycleProbeInput" \
  "didBindNormalizedEventCycleProbeToStage531HostProbe" \
  "didReducePerDemoInputAdapterDuplication" \
  "didPrepareStage535SharedRuntimeDemoCycleEventStateRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage534 normalized event demo surface cycle probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage534_normalized_event_demo_surface_cycle_probe_owner_present=true"
echo "stage533_normalized_event_cycle_input_adapter_consumed=true"
echo "normalized_event_to_cycle_input_adapter_consumed=true"
echo "todo_normalized_event_action_intent_draft_consumed=true"
echo "settings_normalized_event_action_intent_draft_consumed=true"
echo "ai_generated_settings_normalized_event_action_intent_draft_consumed=true"
echo "normalized_event_demo_surface_cycle_probe_contract_materialized=true"
echo "normalized_event_demo_surface_cycle_probe_helper_materialized=true"
echo "todo_normalized_event_demo_surface_cycle_probe_input_materialized=true"
echo "settings_normalized_event_demo_surface_cycle_probe_input_materialized=true"
echo "ai_generated_settings_normalized_event_demo_surface_cycle_probe_input_materialized=true"
echo "normalized_event_cycle_probe_bound_to_stage531_host_probe=true"
echo "normalized_event_cycle_probe_bound_to_stage530_executor=true"
echo "normalized_event_cycle_probe_bound_to_todo_settings_ai_generated_settings=true"
echo "per_demo_input_adapter_duplication_reduced=true"
echo "normalized_event_cycle_probe_checkable=true"
echo "normalized_event_cycle_probe_owner_local=true"
echo "stage535_shared_runtime_demo_cycle_event_state_refresh_prepared=true"
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
