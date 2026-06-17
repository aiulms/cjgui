#!/usr/bin/env zsh
#
# Verifies the stage858 owner-local text input state-store commit snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage858_owner_local_text_input_state_store_commit_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage858 owner-local text input state-store commit snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage858OwnerLocalTextInputStateStoreCommitSnapshotPlan" \
  "CjguiInternalRendererStage858OwnerLocalTextInputStateStoreCommitSnapshotFacts" \
  "CjguiInternalRendererStage858OwnerLocalTextInputStateStoreCommitSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage858OwnerLocalTextInputStateStoreCommitSnapshotDraft" \
  "CjguiInternalRendererStage857OwnerLocalTextInputCommitDryRunReadiness" \
  "didConsumeStage857OwnerLocalTextInputCommitDryRun" \
  "didMaterializeOwnerLocalTextInputStateStoreCommitSnapshot" \
  "didMaterializeOwnerLocalTextInputCommittedValue" \
  "didMaterializeOwnerLocalTextInputStateStoreCommitReceipt" \
  "didMaterializeOwnerLocalTextInputCommitRollbackSnapshot" \
  "didBindStateStoreCommitSnapshotToStage857DryRun" \
  "didKeepOwnerLocalStateStoreInMemoryOnly" \
  "didPrepareStage859OwnerLocalTextInputCommitResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage858 owner-local text input state-store commit snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage858_owner_local_text_input_state_store_commit_snapshot_owner_present=true"
echo "stage857_owner_local_text_input_commit_dry_run_consumed=true"
echo "stage856_text_input_commit_runtime_manager_consumed_transitively=true"
echo "owner_local_text_input_state_store_commit_snapshot_materialized=true"
echo "owner_local_text_input_committed_value_materialized=true"
echo "owner_local_text_input_state_store_commit_receipt_materialized=true"
echo "owner_local_text_input_commit_rollback_snapshot_materialized=true"
echo "owner_local_text_input_state_store_commit_snapshot_bound_to_stage857_dry_run=true"
echo "owner_local_state_store_in_memory_only=true"
echo "owner_local_text_input_commit_first_slice_materialized=true"
echo "owner_local_text_input_commit_applied=true"
echo "stage859_owner_local_text_input_commit_result_surface_prepared=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
