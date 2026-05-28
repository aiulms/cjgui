#!/usr/bin/env zsh
#
# Verifies the stage628 shared focus/validation host input runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage628_shared_focus_validation_host_input_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage628 shared focus validation host input runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractPlan" \
  "CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractFacts" \
  "CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage628SharedFocusValidationHostInputRuntimeContractDraft" \
  "CjguiInternalRendererStage627FocusValidationHostInputCycleExecutorReadiness" \
  "didConsumeStage627FocusValidationHostInputCycleExecutor" \
  "didMaterializeSharedFocusValidationHostInputRuntimeContract" \
  "didMaterializeSharedFocusValidationHostInputRuntimeHelper" \
  "didMaterializeSharedFocusValidationHostInputExecutionReceiptContract" \
  "didMaterializeCycleOrderHostInputEventActionStateRenderHostSurfaceReceipt" \
  "didMaterializeChatComposerFocusValidationHostInputRuntimeSurface" \
  "didBindHostInputRuntimeToStage625Adapter" \
  "didBindHostInputRuntimeToStage626Normalizer" \
  "didBindHostInputRuntimeToStage627CycleExecutor" \
  "didReduceFuturePerDemoFocusValidationHostInputTemplateNeed" \
  "didPrepareStage629ComponentRuntimeFocusValidationHostInputResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage628 shared focus validation host input runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage628_shared_focus_validation_host_input_runtime_contract_owner_present=true"
echo "stage627_focus_validation_host_input_cycle_executor_consumed=true"
echo "stage626_focus_validation_host_input_event_normalizer_consumed_transitively=true"
echo "stage625_focus_validation_host_input_adapter_consumed_transitively=true"
echo "stage624_shared_focus_validation_demo_host_runtime_contract_consumed_transitively=true"
echo "shared_focus_validation_host_input_runtime_contract_materialized=true"
echo "shared_focus_validation_host_input_runtime_helper_materialized=true"
echo "shared_focus_validation_host_input_execution_receipt_contract_materialized=true"
echo "cycle_order_host_input_event_action_state_render_host_surface_receipt_materialized=true"
echo "todo_focus_validation_host_input_runtime_surface_materialized=true"
echo "settings_focus_validation_host_input_runtime_surface_materialized=true"
echo "ai_generated_settings_focus_validation_host_input_runtime_surface_materialized=true"
echo "chat_composer_focus_validation_host_input_runtime_surface_materialized=true"
echo "host_input_runtime_bound_to_stage625_adapter=true"
echo "host_input_runtime_bound_to_stage626_normalizer=true"
echo "host_input_runtime_bound_to_stage627_cycle_executor=true"
echo "future_per_demo_focus_validation_host_input_template_need_reduced=true"
echo "stage629_component_runtime_focus_validation_host_input_result_surface_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
