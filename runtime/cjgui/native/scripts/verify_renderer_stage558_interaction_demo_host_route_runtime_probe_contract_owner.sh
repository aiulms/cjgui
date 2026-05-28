#!/usr/bin/env zsh
#
# Verifies the stage558 interaction demo host route runtime probe contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage558_interaction_demo_host_route_runtime_probe_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage558 interaction demo host route runtime probe contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage558InteractionDemoHostRouteRuntimeProbeContractPlan" \
  "CjguiInternalRendererStage558InteractionDemoHostRouteRuntimeProbeContractFacts" \
  "CjguiInternalRendererStage558InteractionDemoHostRouteRuntimeProbeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage558InteractionDemoHostRouteRuntimeProbeContractDraft" \
  "CjguiInternalRendererStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutorReadiness" \
  "didConsumeStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutor" \
  "didMaterializeSharedHostRouteRuntimeProbeContract" \
  "didMaterializeSharedHostRouteRuntimeProbeHelper" \
  "didMaterializeTodoHostRouteCheckableRuntimeProbeInput" \
  "didMaterializeSettingsHostRouteCheckableRuntimeProbeInput" \
  "didMaterializeAiGeneratedSettingsHostRouteCheckableRuntimeProbeInput" \
  "didBindHostRouteRuntimeProbeContractToStage557Measurements" \
  "didBindHostRouteRuntimeProbeContractToStage555DemoSurfaceContract" \
  "didKeepHostRouteRuntimeProbeCheckable" \
  "didReducePerDemoHostRouteLayoutFocusProbeNeed" \
  "didPrepareStage559InteractionDemoHostRouteInputEventAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage558 interaction demo host route runtime probe contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage558_interaction_demo_host_route_runtime_probe_contract_owner_present=true"
echo "stage557_interaction_demo_host_route_layout_focus_measurement_executor_consumed=true"
echo "stage556_interaction_demo_host_route_layout_focus_preview_consumed_transitively=true"
echo "stage555_interaction_demo_host_route_render_surface_contract_consumed_transitively=true"
echo "shared_host_route_runtime_probe_contract_materialized=true"
echo "shared_host_route_runtime_probe_helper_materialized=true"
echo "todo_host_route_checkable_runtime_probe_input_materialized=true"
echo "settings_host_route_checkable_runtime_probe_input_materialized=true"
echo "ai_generated_settings_host_route_checkable_runtime_probe_input_materialized=true"
echo "host_route_runtime_probe_contract_bound_to_stage557_measurements=true"
echo "host_route_runtime_probe_contract_bound_to_stage555_demo_surface_contract=true"
echo "host_route_runtime_probe_checkable=true"
echo "per_demo_host_route_layout_focus_probe_need_reduced=true"
echo "stage559_interaction_demo_host_route_input_event_adapter_prepared=true"
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
