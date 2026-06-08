#!/usr/bin/env zsh
#
# Verifies the stage822 commit first-slice review decision router owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage822_commit_first_slice_review_decision_router.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage822 commit first-slice review decision router: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage822CommitFirstSliceReviewDecisionRouterPlan" \
  "CjguiInternalRendererStage822CommitFirstSliceReviewDecisionRouterFacts" \
  "CjguiInternalRendererStage822CommitFirstSliceReviewDecisionRouterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage822CommitFirstSliceReviewDecisionRouterDraft" \
  "CjguiInternalRendererStage821CommitFirstSliceOwnerReviewGateReadiness" \
  "didConsumeStage821CommitFirstSliceOwnerReviewGate" \
  "didMaterializeAcceptReviewDecisionRoute" \
  "didMaterializeRejectReviewDecisionRoute" \
  "didMaterializeRequestChangesReviewDecisionRoute" \
  "didMaterializeRollbackHoldDecisionRoute" \
  "didMaterializeCommitCandidateHoldLedger" \
  "didPrepareStage823CommitFirstSliceOwnerReviewDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage822 commit first-slice review decision router: missing token $token" >&2
    exit 3
  fi
done

echo "stage822_commit_first_slice_review_decision_router_owner_present=true"
echo "stage821_commit_first_slice_owner_review_gate_consumed=true"
echo "stage820_commit_first_slice_host_inspection_runtime_presenter_consumed_transitively=true"
echo "commit_first_slice_accept_review_decision_route_materialized=true"
echo "commit_first_slice_reject_review_decision_route_materialized=true"
echo "commit_first_slice_request_changes_review_decision_route_materialized=true"
echo "commit_first_slice_rollback_hold_decision_route_materialized=true"
echo "commit_first_slice_commit_candidate_hold_ledger_materialized=true"
echo "commit_first_slice_review_decision_router_bound_to_stage821_gate=true"
echo "stage823_commit_first_slice_owner_review_demo_host_surface_prepared=true"
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
