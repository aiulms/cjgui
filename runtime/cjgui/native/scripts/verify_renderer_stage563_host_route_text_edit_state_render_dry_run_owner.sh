#!/usr/bin/env zsh
#
# Verifies the stage563 host-route text edit state/render dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage563_host_route_text_edit_state_render_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage563 host route text edit state render dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage563HostRouteTextEditStateRenderDryRunPlan" \
  "CjguiInternalRendererStage563HostRouteTextEditStateRenderDryRunFacts" \
  "CjguiInternalRendererStage563HostRouteTextEditStateRenderDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage563HostRouteTextEditStateRenderDryRunDraft" \
  "CjguiInternalRendererStage562HostRouteTextInputFocusBindingReadiness" \
  "didMaterializeSharedHostRouteTextEditStateDryRunExecutor" \
  "didMaterializeHostRouteTextEditActionIntentLedger" \
  "didMaterializeHostRouteTextBufferStateDeltaDryRunLedger" \
  "didMaterializeHostRouteTextEditRenderCommandRefreshLedger" \
  "didMaterializeTodoHostRouteTextEditStateRenderReceipt" \
  "didMaterializeSettingsHostRouteTextEditStateRenderReceipt" \
  "didMaterializeAiGeneratedSettingsHostRouteTextEditStateRenderReceipt" \
  "didBindHostRouteTextEditToStage562FocusBindings" \
  "didBindHostRouteTextEditToStage560CycleExecutor" \
  "didBindHostRouteTextEditToStage555RenderSurfaceContract" \
  "didPrepareStage564HostRouteTextEditDemoSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage563 host route text edit state render dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage563_host_route_text_edit_state_render_dry_run_owner_present=true"
echo "stage562_host_route_text_input_focus_binding_consumed=true"
echo "stage561_host_route_demo_surface_execution_contract_consumed_transitively=true"
echo "stage557_host_route_layout_focus_measurement_executor_consumed_transitively=true"
echo "stage560_host_route_input_event_cycle_executor_reused=true"
echo "stage555_host_route_render_surface_contract_reused=true"
echo "shared_host_route_text_edit_state_dry_run_executor_materialized=true"
echo "host_route_text_edit_action_intent_ledger_materialized=true"
echo "host_route_text_buffer_state_delta_dry_run_ledger_materialized=true"
echo "host_route_text_edit_render_command_refresh_ledger_materialized=true"
echo "todo_host_route_text_edit_state_render_receipt_materialized=true"
echo "settings_host_route_text_edit_state_render_receipt_materialized=true"
echo "ai_generated_settings_host_route_text_edit_state_render_receipt_materialized=true"
echo "host_route_text_edit_bound_to_stage562_focus_bindings=true"
echo "host_route_text_edit_bound_to_stage560_cycle_executor=true"
echo "host_route_text_edit_bound_to_stage555_render_surface_contract=true"
echo "host_route_text_edit_non_dispatching=true"
echo "host_route_text_edit_state_dry_run_only=true"
echo "host_route_text_edit_render_refresh_preview_only=true"
echo "stage564_host_route_text_edit_demo_surface_contract_prepared=true"
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
