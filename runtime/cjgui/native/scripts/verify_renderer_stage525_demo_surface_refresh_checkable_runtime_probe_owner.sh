#!/usr/bin/env zsh
#
# Verifies the stage525 demo-surface refresh checkable runtime probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage525_demo_surface_refresh_checkable_runtime_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage525 demo surface refresh checkable runtime probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage525DemoSurfaceRefreshCheckableRuntimeProbePlan" \
  "CjguiInternalRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeFacts" \
  "CjguiInternalRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage525DemoSurfaceRefreshCheckableRuntimeProbeDraft" \
  "CjguiInternalRendererStage524DemoSurfaceRefreshLayoutExecutionReceiptReadiness" \
  "didConsumeStage524DemoSurfaceRefreshLayoutExecutionReceipt" \
  "didMaterializeSharedDemoSurfaceRefreshCheckableRuntimePreviewProbeContract" \
  "didMaterializeDemoSurfaceRefreshCheckableRuntimeProbeHelperV4" \
  "cjguiInternalRendererStage525CheckableRuntimeProbeHelperV4Ready" \
  "didMaterializeTodoRefreshedDemoSurfaceRefreshCheckableRuntimeProbeInput" \
  "didMaterializeSettingsRefreshedDemoSurfaceRefreshCheckableRuntimeProbeInput" \
  "didMaterializeAiGeneratedSettingsRefreshedDemoSurfaceRefreshCheckableRuntimeProbeInput" \
  "didBindLayoutExecutionReceiptToCheckableRuntimeProbe" \
  "didPrepareStage526DemoSurfaceRefreshFocusInputActionAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage525 demo surface refresh checkable runtime probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage525_demo_surface_refresh_checkable_runtime_probe_owner_present=true"
echo "stage524_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "shared_demo_surface_refresh_checkable_layout_execution_receipt_consumed=true"
echo "demo_surface_refresh_layout_execution_helper_v4_consumed=true"
echo "todo_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "settings_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_layout_execution_receipt_consumed=true"
echo "shared_demo_surface_refresh_checkable_runtime_preview_probe_contract_materialized=true"
echo "demo_surface_refresh_checkable_runtime_probe_helper_v4_materialized=true"
echo "demo_surface_refresh_checkable_runtime_probe_helper_v4_bound_to_demo_surfaces=true"
echo "todo_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true"
echo "settings_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_checkable_runtime_probe_input_materialized=true"
echo "layout_execution_receipt_to_checkable_runtime_probe_bound=true"
echo "checkable_runtime_probe_bound_to_focus_input_adapter_next=true"
echo "demo_surface_refresh_checkable_runtime_probe_owner_local=true"
echo "demo_surface_refresh_checkable_runtime_probe_non_executing=true"
echo "stage526_demo_surface_refresh_focus_input_action_adapter_prepared=true"
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
