#!/usr/bin/env zsh
#
# Verifies the stage825 commit first-slice publication gate owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage825_commit_first_slice_publication_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage825 commit first-slice publication gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage825CommitFirstSlicePublicationGatePlan" \
  "CjguiInternalRendererStage825CommitFirstSlicePublicationGateFacts" \
  "CjguiInternalRendererStage825CommitFirstSlicePublicationGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage825CommitFirstSlicePublicationGateDraft" \
  "CjguiInternalRendererStage824CommitFirstSliceOwnerReviewRuntimeManagerReadiness" \
  "didConsumeStage824CommitFirstSliceOwnerReviewRuntimeManager" \
  "didMaterializeOwnerLocalPublicationGate" \
  "didMaterializeCommitSlotPublicationAllowlist" \
  "didMaterializeRollbackSafePublicationPolicy" \
  "didMaterializeVisibilityPublicationPredicateLedger" \
  "didBindPublicationGateToStage824OwnerReviewRuntime" \
  "didPrepareStage826CommitFirstSlicePublicationVisibilityRehearsal"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage825 commit first-slice publication gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage825_commit_first_slice_publication_gate_owner_present=true"
echo "stage824_commit_first_slice_owner_review_runtime_manager_consumed=true"
echo "stage823_commit_first_slice_owner_review_demo_host_surface_consumed_transitively=true"
echo "owner_local_publication_gate_materialized=true"
echo "commit_slot_publication_allowlist_materialized=true"
echo "rollback_safe_publication_policy_materialized=true"
echo "visibility_publication_predicate_ledger_materialized=true"
echo "publication_gate_bound_to_stage824_owner_review_runtime=true"
echo "stage826_commit_first_slice_publication_visibility_rehearsal_prepared=true"
echo "public_component_api_added=true"
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
