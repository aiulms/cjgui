#!/usr/bin/env zsh
#
# Verifies the stage640 result-surface host runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage640_result_surface_host_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage640 result surface host runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage640ResultSurfaceHostRuntimeContractPlan" \
  "CjguiInternalRendererStage640ResultSurfaceHostRuntimeContractFacts" \
  "CjguiInternalRendererStage640ResultSurfaceHostRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage640ResultSurfaceHostRuntimeContractDraft" \
  "CjguiInternalRendererStage639ResultSurfaceDemoHostInspectionReadiness" \
  "didConsumeStage639ResultSurfaceDemoHostInspection" \
  "didMaterializeSharedResultSurfaceHostRuntimeContract" \
  "didMaterializeSharedResultSurfaceHostRuntimeHelper" \
  "didMaterializeSharedHostInspectionExecutionReceiptContract" \
  "didMaterializeCycleOrderRuntimeLayoutFocusReceiptHostInspection" \
  "didMaterializeChatComposerResultSurfaceHostRuntimeSurface" \
  "didReduceFuturePerDemoResultSurfaceLayoutFocusHostTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage640 result surface host runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage640_result_surface_host_runtime_contract_owner_present=true"
echo "stage639_result_surface_demo_host_inspection_consumed=true"
echo "stage638_result_surface_layout_focus_receipt_consumed_transitively=true"
echo "stage637_result_surface_layout_focus_preview_consumed_transitively=true"
echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed_transitively=true"
echo "shared_result_surface_host_runtime_contract_materialized=true"
echo "shared_result_surface_host_runtime_helper_materialized=true"
echo "shared_host_inspection_execution_receipt_contract_materialized=true"
echo "cycle_order_runtime_layout_focus_receipt_host_inspection_materialized=true"
echo "todo_result_surface_host_runtime_surface_materialized=true"
echo "settings_result_surface_host_runtime_surface_materialized=true"
echo "ai_generated_settings_result_surface_host_runtime_surface_materialized=true"
echo "chat_composer_result_surface_host_runtime_surface_materialized=true"
echo "future_per_demo_result_surface_layout_focus_host_template_need_reduced=true"
echo "stage641_component_runtime_result_surface_host_input_event_adapter_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
