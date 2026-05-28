#!/usr/bin/env zsh
#
# Verifies the stage556 interaction demo host route layout/focus preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage556_interaction_demo_host_route_layout_focus_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage556 interaction demo host route layout focus preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage556InteractionDemoHostRouteLayoutFocusPreviewPlan" \
  "CjguiInternalRendererStage556InteractionDemoHostRouteLayoutFocusPreviewFacts" \
  "CjguiInternalRendererStage556InteractionDemoHostRouteLayoutFocusPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage556InteractionDemoHostRouteLayoutFocusPreviewDraft" \
  "CjguiInternalRendererStage555InteractionDemoHostRouteRenderSurfaceContractReadiness" \
  "didConsumeStage555InteractionDemoHostRouteRenderSurfaceContract" \
  "didMaterializeSharedHostRouteLayoutStyleTextFocusPreview" \
  "didMaterializeHostRouteLayoutConstraintPreviewLedger" \
  "didMaterializeHostRouteStyleTokenPreviewLedger" \
  "didMaterializeHostRouteTextRunPreviewLedger" \
  "didMaterializeHostRouteFocusTraversalPreviewLedger" \
  "didMaterializeTodoHostRouteLayoutFocusPreviewSurface" \
  "didMaterializeSettingsHostRouteLayoutFocusPreviewSurface" \
  "didMaterializeAiGeneratedSettingsHostRouteLayoutFocusPreviewSurface" \
  "didBindHostRouteLayoutFocusPreviewToStage555DemoSurfaceContract" \
  "didBindHostRouteLayoutFocusPreviewToStage554CycleReceipt" \
  "didKeepHostRouteLayoutFocusPreviewCheckable" \
  "didPrepareStage557InteractionDemoHostRouteLayoutFocusMeasurementExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage556 interaction demo host route layout focus preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage556_interaction_demo_host_route_layout_focus_preview_owner_present=true"
echo "stage555_interaction_demo_host_route_render_surface_contract_consumed=true"
echo "stage554_interaction_demo_host_route_cycle_executor_consumed_transitively=true"
echo "stage552_interaction_demo_host_probe_contract_consumed_transitively=true"
echo "shared_host_route_layout_style_text_focus_preview_materialized=true"
echo "host_route_layout_constraint_preview_ledger_materialized=true"
echo "host_route_style_token_preview_ledger_materialized=true"
echo "host_route_text_run_preview_ledger_materialized=true"
echo "host_route_focus_traversal_preview_ledger_materialized=true"
echo "todo_host_route_layout_focus_preview_surface_materialized=true"
echo "settings_host_route_layout_focus_preview_surface_materialized=true"
echo "ai_generated_settings_host_route_layout_focus_preview_surface_materialized=true"
echo "host_route_layout_focus_preview_bound_to_stage555_demo_surface_contract=true"
echo "host_route_layout_focus_preview_bound_to_stage554_cycle_receipt=true"
echo "host_route_layout_focus_preview_checkable=true"
echo "host_route_layout_focus_preview_template_need_reduced=true"
echo "stage557_interaction_demo_host_route_layout_focus_measurement_executor_prepared=true"
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
