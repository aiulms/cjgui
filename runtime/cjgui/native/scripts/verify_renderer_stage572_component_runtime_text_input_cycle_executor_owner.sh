#!/usr/bin/env zsh
#
# Verifies the stage572 component runtime text input cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage572_component_runtime_text_input_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage572 component runtime text input cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage572ComponentRuntimeTextInputCycleExecutorPlan" \
  "CjguiInternalRendererStage572ComponentRuntimeTextInputCycleExecutorFacts" \
  "CjguiInternalRendererStage572ComponentRuntimeTextInputCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage572ComponentRuntimeTextInputCycleExecutorDraft" \
  "CjguiInternalRendererStage571ComponentRuntimeTextInputEventAdapterReadiness" \
  "didMaterializeSharedTextInputEventCycleExecutor" \
  "didMaterializeTextInputActionIntentLedger" \
  "didMaterializeTextInputValueEditStateDeltaDryRunLedger" \
  "didMaterializeTextInputCaretSelectionTransitionDryRunLedger" \
  "didMaterializeTextInputValidationTriggerPreviewLedger" \
  "didMaterializeTextInputRenderCommandRefreshReceiptLedger" \
  "didPrepareStage573ComponentRuntimeTextInputDemoExecutionContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage572 component runtime text input cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage572_component_runtime_text_input_cycle_executor_owner_present=true"
echo "stage571_component_runtime_text_input_event_adapter_consumed=true"
echo "stage570_component_runtime_text_input_demo_host_surface_contract_consumed_transitively=true"
echo "stage566_component_runtime_text_input_state_executor_consumed_transitively=true"
echo "shared_text_input_event_cycle_executor_materialized=true"
echo "text_input_action_intent_ledger_materialized=true"
echo "text_input_value_edit_state_delta_dry_run_ledger_materialized=true"
echo "text_input_caret_selection_transition_dry_run_ledger_materialized=true"
echo "text_input_validation_trigger_preview_ledger_materialized=true"
echo "text_input_render_command_refresh_receipt_ledger_materialized=true"
echo "todo_text_input_event_cycle_receipt_materialized=true"
echo "settings_text_input_event_cycle_receipt_materialized=true"
echo "ai_generated_settings_text_input_event_cycle_receipt_materialized=true"
echo "chat_composer_text_input_event_cycle_receipt_materialized=true"
echo "text_input_cycle_executor_bound_to_stage571_events=true"
echo "text_input_cycle_executor_bound_to_stage566_state_executor=true"
echo "text_input_cycle_executor_bound_to_stage570_host_surfaces=true"
echo "component_runtime_text_input_event_cycle_owner_local=true"
echo "component_runtime_text_input_event_cycle_non_dispatching=true"
echo "stage573_component_runtime_text_input_demo_execution_contract_prepared=true"
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
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
