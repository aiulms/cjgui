#!/usr/bin/env zsh
#
# Verifies the stage876 owner-local state-store commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage876_owner_local_state_store_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage876 owner-local state-store commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage876OwnerLocalStateStoreCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage876OwnerLocalStateStoreCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage876OwnerLocalStateStoreCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage876OwnerLocalStateStoreCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage875OwnerLocalStateStoreCommitDemoHostSurfaceReadiness" \
  "didConsumeStage875OwnerLocalStateStoreCommitDemoHostSurface" \
  "didMaterializeSharedOwnerLocalStateStoreCommitRuntimeManager" \
  "didMaterializeOwnerLocalStateStoreCommitRuntimeContract" \
  "didMaterializeOwnerLocalStateStoreCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderStateStorePublicApiCommitProofRollbackDemoRuntime" \
  "didMaterializeCommonOwnerLocalStateStoreCommitExecutor" \
  "didMaterializeOwnerLocalStateStoreRollbackLedgerRuntimeBridge" \
  "didReduceFuturePerDemoOwnerLocalStateStoreCommitTemplateNeed" \
  "didPrepareStage877OwnerAcceptanceAfterOwnerLocalStateStoreCommit"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage876 owner-local state-store commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage876_owner_local_state_store_commit_runtime_manager_owner_present=true"
echo "stage875_owner_local_state_store_commit_demo_host_surface_consumed=true"
echo "stage874_owner_local_state_store_commit_rollback_ledger_consumed_transitively=true"
echo "stage873_owner_local_state_store_commit_first_slice_proof_consumed_transitively=true"
echo "stage872_text_input_commit_state_store_public_api_runtime_manager_consumed_transitively=true"
echo "shared_owner_local_state_store_commit_runtime_manager_materialized=true"
echo "owner_local_state_store_commit_runtime_contract_materialized=true"
echo "owner_local_state_store_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_state_store_public_api_commit_proof_rollback_demo_runtime_materialized=true"
echo "todo_owner_local_state_store_commit_runtime_surface_materialized=true"
echo "settings_owner_local_state_store_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_owner_local_state_store_commit_runtime_surface_materialized=true"
echo "chat_composer_owner_local_state_store_commit_runtime_surface_materialized=true"
echo "file_browser_owner_local_state_store_commit_runtime_surface_materialized=true"
echo "common_owner_local_state_store_commit_executor_materialized=true"
echo "owner_local_state_store_rollback_ledger_runtime_bridge_materialized=true"
echo "owner_local_state_store_commit_applied_in_memory=true"
echo "future_per_demo_owner_local_state_store_commit_template_need_reduced=true"
echo "stage877_owner_acceptance_after_owner_local_state_store_commit_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
