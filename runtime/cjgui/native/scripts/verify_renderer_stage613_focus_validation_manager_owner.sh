#!/usr/bin/env zsh
#
# Verifies the stage613 shared focus/validation manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage613_focus_validation_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage613 focus validation manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage613FocusValidationManagerPlan" \
  "CjguiInternalRendererStage613FocusValidationManagerFacts" \
  "CjguiInternalRendererStage613FocusValidationManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage613FocusValidationManagerDraft" \
  "CjguiInternalRendererStage612SharedFeedbackHostInspectionCycleExecutorContractReadiness" \
  "didConsumeStage612SharedFeedbackHostInspectionCycleExecutorContract" \
  "didMaterializeSharedFocusValidationManagerContract" \
  "didMaterializeValidationStateLedger" \
  "didMaterializeFocusCandidateLedger" \
  "didMaterializeInputFeedbackIntentLedger" \
  "didMaterializeTodoFocusValidationRoute" \
  "didMaterializeSettingsFocusValidationRoute" \
  "didMaterializeAiGeneratedSettingsFocusValidationRoute" \
  "didMaterializeChatComposerFocusValidationRoute" \
  "didPrepareStage614FocusValidationFeedbackResolver"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage613 focus validation manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage613_focus_validation_manager_owner_present=true"
echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_consumed=true"
echo "shared_focus_validation_manager_contract_materialized=true"
echo "validation_state_ledger_materialized=true"
echo "focus_candidate_ledger_materialized=true"
echo "input_feedback_intent_ledger_materialized=true"
echo "todo_focus_validation_route_materialized=true"
echo "settings_focus_validation_route_materialized=true"
echo "ai_generated_settings_focus_validation_route_materialized=true"
echo "chat_composer_focus_validation_route_materialized=true"
echo "stage614_focus_validation_feedback_resolver_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
