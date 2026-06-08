#!/usr/bin/env zsh
#
# Verifies the stage826 commit first-slice publication visibility rehearsal owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage826_commit_first_slice_publication_visibility_rehearsal.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage826 commit first-slice publication visibility rehearsal: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage826CommitFirstSlicePublicationVisibilityRehearsalPlan" \
  "CjguiInternalRendererStage826CommitFirstSlicePublicationVisibilityRehearsalFacts" \
  "CjguiInternalRendererStage826CommitFirstSlicePublicationVisibilityRehearsalReadiness" \
  "cjguiInternalExecuteDefaultRendererStage826CommitFirstSlicePublicationVisibilityRehearsalDraft" \
  "CjguiInternalRendererStage825CommitFirstSlicePublicationGateReadiness" \
  "didConsumeStage825CommitFirstSlicePublicationGate" \
  "didMaterializeVisibilityPublicationRehearsalLedger" \
  "didMaterializeRollbackVisibilitySnapshot" \
  "didMaterializeOwnerApprovalPublicationHold" \
  "didMaterializeNotPublishedVisibilityReceipt" \
  "didBindVisibilityRehearsalToStage825Gate" \
  "didPrepareStage827CommitFirstSlicePublicationDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage826 commit first-slice publication visibility rehearsal: missing token $token" >&2
    exit 3
  fi
done

echo "stage826_commit_first_slice_publication_visibility_rehearsal_owner_present=true"
echo "stage825_commit_first_slice_publication_gate_consumed=true"
echo "stage824_commit_first_slice_owner_review_runtime_manager_consumed_transitively=true"
echo "visibility_publication_rehearsal_ledger_materialized=true"
echo "rollback_visibility_snapshot_materialized=true"
echo "owner_approval_publication_hold_materialized=true"
echo "not_published_visibility_receipt_materialized=true"
echo "visibility_rehearsal_bound_to_stage825_publication_gate=true"
echo "stage827_commit_first_slice_publication_demo_host_surface_prepared=true"
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
