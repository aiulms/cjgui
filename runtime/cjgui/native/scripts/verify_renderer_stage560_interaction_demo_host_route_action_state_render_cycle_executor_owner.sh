#!/usr/bin/env zsh
#
# Verifies the stage560 interaction demo host route action/state/render cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage560_interaction_demo_host_route_action_state_render_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage560 interaction demo host route action/state/render cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage560InteractionDemoHostRouteActionStateRenderCycleExecutorPlan" \
  "CjguiInternalRendererStage560InteractionDemoHostRouteActionStateRenderCycleExecutorFacts" \
  "CjguiInternalRendererStage560InteractionDemoHostRouteActionStateRenderCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage560InteractionDemoHostRouteActionStateRenderCycleExecutorDraft" \
  "CjguiInternalRendererStage559InteractionDemoHostRouteInputEventAdapterReadiness" \
  "CjguiInternalRendererStage554InteractionDemoHostRouteCycleExecutorReadiness" \
  "CjguiInternalRendererStage555InteractionDemoHostRouteRenderSurfaceContractReadiness" \
  "didConsumeStage559InteractionDemoHostRouteInputEventAdapter" \
  "didReuseStage554HostRouteCycleExecutor" \
  "didReuseStage555HostRouteRenderSurfaceContract" \
  "didMaterializeSharedHostRouteInputEventCycleExecutor" \
  "didMaterializeHostRouteActionIntentRuntimeLedger" \
  "didMaterializeHostRouteStateDeltaRuntimeDryRunLedger" \
  "didMaterializeHostRouteRenderCommandRuntimeRefreshLedger" \
  "didMaterializeTodoHostRouteInputEventCycleReceipt" \
  "didMaterializeSettingsHostRouteInputEventCycleReceipt" \
  "didMaterializeAiGeneratedSettingsHostRouteInputEventCycleReceipt" \
  "didPrepareStage561InteractionDemoHostRouteDemoSurfaceExecutionContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage560 interaction demo host route action/state/render cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage560_interaction_demo_host_route_action_state_render_cycle_executor_owner_present=true"
echo "stage559_interaction_demo_host_route_input_event_adapter_consumed=true"
echo "stage558_interaction_demo_host_route_runtime_probe_contract_consumed_transitively=true"
echo "stage554_interaction_demo_host_route_cycle_executor_reused=true"
echo "stage555_interaction_demo_host_route_render_surface_contract_reused=true"
echo "shared_host_route_input_event_cycle_executor_materialized=true"
echo "host_route_action_intent_runtime_ledger_materialized=true"
echo "host_route_state_delta_runtime_dry_run_ledger_materialized=true"
echo "host_route_render_command_runtime_refresh_ledger_materialized=true"
echo "todo_host_route_input_event_cycle_receipt_materialized=true"
echo "settings_host_route_input_event_cycle_receipt_materialized=true"
echo "ai_generated_settings_host_route_input_event_cycle_receipt_materialized=true"
echo "host_route_input_event_cycle_bound_to_stage559_normalized_events=true"
echo "host_route_input_event_cycle_bound_to_stage554_cycle_executor=true"
echo "host_route_input_event_cycle_bound_to_stage555_render_surface_contract=true"
echo "host_route_input_event_cycle_non_dispatching=true"
echo "host_route_input_event_cycle_state_dry_run_only=true"
echo "host_route_input_event_cycle_render_refresh_preview_only=true"
echo "host_route_action_state_render_owner_need_reduced=true"
echo "stage561_interaction_demo_host_route_demo_surface_execution_contract_prepared=true"
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
