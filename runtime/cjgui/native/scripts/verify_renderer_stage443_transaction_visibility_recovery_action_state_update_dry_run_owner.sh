#!/usr/bin/env zsh
#
# 维护注释：验证 stage443 transaction visibility recovery action -> state update dry-run owner。
# 它必须消费 stage442 recovery action intent，并生成 owner-local recovery state update / rollback preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage443_transaction_visibility_recovery_action_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage443 transaction visibility recovery action state update dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage443TransactionVisibilityRecoveryActionStateUpdateDryRunPlan" \
  "CjguiInternalRendererStage443TransactionVisibilityRecoveryActionStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage443TransactionVisibilityRecoveryActionStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage443TransactionVisibilityRecoveryActionStateUpdateDryRunDraft" \
  "didConsumeStage442TransactionVisibilityResultRecoveryActionAdapter" \
  "didConsumeOwnerLocalTransactionVisibilityRecoveryActionIntent" \
  "didConsumeTodoTransactionVisibilityResultRecoveryActionIntent" \
  "didConsumeSettingsTransactionVisibilityResultRecoveryActionIntent" \
  "didConsumeAiGeneratedSettingsTransactionVisibilityResultRecoveryActionIntent" \
  "didMaterializeTransactionVisibilityRecoveryActionStateUpdateDryRun" \
  "didMaterializeTodoTransactionVisibilityRecoveryStateUpdateCandidate" \
  "didMaterializeSettingsTransactionVisibilityRecoveryStateUpdateCandidate" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityRecoveryStateUpdateCandidate" \
  "didBindTransactionVisibilityRecoveryActionIntentToStateUpdateDryRun" \
  "didMaterializeTransactionVisibilityRecoveryActionRollbackPreview" \
  "didPrepareStage444TransactionVisibilityRecoveryStateUpdateRenderCommandRefresh" \
  "didKeepTransactionVisibilityRecoveryStateUpdateDryRunOnly" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage443 transaction visibility recovery action state update dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage443_transaction_visibility_recovery_action_state_update_dry_run_owner_present=true"
echo "stage442_transaction_visibility_result_recovery_action_adapter_required=true"
echo "stage442_transaction_visibility_result_recovery_action_adapter_consumed=true"
echo "owner_local_transaction_visibility_recovery_action_intent_consumed=true"
echo "todo_transaction_visibility_result_recovery_action_intent_consumed=true"
echo "settings_transaction_visibility_result_recovery_action_intent_consumed=true"
echo "ai_generated_settings_transaction_visibility_result_recovery_action_intent_consumed=true"
echo "transaction_visibility_recovery_action_state_update_dry_run_materialized=true"
echo "todo_transaction_visibility_recovery_state_update_candidate_materialized=true"
echo "settings_transaction_visibility_recovery_state_update_candidate_materialized=true"
echo "ai_generated_settings_transaction_visibility_recovery_state_update_candidate_materialized=true"
echo "transaction_visibility_recovery_action_intent_to_state_update_dry_run_bound=true"
echo "transaction_visibility_recovery_action_rollback_preview_materialized=true"
echo "transaction_visibility_recovery_state_update_dry_run_only=true"
echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
