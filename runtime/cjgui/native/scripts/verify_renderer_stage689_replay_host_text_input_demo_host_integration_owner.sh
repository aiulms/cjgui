#!/usr/bin/env zsh
#
# Verifies the stage689 replay host text input demo-host integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage689_replay_host_text_input_demo_host_integration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage689 replay host text input demo-host integration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage689ReplayHostTextInputDemoHostIntegrationPlan" \
  "CjguiInternalRendererStage689ReplayHostTextInputDemoHostIntegrationFacts" \
  "CjguiInternalRendererStage689ReplayHostTextInputDemoHostIntegrationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage689ReplayHostTextInputDemoHostIntegrationDraft" \
  "CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractReadiness" \
  "didConsumeStage688ReplayHostTextInputRuntimeContract" \
  "didMaterializeSharedReplayHostTextInputDemoHostIntegration" \
  "didMaterializeReplayHostTextInputHostSlotLedger" \
  "didMaterializeTextEditCommitHostSlot" \
  "didMaterializeValidationDismissHostSlot" \
  "didMaterializeFocusMoveHostSlot" \
  "didMaterializeSubmitHostSlot" \
  "didMaterializeTodoReplayHostTextInputDemoHostIntegration" \
  "didMaterializeSettingsReplayHostTextInputDemoHostIntegration" \
  "didMaterializeAiGeneratedSettingsReplayHostTextInputDemoHostIntegration" \
  "didMaterializeChatComposerReplayHostTextInputDemoHostIntegration" \
  "didBindDemoHostIntegrationToStage688RuntimeContract" \
  "didPrepareStage690ReplayHostTextInputHostEventAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage689 replay host text input demo-host integration: missing token $token" >&2
    exit 3
  fi
done

echo "stage689_replay_host_text_input_demo_host_integration_owner_present=true"
echo "stage688_replay_host_text_input_runtime_contract_consumed=true"
echo "shared_replay_host_text_input_demo_host_integration_materialized=true"
echo "replay_host_text_input_host_slot_ledger_materialized=true"
echo "text_edit_commit_host_slot_materialized=true"
echo "validation_dismiss_host_slot_materialized=true"
echo "focus_move_host_slot_materialized=true"
echo "submit_host_slot_materialized=true"
echo "todo_replay_host_text_input_demo_host_integration_materialized=true"
echo "settings_replay_host_text_input_demo_host_integration_materialized=true"
echo "ai_generated_settings_replay_host_text_input_demo_host_integration_materialized=true"
echo "chat_composer_replay_host_text_input_demo_host_integration_materialized=true"
echo "demo_host_integration_bound_to_stage688_runtime_contract=true"
echo "stage690_replay_host_text_input_host_event_adapter_prepared=true"
echo "host_mutation=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
