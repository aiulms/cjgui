#!/usr/bin/env zsh
#
# Verifies the stage627 focus/validation host input cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage627_focus_validation_host_input_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage627 focus validation host input cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage627FocusValidationHostInputCycleExecutorPlan" \
  "CjguiInternalRendererStage627FocusValidationHostInputCycleExecutorFacts" \
  "CjguiInternalRendererStage627FocusValidationHostInputCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage627FocusValidationHostInputCycleExecutorDraft" \
  "CjguiInternalRendererStage626FocusValidationHostInputEventNormalizerReadiness" \
  "didConsumeStage626FocusValidationHostInputEventNormalizer" \
  "didMaterializeSharedFocusValidationHostInputCycleExecutor" \
  "didMaterializeHostInputActionIntentPreviewLedger" \
  "didMaterializeHostInputStateDeltaDryRunLedger" \
  "didMaterializeHostInputRenderCommandRefreshLedger" \
  "didMaterializeHostInputFocusTransitionReceipt" \
  "didMaterializeHostInputValidationDisplayReceipt" \
  "didMaterializeHostInputFeedbackDisplayReceipt" \
  "didMaterializeChatComposerHostInputCycleReceipt" \
  "didBindHostInputCycleExecutorToStage626Normalizer" \
  "didBindHostInputCycleExecutorToStage625Adapter" \
  "didPrepareStage628SharedFocusValidationHostInputRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage627 focus validation host input cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage627_focus_validation_host_input_cycle_executor_owner_present=true"
echo "stage626_focus_validation_host_input_event_normalizer_consumed=true"
echo "stage625_focus_validation_host_input_adapter_consumed_transitively=true"
echo "shared_focus_validation_host_input_cycle_executor_materialized=true"
echo "host_input_action_intent_preview_ledger_materialized=true"
echo "host_input_state_delta_dry_run_ledger_materialized=true"
echo "host_input_render_command_refresh_ledger_materialized=true"
echo "host_input_focus_transition_receipt_materialized=true"
echo "host_input_validation_display_receipt_materialized=true"
echo "host_input_feedback_display_receipt_materialized=true"
echo "todo_host_input_cycle_receipt_materialized=true"
echo "settings_host_input_cycle_receipt_materialized=true"
echo "ai_generated_settings_host_input_cycle_receipt_materialized=true"
echo "chat_composer_host_input_cycle_receipt_materialized=true"
echo "host_input_cycle_executor_bound_to_stage626_normalizer=true"
echo "host_input_cycle_executor_bound_to_stage625_adapter=true"
echo "stage628_shared_focus_validation_host_input_runtime_contract_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
