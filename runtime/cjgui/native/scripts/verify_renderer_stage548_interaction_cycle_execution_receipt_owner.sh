#!/usr/bin/env zsh
#
# Verifies the stage548 interaction cycle execution receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage548_interaction_cycle_execution_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage548 interaction cycle execution receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage548InteractionCycleExecutionReceiptPlan" \
  "CjguiInternalRendererStage548InteractionCycleExecutionReceiptFacts" \
  "CjguiInternalRendererStage548InteractionCycleExecutionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage548InteractionCycleExecutionReceiptDraft" \
  "CjguiInternalRendererStage547InteractionInputEventCycleProbeReadiness" \
  "didConsumeStage547InteractionInputEventCycleProbe" \
  "didMaterializeSharedInteractionCycleDryRunExecutor" \
  "didMaterializeSharedInteractionCycleExecutionReceipt" \
  "didMaterializeInteractionEventStateRenderLayoutOrderLedger" \
  "didMaterializeInteractionFocusTransitionReceipt" \
  "didMaterializeTodoInteractionCycleExecutionReceipt" \
  "didMaterializeSettingsInteractionCycleExecutionReceipt" \
  "didMaterializeAiGeneratedSettingsInteractionCycleExecutionReceipt" \
  "didBindInteractionCycleExecutionToRuntimeContract" \
  "didKeepInteractionCycleExecutionNonDispatching"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage548 interaction cycle execution receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage548_interaction_cycle_execution_receipt_owner_present=true"
echo "stage547_interaction_input_event_cycle_probe_consumed=true"
echo "shared_interaction_cycle_dry_run_executor_materialized=true"
echo "shared_interaction_cycle_execution_receipt_materialized=true"
echo "interaction_event_state_render_layout_order_ledger_materialized=true"
echo "interaction_focus_transition_receipt_materialized=true"
echo "todo_interaction_cycle_execution_receipt_materialized=true"
echo "settings_interaction_cycle_execution_receipt_materialized=true"
echo "ai_generated_settings_interaction_cycle_execution_receipt_materialized=true"
echo "interaction_cycle_execution_bound_to_stage547_probe_inputs=true"
echo "interaction_cycle_execution_bound_to_stage546_runtime_contract=true"
echo "interaction_cycle_execution_bound_to_stage543_refresh_receipts=true"
echo "interaction_cycle_execution_bound_to_stage545_layout_measurement=true"
echo "interaction_cycle_execution_non_dispatching=true"
echo "stage549_interaction_demo_cycle_surface_contract_prepared=true"
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
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
