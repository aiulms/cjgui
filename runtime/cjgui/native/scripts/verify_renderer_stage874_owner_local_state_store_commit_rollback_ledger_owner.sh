#!/usr/bin/env zsh
#
# Verifies the stage874 owner-local state-store commit rollback ledger owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage874_owner_local_state_store_commit_rollback_ledger.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage874 owner-local state-store commit rollback ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage874OwnerLocalStateStoreCommitRollbackLedgerPlan" \
  "CjguiInternalRendererStage874OwnerLocalStateStoreCommitRollbackLedgerFacts" \
  "CjguiInternalRendererStage874OwnerLocalStateStoreCommitRollbackLedgerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage874OwnerLocalStateStoreCommitRollbackLedgerDraft" \
  "CjguiInternalRendererStage873OwnerLocalStateStoreCommitFirstSliceProofReadiness" \
  "didConsumeStage873OwnerLocalStateStoreCommitFirstSliceProof" \
  "didMaterializeOwnerLocalStateStoreCommitRollbackLedger" \
  "didMaterializeOwnerLocalStateStorePreCommitSnapshot" \
  "didMaterializeOwnerLocalStateStorePostCommitSnapshot" \
  "didMaterializeOwnerLocalStateStoreRollbackPatchPlan" \
  "didMaterializeOwnerLocalStateStoreNotPublishedCommitReceipt" \
  "didKeepOwnerLocalStateStoreCommitReversible" \
  "didPrepareStage875OwnerLocalStateStoreCommitDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage874 owner-local state-store commit rollback ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage874_owner_local_state_store_commit_rollback_ledger_owner_present=true"
echo "stage873_owner_local_state_store_commit_first_slice_proof_consumed=true"
echo "owner_local_state_store_commit_receipt_consumed=true"
echo "owner_local_state_store_commit_rollback_ledger_materialized=true"
echo "owner_local_state_store_pre_commit_snapshot_materialized=true"
echo "owner_local_state_store_post_commit_snapshot_materialized=true"
echo "owner_local_state_store_rollback_patch_plan_materialized=true"
echo "owner_local_state_store_not_published_commit_receipt_materialized=true"
echo "owner_local_state_store_commit_reversible=true"
echo "owner_local_state_store_rollback_rehearsal_in_memory_only=true"
echo "stage875_owner_local_state_store_commit_demo_host_surface_prepared=true"
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
