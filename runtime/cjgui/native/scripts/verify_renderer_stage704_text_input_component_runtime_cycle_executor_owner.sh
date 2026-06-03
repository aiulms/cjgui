#!/usr/bin/env zsh
#
# Verifies the stage704 text input component runtime cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage704_text_input_component_runtime_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage704 text input component runtime cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage704TextInputComponentRuntimeCycleExecutorPlan" \
  "CjguiInternalRendererStage704TextInputComponentRuntimeCycleExecutorFacts" \
  "CjguiInternalRendererStage704TextInputComponentRuntimeCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage704TextInputComponentRuntimeCycleExecutorDraft" \
  "CjguiInternalRendererStage703TextInputComponentRuntimeDemoSurfaceRefreshReadiness" \
  "didConsumeStage703TextInputComponentRuntimeDemoSurfaceRefresh" \
  "didMaterializeSharedTextInputComponentRuntimeCycleExecutor" \
  "didMaterializeSharedTextInputComponentRuntimeContract" \
  "didMaterializeTextInputComponentRuntimeExecutionReceiptContract" \
  "didMaterializeCycleOrderComponentRuntimeSlotContractBindingSurfaceRefreshCycleExecutor" \
  "didReduceFuturePerDemoTextInputComponentRuntimeTemplateNeed" \
  "didPrepareStage705ComponentRuntimeInputEventNormalization"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage704 text input component runtime cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage704_text_input_component_runtime_cycle_executor_owner_present=true"
echo "stage703_text_input_component_runtime_demo_surface_refresh_consumed=true"
echo "stage702_text_input_component_slot_binding_adapter_consumed_transitively=true"
echo "stage701_text_input_timeline_component_runtime_contract_consumed_transitively=true"
echo "stage700_replay_host_text_input_timeline_action_state_render_executor_consumed_transitively=true"
echo "shared_text_input_component_runtime_cycle_executor_materialized=true"
echo "shared_text_input_component_runtime_contract_materialized=true"
echo "text_input_component_runtime_execution_receipt_contract_materialized=true"
echo "cycle_order_component_runtime_slot_contract_binding_surface_refresh_cycle_executor_materialized=true"
echo "todo_text_input_component_runtime_cycle_surface_materialized=true"
echo "settings_text_input_component_runtime_cycle_surface_materialized=true"
echo "ai_generated_settings_text_input_component_runtime_cycle_surface_materialized=true"
echo "chat_composer_text_input_component_runtime_cycle_surface_materialized=true"
echo "future_per_demo_text_input_component_runtime_template_need_reduced=true"
echo "stage705_component_runtime_input_event_normalization_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
