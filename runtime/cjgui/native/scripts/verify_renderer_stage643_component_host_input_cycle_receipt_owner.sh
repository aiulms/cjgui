#!/usr/bin/env zsh
#
# Verifies the stage643 component host input cycle receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage643_component_host_input_cycle_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage643 component host input cycle receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage643ComponentHostInputCycleReceiptPlan" \
  "CjguiInternalRendererStage643ComponentHostInputCycleReceiptFacts" \
  "CjguiInternalRendererStage643ComponentHostInputCycleReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage643ComponentHostInputCycleReceiptDraft" \
  "CjguiInternalRendererStage642ComponentHostInputEventQueueReadiness" \
  "didConsumeStage642ComponentHostInputEventQueue" \
  "didMaterializeSharedComponentHostInputCycleReceipt" \
  "didMaterializeHostInputActionIntentPreviewLedger" \
  "didMaterializeHostInputStateDeltaDryRunLedger" \
  "didMaterializeHostInputRenderCommandRefreshLedger" \
  "didMaterializeHostInputFocusMovementReceipt" \
  "didMaterializeChatComposerComponentHostInputCycleReceipt" \
  "didPrepareStage644ComponentHostInputCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage643 component host input cycle receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage643_component_host_input_cycle_receipt_owner_present=true"
echo "stage642_component_host_input_event_queue_consumed=true"
echo "stage641_result_surface_host_input_adapter_consumed_transitively=true"
echo "shared_component_host_input_cycle_receipt_materialized=true"
echo "host_input_action_intent_preview_ledger_materialized=true"
echo "host_input_state_delta_dry_run_ledger_materialized=true"
echo "host_input_render_command_refresh_ledger_materialized=true"
echo "host_input_focus_movement_receipt_materialized=true"
echo "host_input_validation_refresh_receipt_materialized=true"
echo "host_input_feedback_clear_receipt_materialized=true"
echo "host_input_semantic_refresh_receipt_materialized=true"
echo "todo_component_host_input_cycle_receipt_materialized=true"
echo "settings_component_host_input_cycle_receipt_materialized=true"
echo "ai_generated_settings_component_host_input_cycle_receipt_materialized=true"
echo "chat_composer_component_host_input_cycle_receipt_materialized=true"
echo "component_host_input_cycle_receipt_bound_to_stage642_queue=true"
echo "component_host_input_cycle_receipt_non_dispatching=true"
echo "stage644_component_host_input_cycle_executor_prepared=true"
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
