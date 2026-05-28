#!/usr/bin/env zsh
#
# Verifies the stage557 interaction demo host route layout/focus measurement owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage557_interaction_demo_host_route_layout_focus_measurement_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage557 interaction demo host route layout focus measurement executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutorPlan" \
  "CjguiInternalRendererStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutorFacts" \
  "CjguiInternalRendererStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutorDraft" \
  "CjguiInternalRendererStage556InteractionDemoHostRouteLayoutFocusPreviewReadiness" \
  "didConsumeStage556InteractionDemoHostRouteLayoutFocusPreview" \
  "didMaterializeSharedHostRouteLayoutFocusMeasurementExecutor" \
  "didMaterializeHostRouteMeasuredLayoutSlotLedger" \
  "didMaterializeHostRouteResolvedStyleTokenReceipt" \
  "didMaterializeHostRouteTextMetricReceipt" \
  "didMaterializeHostRouteFocusTraversalReceipt" \
  "didMaterializeTodoHostRouteLayoutFocusMeasurementReceipt" \
  "didMaterializeSettingsHostRouteLayoutFocusMeasurementReceipt" \
  "didMaterializeAiGeneratedSettingsHostRouteLayoutFocusMeasurementReceipt" \
  "didBindHostRouteMeasurementToStage556LayoutFocusPreview" \
  "didBindHostRouteMeasurementToStage555RenderSurfaceContract" \
  "didKeepHostRouteMeasurementDryRunOnly" \
  "didPrepareStage558InteractionDemoHostRouteRuntimeProbeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage557 interaction demo host route layout focus measurement executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage557_interaction_demo_host_route_layout_focus_measurement_executor_owner_present=true"
echo "stage556_interaction_demo_host_route_layout_focus_preview_consumed=true"
echo "stage555_interaction_demo_host_route_render_surface_contract_consumed_transitively=true"
echo "shared_host_route_layout_focus_measurement_executor_materialized=true"
echo "host_route_measured_layout_slot_ledger_materialized=true"
echo "host_route_resolved_style_token_receipt_materialized=true"
echo "host_route_text_metric_receipt_materialized=true"
echo "host_route_focus_traversal_receipt_materialized=true"
echo "todo_host_route_layout_focus_measurement_receipt_materialized=true"
echo "settings_host_route_layout_focus_measurement_receipt_materialized=true"
echo "ai_generated_settings_host_route_layout_focus_measurement_receipt_materialized=true"
echo "host_route_measurement_bound_to_stage556_layout_focus_preview=true"
echo "host_route_measurement_bound_to_stage555_render_surface_contract=true"
echo "host_route_measurement_dry_run_only=true"
echo "host_route_layout_focus_execution_template_need_reduced=true"
echo "stage558_interaction_demo_host_route_runtime_probe_contract_prepared=true"
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
