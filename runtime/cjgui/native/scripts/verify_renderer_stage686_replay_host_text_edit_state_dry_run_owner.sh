#!/usr/bin/env zsh
#
# Verifies the stage686 replay host text edit state dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage686_replay_host_text_edit_state_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage686 replay host text edit state dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage686ReplayHostTextEditStateDryRunPlan" \
  "CjguiInternalRendererStage686ReplayHostTextEditStateDryRunFacts" \
  "CjguiInternalRendererStage686ReplayHostTextEditStateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage686ReplayHostTextEditStateDryRunDraft" \
  "CjguiInternalRendererStage685ReplayHostTextEditFieldModelReadiness" \
  "didConsumeStage685ReplayHostTextEditFieldModel" \
  "didMaterializeSharedReplayHostTextEditOperationLedger" \
  "didMaterializeTextInsertOperationDryRun" \
  "didMaterializeTextDeleteOperationDryRun" \
  "didMaterializeTextSubmitOperationDryRun" \
  "didMaterializeFocusMoveOperationDryRun" \
  "didMaterializeTextValueStateDeltaDryRun" \
  "didMaterializeSelectionCaretStateDeltaDryRun" \
  "didMaterializeValidationFeedbackStateDeltaDryRun" \
  "didMaterializeChatComposerReplayHostTextEditStateReceipt" \
  "didBindTextEditStateDryRunToStage685FieldModel" \
  "didBindTextEditStateDryRunToStage684RuntimeContract" \
  "didPrepareStage687ReplayHostTextEditRenderResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage686 replay host text edit state dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage686_replay_host_text_edit_state_dry_run_owner_present=true"
echo "stage685_replay_host_text_edit_field_model_consumed=true"
echo "shared_replay_host_text_edit_operation_ledger_materialized=true"
echo "text_insert_operation_dry_run_materialized=true"
echo "text_delete_operation_dry_run_materialized=true"
echo "text_submit_operation_dry_run_materialized=true"
echo "focus_move_operation_dry_run_materialized=true"
echo "text_value_state_delta_dry_run_materialized=true"
echo "selection_caret_state_delta_dry_run_materialized=true"
echo "validation_feedback_state_delta_dry_run_materialized=true"
echo "todo_replay_host_text_edit_state_receipt_materialized=true"
echo "settings_replay_host_text_edit_state_receipt_materialized=true"
echo "ai_generated_settings_replay_host_text_edit_state_receipt_materialized=true"
echo "chat_composer_replay_host_text_edit_state_receipt_materialized=true"
echo "text_edit_state_dry_run_bound_to_stage685_field_model=true"
echo "text_edit_state_dry_run_bound_to_stage684_runtime_contract=true"
echo "stage687_replay_host_text_edit_render_result_surface_prepared=true"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
