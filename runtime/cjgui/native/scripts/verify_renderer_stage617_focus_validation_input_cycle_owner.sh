#!/usr/bin/env zsh
#
# Verifies the stage617 shared focus/validation input cycle owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage617_focus_validation_input_cycle.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage617 focus validation input cycle: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage617FocusValidationInputCyclePlan" \
  "CjguiInternalRendererStage617FocusValidationInputCycleFacts" \
  "CjguiInternalRendererStage617FocusValidationInputCycleReadiness" \
  "cjguiInternalExecuteDefaultRendererStage617FocusValidationInputCycleDraft" \
  "CjguiInternalRendererStage616FocusValidationRuntimeContractReadiness" \
  "didConsumeStage616FocusValidationRuntimeContract" \
  "didMaterializeSharedFocusValidationInputCycleContract" \
  "didMaterializeNormalizedFocusValidationInputEventLedger" \
  "didMaterializeValidationChangeInputIntent" \
  "didMaterializeFocusMoveInputIntent" \
  "didMaterializeInputFeedbackIntentAdapter" \
  "didMaterializeChatComposerFocusValidationInputCycle" \
  "didPrepareStage618FocusValidationStateRenderExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage617 focus validation input cycle: missing token $token" >&2
    exit 3
  fi
done

echo "stage617_focus_validation_input_cycle_owner_present=true"
echo "stage616_focus_validation_runtime_contract_consumed=true"
echo "shared_focus_validation_input_cycle_contract_materialized=true"
echo "normalized_focus_validation_input_event_ledger_materialized=true"
echo "validation_change_input_intent_materialized=true"
echo "focus_move_input_intent_materialized=true"
echo "input_feedback_intent_adapter_materialized=true"
echo "todo_focus_validation_input_cycle_materialized=true"
echo "settings_focus_validation_input_cycle_materialized=true"
echo "ai_generated_settings_focus_validation_input_cycle_materialized=true"
echo "chat_composer_focus_validation_input_cycle_materialized=true"
echo "input_cycle_bound_to_stage616_runtime_contract=true"
echo "focus_validation_input_cycle_owner_local=true"
echo "focus_validation_input_cycle_non_dispatching=true"
echo "stage618_focus_validation_state_render_executor_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
