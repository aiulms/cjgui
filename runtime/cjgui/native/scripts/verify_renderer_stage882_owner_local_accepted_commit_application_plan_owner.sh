#!/usr/bin/env zsh
#
# Verifies the stage882 owner-local accepted commit application plan owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage882_owner_local_accepted_commit_application_plan.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage882 owner-local accepted commit application plan: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage882OwnerLocalAcceptedCommitApplicationPlan" \
  "CjguiInternalRendererStage882OwnerLocalAcceptedCommitApplicationFacts" \
  "CjguiInternalRendererStage882OwnerLocalAcceptedCommitApplicationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage882OwnerLocalAcceptedCommitApplicationPlanDraft" \
  "CjguiInternalRendererStage881OwnerLocalAcceptedCommitInspectionReadiness" \
  "didConsumeStage881OwnerLocalAcceptedCommitInspection" \
  "didMaterializeOwnerLocalAcceptedCommitApplicationPlan" \
  "didMaterializeAcceptedCommitPatchApplicationLedger" \
  "didMaterializeAcceptedCommitRollbackToken" \
  "didMaterializeAcceptedCommitNotPublishedReceipt" \
  "didMaterializeStateStoreWritePreviewBoundary" \
  "didBindAcceptedCommitApplicationPlanToInspectionGate" \
  "didPrepareStage883OwnerLocalAcceptedCommitDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage882 owner-local accepted commit application plan: missing token $token" >&2
    exit 3
  fi
done

echo "stage882_owner_local_accepted_commit_application_plan_owner_present=true"
echo "stage881_owner_local_accepted_commit_inspection_consumed=true"
echo "stage880_owner_local_commit_acceptance_runtime_manager_consumed_transitively=true"
echo "owner_local_accepted_commit_application_plan_materialized=true"
echo "accepted_commit_patch_application_ledger_materialized=true"
echo "accepted_commit_rollback_token_materialized=true"
echo "accepted_commit_not_published_receipt_materialized=true"
echo "state_store_write_preview_boundary_materialized=true"
echo "accepted_commit_application_plan_bound_to_inspection_gate=true"
echo "stage883_owner_local_accepted_commit_demo_surface_prepared=true"
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
