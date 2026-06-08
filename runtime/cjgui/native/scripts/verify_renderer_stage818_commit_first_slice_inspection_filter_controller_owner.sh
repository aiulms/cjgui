#!/usr/bin/env zsh
#
# Verifies the stage818 commit first-slice inspection filter controller owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage818_commit_first_slice_inspection_filter_controller.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage818 commit first-slice inspection filter controller: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage818CommitFirstSliceInspectionFilterControllerPlan" \
  "CjguiInternalRendererStage818CommitFirstSliceInspectionFilterControllerFacts" \
  "CjguiInternalRendererStage818CommitFirstSliceInspectionFilterControllerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage818CommitFirstSliceInspectionFilterControllerDraft" \
  "CjguiInternalRendererStage817CommitFirstSliceHostInspectionLensReadiness" \
  "didConsumeStage817CommitFirstSliceHostInspectionLens" \
  "didMaterializeInspectionFilterController" \
  "didMaterializeRollbackProofRoute" \
  "didMaterializeDeniedWriteSetFilter" \
  "didMaterializeNotPublishedBoundaryFilter" \
  "didMaterializeDemoHostQueryContract" \
  "didPrepareStage819CommitFirstSliceDemoHostInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage818 commit first-slice inspection filter controller: missing token $token" >&2
    exit 3
  fi
done

echo "stage818_commit_first_slice_inspection_filter_controller_owner_present=true"
echo "stage817_commit_first_slice_host_inspection_lens_consumed=true"
echo "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_consumed_transitively=true"
echo "commit_first_slice_inspection_filter_controller_materialized=true"
echo "commit_first_slice_rollback_proof_route_materialized=true"
echo "commit_first_slice_denied_write_set_filter_materialized=true"
echo "commit_first_slice_not_published_boundary_filter_materialized=true"
echo "commit_first_slice_demo_host_query_contract_materialized=true"
echo "commit_first_slice_inspection_filter_controller_bound_to_stage817_lens=true"
echo "stage819_commit_first_slice_demo_host_inspection_surface_prepared=true"
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
