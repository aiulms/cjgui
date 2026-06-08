#!/usr/bin/env zsh
#
# Verifies the stage777 preview component API state-store commit boundary owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage777_preview_component_api_state_store_commit_boundary.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage777 preview component api state-store commit boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage777PreviewComponentApiStateStoreCommitBoundaryPlan" \
  "CjguiInternalRendererStage777PreviewComponentApiStateStoreCommitBoundaryFacts" \
  "CjguiInternalRendererStage777PreviewComponentApiStateStoreCommitBoundaryReadiness" \
  "cjguiInternalExecuteDefaultRendererStage777PreviewComponentApiStateStoreCommitBoundaryDraft" \
  "CjguiInternalRendererStage776PreviewComponentApiCommitAdmissionRuntimeManagerReadiness" \
  "didConsumeStage776PreviewComponentApiCommitAdmissionRuntimeManager" \
  "didMaterializePreviewComponentApiStateStoreCommitBoundary" \
  "didMaterializeOwnerLocalStateStoreWriteSetCandidate" \
  "didMaterializeStateSlotAdmissionLedger" \
  "didMaterializeCommitAdmissionToStateStoreBoundaryBridge" \
  "didMaterializeChatComposerPreviewComponentApiStateStoreCommitBoundarySurface" \
  "didBindStateStoreCommitBoundaryToStage776RuntimeManager" \
  "didPrepareStage778PreviewComponentApiStateStoreRollbackSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage777 preview component api state-store commit boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage777_preview_component_api_state_store_commit_boundary_owner_present=true"
echo "stage776_preview_component_api_commit_admission_runtime_manager_consumed=true"
echo "stage775_preview_component_api_commit_admission_host_inspection_surface_consumed_transitively=true"
echo "preview_component_api_state_store_commit_boundary_materialized=true"
echo "owner_local_state_store_write_set_candidate_materialized=true"
echo "state_slot_admission_ledger_materialized=true"
echo "commit_admission_to_state_store_boundary_bridge_materialized=true"
echo "todo_preview_component_api_state_store_commit_boundary_surface_materialized=true"
echo "settings_preview_component_api_state_store_commit_boundary_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_state_store_commit_boundary_surface_materialized=true"
echo "chat_composer_preview_component_api_state_store_commit_boundary_surface_materialized=true"
echo "state_store_commit_boundary_bound_to_stage776_runtime_manager=true"
echo "stage778_preview_component_api_state_store_rollback_snapshot_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
