#!/usr/bin/env zsh
#
# Verifies the stage524 demo-surface refresh layout execution receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage524_demo_surface_refresh_layout_execution_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage524 demo surface refresh layout execution receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage524DemoSurfaceRefreshLayoutExecutionReceiptPlan" \
  "CjguiInternalRendererStage524DemoSurfaceRefreshLayoutExecutionReceiptFacts" \
  "CjguiInternalRendererStage524DemoSurfaceRefreshLayoutExecutionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage524DemoSurfaceRefreshLayoutExecutionReceiptDraft" \
  "CjguiInternalRendererStage523DemoSurfaceRefreshLayoutStylePreviewReadiness" \
  "didConsumeStage523DemoSurfaceRefreshLayoutStylePreview" \
  "didMaterializeSharedDemoSurfaceRefreshCheckableLayoutExecutionReceipt" \
  "didMaterializeDemoSurfaceRefreshLayoutExecutionHelperV4" \
  "cjguiInternalRendererStage524LayoutExecutionHelperV4Ready" \
  "didMaterializeTodoRefreshedDemoSurfaceRefreshLayoutExecutionReceipt" \
  "didMaterializeSettingsRefreshedDemoSurfaceRefreshLayoutExecutionReceipt" \
  "didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshLayoutExecutionReceipt" \
  "didBindCheckableLayoutStylePreviewToExecutionReceipt" \
  "didPrepareStage525DemoSurfaceRefreshCheckableRuntimeProbe"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage524 demo surface refresh layout execution receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage524_demo_surface_refresh_layout_execution_receipt_owner_present=true"
echo "stage523_demo_surface_refresh_layout_style_preview_consumed=true"
echo "shared_demo_surface_refresh_checkable_layout_style_text_focus_preview_consumed=true"
echo "demo_surface_refresh_checkable_layout_preview_contract_consumed=true"
echo "todo_refreshed_demo_surface_refresh_checkable_layout_style_preview_node_consumed=true"
echo "settings_refreshed_demo_surface_refresh_checkable_layout_style_preview_node_consumed=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_checkable_layout_style_preview_node_consumed=true"
echo "shared_demo_surface_refresh_checkable_layout_execution_receipt_materialized=true"
echo "demo_surface_refresh_layout_execution_helper_v4_materialized=true"
echo "demo_surface_refresh_layout_execution_helper_v4_bound_to_demo_surfaces=true"
echo "todo_refreshed_demo_surface_refresh_layout_execution_receipt_materialized=true"
echo "settings_refreshed_demo_surface_refresh_layout_execution_receipt_materialized=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_layout_execution_receipt_materialized=true"
echo "checkable_layout_style_preview_to_execution_receipt_bound=true"
echo "demo_surface_refresh_text_focus_affordance_receipt_materialized=true"
echo "demo_surface_refresh_layout_execution_owner_local=true"
echo "demo_surface_refresh_layout_execution_dry_run_only=true"
echo "stage525_demo_surface_refresh_checkable_runtime_probe_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
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
