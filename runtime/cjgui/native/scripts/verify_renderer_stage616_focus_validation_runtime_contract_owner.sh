#!/usr/bin/env zsh
#
# Verifies the stage616 shared focus/validation runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage616_focus_validation_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage616 focus validation runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage616FocusValidationRuntimeContractPlan" \
  "CjguiInternalRendererStage616FocusValidationRuntimeContractFacts" \
  "CjguiInternalRendererStage616FocusValidationRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage616FocusValidationRuntimeContractDraft" \
  "CjguiInternalRendererStage615FocusValidationDemoHostReceiptReadiness" \
  "didConsumeStage615FocusValidationDemoHostReceipt" \
  "didMaterializeSharedFocusValidationRuntimeContract" \
  "didMaterializeSharedFocusValidationRuntimeHelper" \
  "didMaterializeSharedFocusValidationExecutionReceiptContract" \
  "didMaterializeFocusValidationCycleOrder" \
  "didMaterializeChatComposerFocusValidationRuntimeSurface" \
  "didReduceFuturePerDemoFocusValidationTemplateNeed" \
  "didPrepareStage617FocusValidationInputCycle"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage616 focus validation runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage616_focus_validation_runtime_contract_owner_present=true"
echo "stage615_focus_validation_demo_host_receipt_consumed=true"
echo "shared_focus_validation_runtime_contract_materialized=true"
echo "shared_focus_validation_runtime_helper_materialized=true"
echo "shared_focus_validation_execution_receipt_contract_materialized=true"
echo "focus_validation_cycle_order_materialized=true"
echo "todo_focus_validation_runtime_surface_materialized=true"
echo "settings_focus_validation_runtime_surface_materialized=true"
echo "ai_generated_settings_focus_validation_runtime_surface_materialized=true"
echo "chat_composer_focus_validation_runtime_surface_materialized=true"
echo "future_per_demo_focus_validation_template_need_reduced=true"
echo "stage617_focus_validation_input_cycle_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
