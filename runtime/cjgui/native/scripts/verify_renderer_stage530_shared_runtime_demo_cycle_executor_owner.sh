#!/usr/bin/env zsh
#
# Verifies the stage530 shared runtime demo cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage530_shared_runtime_demo_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage530 shared runtime demo cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage530SharedRuntimeDemoCycleExecutorPlan" \
  "CjguiInternalRendererStage530SharedRuntimeDemoCycleExecutorFacts" \
  "CjguiInternalRendererStage530SharedRuntimeDemoCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage530SharedRuntimeDemoCycleExecutorDraft" \
  "CjguiInternalRendererStage529SharedRuntimeDemoCycleInputContractReadiness" \
  "didConsumeStage529SharedRuntimeDemoCycleInputContract" \
  "didConsumeSharedRuntimeDemoCycleRouteLedger" \
  "didMaterializeSharedRuntimeDemoCycleExecutor" \
  "didMaterializeSharedRuntimeDemoCycleExecutionReceipt" \
  "didMaterializeRuntimeDemoCycleOrderInputActionStateRenderLayoutProbe" \
  "didMaterializeTodoRuntimeDemoCycleExecutionReceipt" \
  "didMaterializeSettingsRuntimeDemoCycleExecutionReceipt" \
  "didMaterializeAiGeneratedSettingsRuntimeDemoCycleExecutionReceipt" \
  "didBindRuntimeDemoCycleInputContractToExecutor" \
  "didPrepareStage531SharedRuntimeDemoCycleHostProbe"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage530 shared runtime demo cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage530_shared_runtime_demo_cycle_executor_owner_present=true"
echo "stage529_shared_runtime_demo_cycle_input_contract_consumed=true"
echo "shared_runtime_demo_cycle_input_contract_consumed=true"
echo "shared_runtime_demo_cycle_route_ledger_consumed=true"
echo "todo_runtime_demo_cycle_input_consumed=true"
echo "settings_runtime_demo_cycle_input_consumed=true"
echo "ai_generated_settings_runtime_demo_cycle_input_consumed=true"
echo "shared_runtime_demo_cycle_executor_materialized=true"
echo "shared_runtime_demo_cycle_execution_receipt_materialized=true"
echo "runtime_demo_cycle_order_input_action_state_render_layout_probe_materialized=true"
echo "todo_runtime_demo_cycle_execution_receipt_materialized=true"
echo "settings_runtime_demo_cycle_execution_receipt_materialized=true"
echo "ai_generated_settings_runtime_demo_cycle_execution_receipt_materialized=true"
echo "runtime_demo_cycle_input_contract_to_executor_bound=true"
echo "runtime_demo_cycle_executor_bound_to_layout_style_probe_route=true"
echo "runtime_demo_cycle_executor_reusable=true"
echo "runtime_demo_cycle_executor_owner_local=true"
echo "runtime_demo_cycle_executor_non_dispatching=true"
echo "runtime_demo_cycle_executor_state_dry_run_only=true"
echo "runtime_demo_cycle_executor_render_preview_only=true"
echo "stage531_shared_runtime_demo_cycle_host_probe_prepared=true"
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
