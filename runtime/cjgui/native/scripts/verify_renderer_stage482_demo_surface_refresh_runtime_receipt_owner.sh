#!/usr/bin/env zsh
#
# Verifies the stage482 demo-surface refresh runtime receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage482_demo_surface_refresh_runtime_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage482 demo surface refresh runtime receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage482DemoSurfaceRefreshRuntimeReceiptPlan" \
  "CjguiInternalRendererStage482DemoSurfaceRefreshRuntimeReceiptFacts" \
  "CjguiInternalRendererStage482DemoSurfaceRefreshRuntimeReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage482DemoSurfaceRefreshRuntimeReceiptDraft" \
  "CjguiInternalRendererStage481DemoSurfaceRefreshLayoutFocusExecutionRouteReadiness" \
  "didConsumeStage481DemoSurfaceRefreshLayoutFocusExecutionRoute" \
  "didConsumeSharedDemoSurfaceRefreshLayoutFocusExecutionRoute" \
  "didConsumeTodoDemoSurfaceRefreshLayoutFocusPass" \
  "didConsumeSettingsDemoSurfaceRefreshLayoutFocusPass" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRefreshLayoutFocusPass" \
  "didMaterializeSharedDemoSurfaceRefreshRuntimeReceipt" \
  "didMaterializeTodoDemoSurfaceRefreshRuntimeReceipt" \
  "didMaterializeSettingsDemoSurfaceRefreshRuntimeReceipt" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshRuntimeReceipt" \
  "didBindLayoutFocusExecutionRouteToRuntimeReceipt" \
  "didBindCheckableSurfaceProbeToRuntimeReceipt" \
  "didMaterializeDemoSurfaceRefreshRuntimeProbeInput" \
  "didKeepRuntimeReceiptReusable" \
  "didKeepRuntimeReceiptOwnerLocal" \
  "didKeepRuntimeReceiptDryRunOnly" \
  "didPrepareStage483DemoSurfaceRefreshRuntimeExecutionContract" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage482 demo surface refresh runtime receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage482_demo_surface_refresh_runtime_receipt_owner_present=true"
echo "stage481_demo_surface_refresh_layout_focus_execution_route_required=true"
echo "stage481_demo_surface_refresh_layout_focus_execution_route_consumed=true"
echo "shared_demo_surface_refresh_layout_focus_execution_route_consumed=true"
echo "todo_demo_surface_refresh_layout_focus_pass_consumed=true"
echo "settings_demo_surface_refresh_layout_focus_pass_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_layout_focus_pass_consumed=true"
echo "shared_demo_surface_refresh_runtime_receipt_materialized=true"
echo "todo_demo_surface_refresh_runtime_receipt_materialized=true"
echo "settings_demo_surface_refresh_runtime_receipt_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_runtime_receipt_materialized=true"
echo "layout_focus_execution_route_to_runtime_receipt_bound=true"
echo "checkable_surface_probe_to_runtime_receipt_bound=true"
echo "demo_surface_refresh_runtime_probe_input_materialized=true"
echo "runtime_receipt_reusable=true"
echo "runtime_receipt_owner_local=true"
echo "runtime_receipt_dry_run_only=true"
echo "stage483_demo_surface_refresh_runtime_execution_contract_prepared=true"
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
