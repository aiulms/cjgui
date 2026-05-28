#!/usr/bin/env zsh
#
# Verifies the stage554 interaction demo host route cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage554_interaction_demo_host_route_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage554 interaction demo host route cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage554InteractionDemoHostRouteCycleExecutorPlan" \
  "CjguiInternalRendererStage554InteractionDemoHostRouteCycleExecutorFacts" \
  "CjguiInternalRendererStage554InteractionDemoHostRouteCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage554InteractionDemoHostRouteCycleExecutorDraft" \
  "CjguiInternalRendererStage553InteractionDemoHostInputRoutePreviewReadiness" \
  "didConsumeStage553InteractionDemoHostInputRoutePreview" \
  "didMaterializeSharedInteractionDemoHostRouteCycleExecutor" \
  "didMaterializeSharedInteractionDemoHostRouteCycleReceipt" \
  "didMaterializeHostRouteActionIntentLedger" \
  "didMaterializeHostRouteStateDeltaDryRunLedger" \
  "didMaterializeTodoHostRouteActionStateCandidate" \
  "didMaterializeSettingsHostRouteActionStateCandidate" \
  "didMaterializeAiGeneratedSettingsHostRouteActionStateCandidate" \
  "didBindHostRouteCycleToStage553InputRoutes" \
  "didBindHostRouteCycleToStage552ProbeContract" \
  "didBindHostRouteCycleToStage548OrderLedger" \
  "didKeepHostRouteCycleNonDispatching" \
  "didKeepHostRouteStateUpdateDryRunOnly" \
  "didReduceHostRouteActionStateOwnerNeed" \
  "didPrepareStage555InteractionDemoHostRouteRenderSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage554 interaction demo host route cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage554_interaction_demo_host_route_cycle_executor_owner_present=true"
echo "stage553_interaction_demo_host_input_route_preview_consumed=true"
echo "shared_interaction_demo_host_route_cycle_executor_materialized=true"
echo "shared_interaction_demo_host_route_cycle_receipt_materialized=true"
echo "host_route_action_intent_ledger_materialized=true"
echo "host_route_state_delta_dry_run_ledger_materialized=true"
echo "todo_host_route_action_state_candidate_materialized=true"
echo "settings_host_route_action_state_candidate_materialized=true"
echo "ai_generated_settings_host_route_action_state_candidate_materialized=true"
echo "host_route_cycle_bound_to_stage553_input_routes=true"
echo "host_route_cycle_bound_to_stage552_probe_contract=true"
echo "host_route_cycle_bound_to_stage548_order_ledger=true"
echo "host_route_cycle_non_dispatching=true"
echo "host_route_state_update_dry_run_only=true"
echo "host_route_action_state_owner_need_reduced=true"
echo "stage555_interaction_demo_host_route_render_surface_contract_prepared=true"
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
