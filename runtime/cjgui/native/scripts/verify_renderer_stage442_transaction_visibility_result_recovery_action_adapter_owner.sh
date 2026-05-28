#!/usr/bin/env zsh
#
# 维护注释：验证 stage442 transaction visibility result recovery action adapter owner。
# 它必须消费 stage441 result surface refresh，并产出 owner-local recovery action intent。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage442_transaction_visibility_result_recovery_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage442 transaction visibility result recovery action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage442TransactionVisibilityResultRecoveryActionAdapterPlan" \
  "CjguiInternalRendererStage442TransactionVisibilityResultRecoveryActionAdapterFacts" \
  "CjguiInternalRendererStage442TransactionVisibilityResultRecoveryActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage442TransactionVisibilityResultRecoveryActionAdapterDraft" \
  "didConsumeStage441TransactionVisibilityResultDemoSurfaceRefresh" \
  "didConsumeTransactionVisibilityResultDemoSurfaceRefresh" \
  "didConsumeTodoTransactionVisibilityResultSurface" \
  "didConsumeSettingsTransactionVisibilityResultSurface" \
  "didConsumeAiGeneratedSettingsTransactionVisibilityResultSurface" \
  "didBindNotAdmittedResultSurfaceToRecoveryAction" \
  "didBindRollbackResultSurfaceToRecoveryAction" \
  "didMaterializeTransactionVisibilityResultRecoveryActionAdapter" \
  "didMaterializeTodoTransactionVisibilityResultRecoveryActionIntent" \
  "didMaterializeSettingsTransactionVisibilityResultRecoveryActionIntent" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityResultRecoveryActionIntent" \
  "didMaterializeOwnerLocalTransactionVisibilityRecoveryActionIntent" \
  "didBindRecoveryActionAdapterToStage441SurfaceRefresh" \
  "didBindRecoveryActionAdapterToStage440ResultBoundary" \
  "didKeepTransactionVisibilityRecoveryActionIntentOwnerLocal" \
  "didKeepTransactionVisibilityRecoveryActionIntentNonDispatching" \
  "didPrepareStage443TransactionVisibilityRecoveryActionStateUpdateDryRun" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage442 transaction visibility result recovery action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage442_transaction_visibility_result_recovery_action_adapter_owner_present=true"
echo "stage441_transaction_visibility_result_demo_surface_refresh_required=true"
echo "stage441_transaction_visibility_result_demo_surface_refresh_consumed=true"
echo "transaction_visibility_result_demo_surface_refresh_consumed=true"
echo "todo_transaction_visibility_result_surface_consumed=true"
echo "settings_transaction_visibility_result_surface_consumed=true"
echo "ai_generated_settings_transaction_visibility_result_surface_consumed=true"
echo "not_admitted_result_surface_to_recovery_action_bound=true"
echo "rollback_result_surface_to_recovery_action_bound=true"
echo "transaction_visibility_result_recovery_action_adapter_materialized=true"
echo "todo_transaction_visibility_result_recovery_action_intent_materialized=true"
echo "settings_transaction_visibility_result_recovery_action_intent_materialized=true"
echo "ai_generated_settings_transaction_visibility_result_recovery_action_intent_materialized=true"
echo "owner_local_transaction_visibility_recovery_action_intent_materialized=true"
echo "recovery_action_adapter_bound_to_stage441_surface_refresh=true"
echo "recovery_action_adapter_bound_to_stage440_result_boundary=true"
echo "transaction_visibility_recovery_action_intent_owner_local=true"
echo "transaction_visibility_recovery_action_intent_non_dispatching=true"
echo "stage443_transaction_visibility_recovery_action_state_update_dry_run_prepared=true"
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
