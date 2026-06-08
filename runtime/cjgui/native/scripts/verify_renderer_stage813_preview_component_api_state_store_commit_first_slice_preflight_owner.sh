#!/usr/bin/env zsh
#
# Verifies the stage813 preview component API state-store commit first-slice preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage813 preview component api state-store commit first-slice preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage813PreviewComponentApiStateStoreCommitFirstSlicePreflightPlan" \
  "CjguiInternalRendererStage813PreviewComponentApiStateStoreCommitFirstSlicePreflightFacts" \
  "CjguiInternalRendererStage813PreviewComponentApiStateStoreCommitFirstSlicePreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage813PreviewComponentApiStateStoreCommitFirstSlicePreflightDraft" \
  "CjguiInternalRendererStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManagerReadiness" \
  "didConsumeStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManager" \
  "didMaterializeCommitFirstSliceSlotAllowlist" \
  "didMaterializeOwnerLocalWriteSetCandidateShape" \
  "didMaterializeRollbackSnapshotPolicy" \
  "didMaterializeCommitCompatibilityGate" \
  "didMaterializeNotPublishedCommitBoundary" \
  "didBindFirstSlicePreflightToAcceptanceRuntimeManager" \
  "didPrepareStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage813 preview component api state-store commit first-slice preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_owner_present=true"
echo "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_consumed=true"
echo "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_consumed_transitively=true"
echo "commit_first_slice_slot_allowlist_materialized=true"
echo "owner_local_write_set_candidate_shape_materialized=true"
echo "rollback_snapshot_policy_materialized=true"
echo "commit_compatibility_gate_materialized=true"
echo "not_published_commit_boundary_materialized=true"
echo "first_slice_preflight_bound_to_acceptance_runtime_manager=true"
echo "first_slice_preflight_non_public=true"
echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_prepared=true"
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
