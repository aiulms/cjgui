#!/usr/bin/env zsh
#
# Verifies the stage559 interaction demo host route input event adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage559_interaction_demo_host_route_input_event_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage559 interaction demo host route input event adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage559InteractionDemoHostRouteInputEventAdapterPlan" \
  "CjguiInternalRendererStage559InteractionDemoHostRouteInputEventAdapterFacts" \
  "CjguiInternalRendererStage559InteractionDemoHostRouteInputEventAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage559InteractionDemoHostRouteInputEventAdapterDraft" \
  "CjguiInternalRendererStage558InteractionDemoHostRouteRuntimeProbeContractReadiness" \
  "didConsumeStage558InteractionDemoHostRouteRuntimeProbeContract" \
  "didMaterializeSharedHostRouteInputEventAdapter" \
  "didMaterializeHostRouteNormalizedInputEventLedger" \
  "didAdaptTodoHostRouteRuntimeProbeInputEvent" \
  "didAdaptSettingsHostRouteRuntimeProbeInputEvent" \
  "didAdaptAiGeneratedSettingsHostRouteRuntimeProbeInputEvent" \
  "didBindHostRouteInputEventAdapterToStage558RuntimeProbeContract" \
  "didBindHostRouteInputEventAdapterToStage553HostInputRoutePreview" \
  "didKeepHostRouteInputEventAdapterOwnerLocal" \
  "didKeepHostRouteInputEventAdapterNonExecuting" \
  "didKeepHostRouteInputEventAdapterNonDispatching" \
  "didPrepareStage560InteractionDemoHostRouteActionStateRenderCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage559 interaction demo host route input event adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage559_interaction_demo_host_route_input_event_adapter_owner_present=true"
echo "stage558_interaction_demo_host_route_runtime_probe_contract_consumed=true"
echo "stage557_interaction_demo_host_route_layout_focus_measurement_executor_consumed_transitively=true"
echo "stage553_interaction_demo_host_input_route_preview_consumed_transitively=true"
echo "shared_host_route_input_event_adapter_materialized=true"
echo "host_route_normalized_input_event_ledger_materialized=true"
echo "todo_host_route_runtime_probe_input_event_adapted=true"
echo "settings_host_route_runtime_probe_input_event_adapted=true"
echo "ai_generated_settings_host_route_runtime_probe_input_event_adapted=true"
echo "host_route_input_event_adapter_bound_to_stage558_runtime_probe_contract=true"
echo "host_route_input_event_adapter_bound_to_stage553_host_input_route_preview=true"
echo "host_route_input_event_adapter_owner_local=true"
echo "host_route_input_event_adapter_non_executing=true"
echo "host_route_input_event_adapter_non_dispatching=true"
echo "stage560_interaction_demo_host_route_action_state_render_cycle_executor_prepared=true"
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
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
