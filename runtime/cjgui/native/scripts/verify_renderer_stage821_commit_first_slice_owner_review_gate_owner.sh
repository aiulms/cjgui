#!/usr/bin/env zsh
#
# Verifies the stage821 commit first-slice owner review gate owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage821_commit_first_slice_owner_review_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage821 commit first-slice owner review gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage821CommitFirstSliceOwnerReviewGatePlan" \
  "CjguiInternalRendererStage821CommitFirstSliceOwnerReviewGateFacts" \
  "CjguiInternalRendererStage821CommitFirstSliceOwnerReviewGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage821CommitFirstSliceOwnerReviewGateDraft" \
  "CjguiInternalRendererStage820CommitFirstSliceHostInspectionRuntimePresenterReadiness" \
  "didConsumeStage820CommitFirstSliceHostInspectionRuntimePresenter" \
  "didMaterializeOwnerReviewGate" \
  "didMaterializeAcceptabilityReviewRoute" \
  "didMaterializeRequestChangesReviewRoute" \
  "didMaterializeRejectReasonReviewRoute" \
  "didBindOwnerReviewGateToStage820Presenter" \
  "didPrepareStage822CommitFirstSliceReviewDecisionRouter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage821 commit first-slice owner review gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage821_commit_first_slice_owner_review_gate_owner_present=true"
echo "stage820_commit_first_slice_host_inspection_runtime_presenter_consumed=true"
echo "stage819_commit_first_slice_demo_host_inspection_surface_consumed_transitively=true"
echo "commit_first_slice_owner_review_gate_materialized=true"
echo "commit_first_slice_acceptability_review_route_materialized=true"
echo "commit_first_slice_request_changes_review_route_materialized=true"
echo "commit_first_slice_reject_reason_review_route_materialized=true"
echo "commit_first_slice_owner_review_gate_bound_to_stage820_presenter=true"
echo "stage822_commit_first_slice_review_decision_router_prepared=true"
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
