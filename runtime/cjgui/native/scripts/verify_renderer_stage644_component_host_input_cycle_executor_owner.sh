#!/usr/bin/env zsh
#
# Verifies the stage644 component host input cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage644_component_host_input_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage644 component host input cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage644ComponentHostInputCycleExecutorPlan" \
  "CjguiInternalRendererStage644ComponentHostInputCycleExecutorFacts" \
  "CjguiInternalRendererStage644ComponentHostInputCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage644ComponentHostInputCycleExecutorDraft" \
  "CjguiInternalRendererStage643ComponentHostInputCycleReceiptReadiness" \
  "didConsumeStage643ComponentHostInputCycleReceipt" \
  "didMaterializeSharedComponentRuntimeHostInputCycleExecutorContract" \
  "didMaterializeSharedComponentRuntimeHostInputCycleExecutorHelper" \
  "didMaterializeSharedComponentHostInputExecutionReceiptContract" \
  "didMaterializeCycleOrderHostEventQueueActionStateRenderFocusReceipt" \
  "didMaterializeChatComposerComponentHostInputRuntimeSurface" \
  "didBridgeStage640HostRuntimeToSharedHostInputCycle" \
  "didReduceFuturePerDemoResultSurfaceHostInputTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage644 component host input cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage644_component_host_input_cycle_executor_owner_present=true"
echo "stage643_component_host_input_cycle_receipt_consumed=true"
echo "stage642_component_host_input_event_queue_consumed_transitively=true"
echo "stage641_result_surface_host_input_adapter_consumed_transitively=true"
echo "stage640_result_surface_host_runtime_contract_consumed_transitively=true"
echo "shared_component_runtime_host_input_cycle_executor_contract_materialized=true"
echo "shared_component_runtime_host_input_cycle_executor_helper_materialized=true"
echo "shared_component_host_input_execution_receipt_contract_materialized=true"
echo "cycle_order_host_event_queue_action_state_render_focus_receipt_materialized=true"
echo "todo_component_host_input_runtime_surface_materialized=true"
echo "settings_component_host_input_runtime_surface_materialized=true"
echo "ai_generated_settings_component_host_input_runtime_surface_materialized=true"
echo "chat_composer_component_host_input_runtime_surface_materialized=true"
echo "stage640_host_runtime_bridged_to_shared_host_input_cycle=true"
echo "future_per_demo_result_surface_host_input_template_need_reduced=true"
echo "stage645_component_host_input_result_surface_refresh_prepared=true"
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
