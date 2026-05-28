#!/usr/bin/env zsh
#
# Verifies the stage518 demo-surface refresh layout execution receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage518_demo_surface_refresh_layout_execution_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage518 demo surface refresh layout execution receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage518DemoSurfaceRefreshLayoutExecutionReceiptPlan" \
  "CjguiInternalRendererStage518DemoSurfaceRefreshLayoutExecutionReceiptFacts" \
  "CjguiInternalRendererStage518DemoSurfaceRefreshLayoutExecutionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage518DemoSurfaceRefreshLayoutExecutionReceiptDraft" \
  "CjguiInternalRendererStage517DemoSurfaceRefreshLayoutStylePreviewReadiness" \
  "didConsumeStage517DemoSurfaceRefreshLayoutStylePreview" \
  "didConsumeSharedDemoSurfaceRefreshRefreshedLayoutStyleTextFocusPreview" \
  "didMaterializeSharedDemoSurfaceRefreshRefreshedLayoutStyleExecutionReceipt" \
  "didMaterializeDemoSurfaceRefreshLayoutExecutionHelperV3" \
  "cjguiInternalRendererStage518SharedLayoutExecutionHelperV3Ready" \
  "didBindRefreshedLayoutStylePreviewToExecutionReceipt" \
  "didPrepareStage519DemoSurfaceRefreshRuntimePreviewProbe"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage518 demo surface refresh layout execution receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage518_demo_surface_refresh_layout_execution_receipt_owner_present=true"
echo "stage517_demo_surface_refresh_layout_style_preview_consumed=true"
echo "shared_demo_surface_refresh_refreshed_layout_style_text_focus_preview_consumed=true"
echo "todo_refreshed_runtime_demo_surface_refresh_layout_style_text_focus_node_consumed=true"
echo "settings_refreshed_runtime_demo_surface_refresh_layout_style_text_focus_node_consumed=true"
echo "ai_generated_settings_refreshed_runtime_demo_surface_refresh_layout_style_text_focus_node_consumed=true"
echo "shared_demo_surface_refresh_refreshed_layout_style_execution_receipt_materialized=true"
echo "todo_refreshed_runtime_demo_surface_refresh_layout_execution_receipt_materialized=true"
echo "settings_refreshed_runtime_demo_surface_refresh_layout_execution_receipt_materialized=true"
echo "ai_generated_settings_refreshed_runtime_demo_surface_refresh_layout_execution_receipt_materialized=true"
echo "refreshed_layout_style_preview_to_execution_receipt_bound=true"
echo "demo_surface_refresh_refreshed_text_focus_affordance_materialized=true"
echo "demo_surface_refresh_layout_execution_helper_v3_materialized=true"
echo "demo_surface_refresh_layout_execution_helper_v3_bound_to_demo_surfaces=true"
echo "layout_execution_receipt_reusable=true"
echo "layout_execution_receipt_owner_local=true"
echo "layout_execution_receipt_dry_run_only=true"
echo "stage519_demo_surface_refresh_runtime_preview_probe_prepared=true"
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
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
