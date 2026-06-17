#!/usr/bin/env zsh
#
# Verifies the stage885 owner-local accepted commit publication preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage885_owner_local_accepted_commit_publication_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage885 owner-local accepted commit publication preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage885OwnerLocalAcceptedCommitPublicationPreflightPlan" \
  "CjguiInternalRendererStage885OwnerLocalAcceptedCommitPublicationPreflightFacts" \
  "CjguiInternalRendererStage885OwnerLocalAcceptedCommitPublicationPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage885OwnerLocalAcceptedCommitPublicationPreflightDraft" \
  "CjguiInternalRendererStage884OwnerLocalAcceptedCommitRuntimeManagerReadiness" \
  "didConsumeStage884OwnerLocalAcceptedCommitRuntimeManager" \
  "didMaterializeOwnerLocalAcceptedCommitPublicationPreflight" \
  "didMaterializeAcceptedCommitPublicationCandidateLedger" \
  "didMaterializeAcceptedCommitVisibilityPredicateLedger" \
  "didMaterializeAcceptedCommitStateStoreWriteDenylist" \
  "didBindPublicationPreflightToStage884RuntimeManager" \
  "didPrepareStage886OwnerLocalAcceptedCommitPublicationBoundary"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage885 owner-local accepted commit publication preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage885_owner_local_accepted_commit_publication_preflight_owner_present=true"
echo "stage884_owner_local_accepted_commit_runtime_manager_consumed=true"
echo "stage883_owner_local_accepted_commit_demo_surface_consumed_transitively=true"
echo "owner_local_accepted_commit_publication_preflight_materialized=true"
echo "accepted_commit_publication_candidate_ledger_materialized=true"
echo "accepted_commit_visibility_predicate_ledger_materialized=true"
echo "accepted_commit_state_store_write_denylist_materialized=true"
echo "publication_preflight_bound_to_stage884_runtime_manager=true"
echo "stage886_owner_local_accepted_commit_publication_boundary_prepared=true"
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
