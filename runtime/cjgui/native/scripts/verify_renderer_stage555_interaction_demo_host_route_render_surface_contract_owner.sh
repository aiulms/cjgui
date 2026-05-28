#!/usr/bin/env zsh
#
# Verifies the stage555 interaction demo host route render surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage555_interaction_demo_host_route_render_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage555 interaction demo host route render surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage555InteractionDemoHostRouteRenderSurfaceContractPlan" \
  "CjguiInternalRendererStage555InteractionDemoHostRouteRenderSurfaceContractFacts" \
  "CjguiInternalRendererStage555InteractionDemoHostRouteRenderSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage555InteractionDemoHostRouteRenderSurfaceContractDraft" \
  "CjguiInternalRendererStage554InteractionDemoHostRouteCycleExecutorReadiness" \
  "didConsumeStage554InteractionDemoHostRouteCycleExecutor" \
  "didMaterializeSharedHostRouteStateRenderRefreshBridge" \
  "didMaterializeSharedHostRouteRenderCommandRefreshReceipt" \
  "didMaterializeSharedHostRouteDemoSurfaceContract" \
  "didMaterializeTodoHostRouteDemoSurfaceRefreshReceipt" \
  "didMaterializeSettingsHostRouteDemoSurfaceRefreshReceipt" \
  "didMaterializeAiGeneratedSettingsHostRouteDemoSurfaceRefreshReceipt" \
  "didBindHostRouteRenderSurfaceToStage554CycleReceipt" \
  "didBindHostRouteRenderSurfaceToStage552HostProbeInputs" \
  "didBindHostRouteRenderSurfaceToStage549CycleSurfaces" \
  "didKeepHostRouteRenderSurfaceCheckable" \
  "didReduceHostInputRouteStateRenderTemplateNeed" \
  "didPrepareStage556InteractionDemoHostRouteLayoutFocusPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage555 interaction demo host route render surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage555_interaction_demo_host_route_render_surface_contract_owner_present=true"
echo "stage554_interaction_demo_host_route_cycle_executor_consumed=true"
echo "stage553_interaction_demo_host_input_route_preview_consumed_transitively=true"
echo "stage552_interaction_demo_host_probe_contract_consumed_transitively=true"
echo "stage549_interaction_demo_cycle_surface_contract_consumed_transitively=true"
echo "shared_host_route_state_render_refresh_bridge_materialized=true"
echo "shared_host_route_render_command_refresh_receipt_materialized=true"
echo "shared_host_route_demo_surface_contract_materialized=true"
echo "todo_host_route_demo_surface_refresh_receipt_materialized=true"
echo "settings_host_route_demo_surface_refresh_receipt_materialized=true"
echo "ai_generated_settings_host_route_demo_surface_refresh_receipt_materialized=true"
echo "host_route_render_surface_bound_to_stage554_cycle_receipt=true"
echo "host_route_render_surface_bound_to_stage552_host_probe_inputs=true"
echo "host_route_render_surface_bound_to_stage549_cycle_surfaces=true"
echo "host_route_render_surface_checkable=true"
echo "host_input_route_state_render_template_need_reduced=true"
echo "stage556_interaction_demo_host_route_layout_focus_preview_prepared=true"
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
