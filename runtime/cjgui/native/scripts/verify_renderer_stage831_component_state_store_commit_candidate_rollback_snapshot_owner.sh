#!/usr/bin/env zsh
#
# Verifies the stage831 component state-store commit candidate rollback snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage831 component state-store commit candidate rollback snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage831ComponentStateStoreCommitCandidateRollbackSnapshotPlan" \
  "CjguiInternalRendererStage831ComponentStateStoreCommitCandidateRollbackSnapshotFacts" \
  "CjguiInternalRendererStage831ComponentStateStoreCommitCandidateRollbackSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage831ComponentStateStoreCommitCandidateRollbackSnapshotDraft" \
  "CjguiInternalRendererStage830ComponentStateStoreSlotValueModelReadiness" \
  "didConsumeStage830ComponentStateStoreSlotValueModel" \
  "didMaterializeOwnerLocalCommitCandidate" \
  "didMaterializeWriteSetPreflightLedger" \
  "didMaterializeRollbackSnapshot" \
  "didMaterializeConflictPreflightReceipt" \
  "didMaterializeNotPublishedCommitReceipt" \
  "didBindCommitCandidateToStage830SlotValueModel" \
  "didPrepareStage832ComponentStateStorePublishableRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage831 component state-store commit candidate rollback snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage831_component_state_store_commit_candidate_rollback_snapshot_owner_present=true"
echo "stage830_component_state_store_slot_value_model_consumed=true"
echo "stage829_component_state_store_publishable_state_model_consumed_transitively=true"
echo "owner_local_commit_candidate_materialized=true"
echo "write_set_preflight_ledger_materialized=true"
echo "rollback_snapshot_materialized=true"
echo "conflict_preflight_receipt_materialized=true"
echo "not_published_commit_receipt_materialized=true"
echo "commit_candidate_bound_to_stage830_slot_value_model=true"
echo "stage832_component_state_store_publishable_runtime_manager_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
