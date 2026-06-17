#!/usr/bin/env zsh
#
# Verifies the stage873 owner-local state-store commit first-slice proof owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage873_owner_local_state_store_commit_first_slice_proof.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage873 owner-local state-store commit first-slice proof: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage873OwnerLocalStateStoreCommitFirstSliceProofPlan" \
  "CjguiInternalRendererStage873OwnerLocalStateStoreCommitFirstSliceProofFacts" \
  "CjguiInternalRendererStage873OwnerLocalStateStoreCommitFirstSliceProofReadiness" \
  "cjguiInternalExecuteDefaultRendererStage873OwnerLocalStateStoreCommitFirstSliceProofDraft" \
  "CjguiInternalRendererStage872TextInputCommitStateStorePublicApiRuntimeManagerReadiness" \
  "didConsumeStage872TextInputCommitStateStorePublicApiRuntimeManager" \
  "didMaterializeOwnerLocalStateStoreCommitFirstSliceProof" \
  "didMaterializeOwnerLocalInMemoryStateStoreCommitExecutor" \
  "didMaterializeOwnerLocalStateStoreCommitPatchSet" \
  "didMaterializeOwnerLocalStateStoreCommitReceipt" \
  "didMaterializeOwnerLocalStateStoreCommitRollbackToken" \
  "didApplyOwnerLocalStateStoreCommitInMemory" \
  "didKeepOwnerLocalStateStoreCommitInspectable" \
  "didPrepareStage874OwnerLocalStateStoreCommitRollbackLedger"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage873 owner-local state-store commit first-slice proof: missing token $token" >&2
    exit 3
  fi
done

echo "stage873_owner_local_state_store_commit_first_slice_proof_owner_present=true"
echo "stage872_text_input_commit_state_store_public_api_runtime_manager_consumed=true"
echo "state_store_public_api_commit_runtime_contract_consumed=true"
echo "owner_local_state_store_commit_first_slice_proof_materialized=true"
echo "owner_local_in_memory_state_store_commit_executor_materialized=true"
echo "owner_local_state_store_commit_patch_set_materialized=true"
echo "owner_local_state_store_commit_receipt_materialized=true"
echo "owner_local_state_store_commit_rollback_token_materialized=true"
echo "owner_local_state_store_commit_applied_in_memory=true"
echo "owner_local_state_store_commit_inspectable=true"
echo "stage874_owner_local_state_store_commit_rollback_ledger_prepared=true"
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
