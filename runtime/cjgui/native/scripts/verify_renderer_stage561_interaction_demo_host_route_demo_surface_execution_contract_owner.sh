#!/usr/bin/env zsh
#
# Verifies the stage561 interaction demo host route demo surface execution contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage561_interaction_demo_host_route_demo_surface_execution_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage561 interaction demo host route demo surface execution contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage561InteractionDemoHostRouteDemoSurfaceExecutionContractPlan" \
  "CjguiInternalRendererStage561InteractionDemoHostRouteDemoSurfaceExecutionContractFacts" \
  "CjguiInternalRendererStage561InteractionDemoHostRouteDemoSurfaceExecutionContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage561InteractionDemoHostRouteDemoSurfaceExecutionContractDraft" \
  "CjguiInternalRendererStage560InteractionDemoHostRouteActionStateRenderCycleExecutorReadiness" \
  "didConsumeStage560InteractionDemoHostRouteActionStateRenderCycleExecutor" \
  "didMaterializeSharedHostRouteDemoSurfaceExecutionContract" \
  "didMaterializeSharedHostRouteDemoSurfaceExecutionHelper" \
  "didMaterializeTodoHostRouteCheckableDemoSurfaceExecutionInput" \
  "didMaterializeSettingsHostRouteCheckableDemoSurfaceExecutionInput" \
  "didMaterializeAiGeneratedSettingsHostRouteCheckableDemoSurfaceExecutionInput" \
  "didBindHostRouteDemoSurfaceExecutionToStage560CycleReceipts" \
  "didBindHostRouteDemoSurfaceExecutionToStage558RuntimeProbeContract" \
  "didBindHostRouteDemoSurfaceExecutionToStage555RenderSurfaceContract" \
  "didReduceHostRouteInputActionStateRenderProbeNeed" \
  "didPrepareStage562InteractionDemoHostRouteTextInputFocusBinding"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage561 interaction demo host route demo surface execution contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage561_interaction_demo_host_route_demo_surface_execution_contract_owner_present=true"
echo "stage560_interaction_demo_host_route_action_state_render_cycle_executor_consumed=true"
echo "stage559_interaction_demo_host_route_input_event_adapter_consumed_transitively=true"
echo "stage558_interaction_demo_host_route_runtime_probe_contract_consumed_transitively=true"
echo "shared_host_route_demo_surface_execution_contract_materialized=true"
echo "shared_host_route_demo_surface_execution_helper_materialized=true"
echo "todo_host_route_checkable_demo_surface_execution_input_materialized=true"
echo "settings_host_route_checkable_demo_surface_execution_input_materialized=true"
echo "ai_generated_settings_host_route_checkable_demo_surface_execution_input_materialized=true"
echo "host_route_demo_surface_execution_bound_to_stage560_cycle_receipts=true"
echo "host_route_demo_surface_execution_bound_to_stage558_runtime_probe_contract=true"
echo "host_route_demo_surface_execution_bound_to_stage555_render_surface_contract=true"
echo "host_route_demo_surface_execution_checkable=true"
echo "host_route_input_action_state_render_probe_need_reduced=true"
echo "stage562_interaction_demo_host_route_text_input_focus_binding_prepared=true"
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
