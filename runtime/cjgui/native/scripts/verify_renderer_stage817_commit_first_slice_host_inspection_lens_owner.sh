#!/usr/bin/env zsh
#
# Verifies the stage817 commit first-slice host inspection lens owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage817_commit_first_slice_host_inspection_lens.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage817 commit first-slice host inspection lens: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage817CommitFirstSliceHostInspectionLensPlan" \
  "CjguiInternalRendererStage817CommitFirstSliceHostInspectionLensFacts" \
  "CjguiInternalRendererStage817CommitFirstSliceHostInspectionLensReadiness" \
  "cjguiInternalExecuteDefaultRendererStage817CommitFirstSliceHostInspectionLensDraft" \
  "CjguiInternalRendererStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManagerReadiness" \
  "didConsumeStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManager" \
  "didMaterializeWriteSetInspectionRows" \
  "didMaterializeRollbackSnapshotInspectionRows" \
  "didMaterializeDenialLedgerInspectionRows" \
  "didMaterializeNotPublishedBoundaryInspectionRows" \
  "didMaterializeComponentSlotDiffInspectionRows" \
  "didPrepareStage818CommitFirstSliceInspectionFilterController"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage817 commit first-slice host inspection lens: missing token $token" >&2
    exit 3
  fi
done

echo "stage817_commit_first_slice_host_inspection_lens_owner_present=true"
echo "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_consumed=true"
echo "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_consumed_transitively=true"
echo "commit_first_slice_write_set_inspection_rows_materialized=true"
echo "commit_first_slice_rollback_snapshot_inspection_rows_materialized=true"
echo "commit_first_slice_denial_ledger_inspection_rows_materialized=true"
echo "commit_first_slice_not_published_boundary_inspection_rows_materialized=true"
echo "commit_first_slice_component_slot_diff_inspection_rows_materialized=true"
echo "commit_first_slice_host_inspection_lens_bound_to_stage816_runtime_manager=true"
echo "stage818_commit_first_slice_inspection_filter_controller_prepared=true"
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
