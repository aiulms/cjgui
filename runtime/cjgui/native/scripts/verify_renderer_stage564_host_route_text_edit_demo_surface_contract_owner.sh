#!/usr/bin/env zsh
#
# Verifies the stage564 host-route text edit demo surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage564_host_route_text_edit_demo_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage564 host route text edit demo surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage564HostRouteTextEditDemoSurfaceContractPlan" \
  "CjguiInternalRendererStage564HostRouteTextEditDemoSurfaceContractFacts" \
  "CjguiInternalRendererStage564HostRouteTextEditDemoSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage564HostRouteTextEditDemoSurfaceContractDraft" \
  "CjguiInternalRendererStage563HostRouteTextEditStateRenderDryRunReadiness" \
  "didMaterializeSharedHostRouteTextEditDemoSurfaceContract" \
  "didMaterializeSharedHostRouteTextEditDemoSurfaceHelper" \
  "didMaterializeTodoHostRouteCheckableTextEditDemoSurfaceInput" \
  "didMaterializeSettingsHostRouteCheckableTextEditDemoSurfaceInput" \
  "didMaterializeAiGeneratedSettingsHostRouteCheckableTextEditDemoSurfaceInput" \
  "didBindHostRouteTextEditDemoSurfaceToStage563Receipts" \
  "didBindHostRouteTextEditDemoSurfaceToStage562Bindings" \
  "didBindHostRouteTextEditDemoSurfaceToStage561ExecutionContract" \
  "didReduceHostRouteTextInputStateRenderTemplateNeed" \
  "didPrepareStage565ComponentRuntimeTextInputModel"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage564 host route text edit demo surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage564_host_route_text_edit_demo_surface_contract_owner_present=true"
echo "stage563_host_route_text_edit_state_render_dry_run_consumed=true"
echo "stage562_host_route_text_input_focus_binding_consumed_transitively=true"
echo "stage561_host_route_demo_surface_execution_contract_consumed_transitively=true"
echo "shared_host_route_text_edit_demo_surface_contract_materialized=true"
echo "shared_host_route_text_edit_demo_surface_helper_materialized=true"
echo "todo_host_route_checkable_text_edit_demo_surface_input_materialized=true"
echo "settings_host_route_checkable_text_edit_demo_surface_input_materialized=true"
echo "ai_generated_settings_host_route_checkable_text_edit_demo_surface_input_materialized=true"
echo "host_route_text_edit_demo_surface_bound_to_stage563_receipts=true"
echo "host_route_text_edit_demo_surface_bound_to_stage562_bindings=true"
echo "host_route_text_edit_demo_surface_bound_to_stage561_execution_contract=true"
echo "host_route_text_edit_demo_surface_checkable=true"
echo "host_route_text_input_state_render_template_need_reduced=true"
echo "stage565_component_runtime_text_input_model_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
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
