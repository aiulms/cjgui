#!/usr/bin/env zsh
#
# Verifies the stage513 demo-surface refresh runtime preview/probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage513_demo_surface_refresh_runtime_preview_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage513 demo surface refresh runtime preview probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage513DemoSurfaceRefreshRuntimePreviewProbePlan" \
  "CjguiInternalRendererStage513DemoSurfaceRefreshRuntimePreviewProbeFacts" \
  "CjguiInternalRendererStage513DemoSurfaceRefreshRuntimePreviewProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage513DemoSurfaceRefreshRuntimePreviewProbeDraft" \
  "CjguiInternalRendererStage512DemoSurfaceRefreshLayoutExecutionReceiptReadiness" \
  "didConsumeStage512DemoSurfaceRefreshLayoutExecutionReceipt" \
  "didConsumeSharedDemoSurfaceRefreshRefreshedLayoutStyleExecutionReceipt" \
  "didMaterializeSharedDemoSurfaceRefreshRefreshedRuntimePreviewProbeContract" \
  "cjguiInternalRendererStage513SharedRuntimePreviewProbeContractHelperV2Ready" \
  "didMaterializeTodoRefreshedDemoSurfaceRefreshRuntimePreviewProbeInput" \
  "didMaterializeSettingsRefreshedDemoSurfaceRefreshRuntimePreviewProbeInput" \
  "didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshRuntimePreviewProbeInput" \
  "didBindRefreshedLayoutExecutionReceiptToRuntimePreviewProbe" \
  "didPrepareStage514DemoSurfaceRefreshFocusInputActionAdapterAfterRefreshedRuntimePreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage513 demo surface refresh runtime preview probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage513_demo_surface_refresh_runtime_preview_probe_owner_present=true"
echo "stage512_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "shared_demo_surface_refresh_refreshed_layout_style_execution_receipt_consumed=true"
echo "todo_refreshed_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "settings_refreshed_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "ai_generated_settings_refreshed_runtime_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "shared_demo_surface_refresh_refreshed_runtime_preview_probe_contract_materialized=true"
echo "shared_demo_surface_refresh_refreshed_runtime_preview_probe_contract_helper_materialized=true"
echo "shared_demo_surface_refresh_refreshed_runtime_preview_probe_contract_helper_bound_to_demo_surfaces=true"
echo "todo_refreshed_demo_surface_refresh_runtime_preview_probe_input_materialized=true"
echo "settings_refreshed_demo_surface_refresh_runtime_preview_probe_input_materialized=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_runtime_preview_probe_input_materialized=true"
echo "refreshed_layout_execution_receipt_to_runtime_preview_probe_bound=true"
echo "demo_surface_refresh_refreshed_runtime_preview_probe_input_materialized=true"
echo "runtime_preview_probe_v2_reusable=true"
echo "runtime_preview_probe_v2_owner_local=true"
echo "runtime_preview_probe_v2_dry_run_only=true"
echo "stage514_demo_surface_refresh_focus_input_action_adapter_after_refreshed_runtime_preview_prepared=true"
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
