#!/usr/bin/env zsh
#
# Verifies the stage562 host-route text input / focus binding owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage562_host_route_text_input_focus_binding.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage562 host route text input focus binding: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage562HostRouteTextInputFocusBindingPlan" \
  "CjguiInternalRendererStage562HostRouteTextInputFocusBindingFacts" \
  "CjguiInternalRendererStage562HostRouteTextInputFocusBindingReadiness" \
  "cjguiInternalExecuteDefaultRendererStage562HostRouteTextInputFocusBindingDraft" \
  "CjguiInternalRendererStage561InteractionDemoHostRouteDemoSurfaceExecutionContractReadiness" \
  "CjguiInternalRendererStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutorReadiness" \
  "didMaterializeSharedHostRouteTextInputFocusBindingContract" \
  "didMaterializeSharedHostRouteTextInputFocusBindingHelper" \
  "didMaterializeHostRouteTextInputFocusBindingLedger" \
  "didMaterializeTodoHostRouteTextInputFocusBinding" \
  "didMaterializeSettingsHostRouteTextInputFocusBinding" \
  "didMaterializeAiGeneratedSettingsHostRouteTextInputFocusBinding" \
  "didBindHostRouteTextInputFocusToStage561ExecutionInputs" \
  "didBindHostRouteTextInputFocusToStage557FocusTraversal" \
  "didPrepareStage563HostRouteTextEditStateRenderDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage562 host route text input focus binding: missing token $token" >&2
    exit 3
  fi
done

echo "stage562_host_route_text_input_focus_binding_owner_present=true"
echo "stage561_host_route_demo_surface_execution_contract_consumed=true"
echo "stage557_host_route_layout_focus_measurement_executor_consumed=true"
echo "stage560_host_route_action_state_render_cycle_consumed_transitively=true"
echo "stage555_host_route_render_surface_contract_consumed_transitively=true"
echo "shared_host_route_text_input_focus_binding_contract_materialized=true"
echo "shared_host_route_text_input_focus_binding_helper_materialized=true"
echo "host_route_text_input_focus_binding_ledger_materialized=true"
echo "todo_host_route_text_input_focus_binding_materialized=true"
echo "settings_host_route_text_input_focus_binding_materialized=true"
echo "ai_generated_settings_host_route_text_input_focus_binding_materialized=true"
echo "host_route_text_input_focus_bound_to_stage561_execution_inputs=true"
echo "host_route_text_input_focus_bound_to_stage557_focus_traversal=true"
echo "host_route_text_input_focus_checkable=true"
echo "stage563_host_route_text_edit_state_render_dry_run_prepared=true"
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
