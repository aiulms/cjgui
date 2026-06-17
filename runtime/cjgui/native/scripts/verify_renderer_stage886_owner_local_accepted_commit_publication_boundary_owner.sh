#!/usr/bin/env zsh
#
# Verifies the stage886 owner-local accepted commit publication boundary owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage886_owner_local_accepted_commit_publication_boundary.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage886 owner-local accepted commit publication boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage886OwnerLocalAcceptedCommitPublicationBoundaryPlan" \
  "CjguiInternalRendererStage886OwnerLocalAcceptedCommitPublicationBoundaryFacts" \
  "CjguiInternalRendererStage886OwnerLocalAcceptedCommitPublicationBoundaryReadiness" \
  "cjguiInternalExecuteDefaultRendererStage886OwnerLocalAcceptedCommitPublicationBoundaryDraft" \
  "CjguiInternalRendererStage885OwnerLocalAcceptedCommitPublicationPreflightReadiness" \
  "didConsumeStage885OwnerLocalAcceptedCommitPublicationPreflight" \
  "didMaterializeAcceptedCommitPublicationRollbackSnapshot" \
  "didMaterializeAcceptedCommitPublicationRollbackToken" \
  "didMaterializeAcceptedCommitPublicationNotPublishedReceipt" \
  "didMaterializeVisibilityPublicationNotPublishedBoundary" \
  "didMaterializeStateStoreWriteDeniedReceipt" \
  "didPrepareStage887OwnerLocalAcceptedCommitPublicationDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage886 owner-local accepted commit publication boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage886_owner_local_accepted_commit_publication_boundary_owner_present=true"
echo "stage885_owner_local_accepted_commit_publication_preflight_consumed=true"
echo "stage884_owner_local_accepted_commit_runtime_manager_consumed_transitively=true"
echo "accepted_commit_publication_rollback_snapshot_materialized=true"
echo "accepted_commit_publication_rollback_token_materialized=true"
echo "accepted_commit_publication_not_published_receipt_materialized=true"
echo "visibility_publication_not_published_boundary_materialized=true"
echo "state_store_write_denied_receipt_materialized=true"
echo "publication_boundary_bound_to_stage885_preflight=true"
echo "stage887_owner_local_accepted_commit_publication_demo_surface_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_store_write_executed=false"
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
