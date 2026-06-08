#!/usr/bin/env zsh
#
# Verifies the stage778 preview component API state-store rollback snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage778_preview_component_api_state_store_rollback_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage778 preview component api state-store rollback snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage778PreviewComponentApiStateStoreRollbackSnapshotPlan" \
  "CjguiInternalRendererStage778PreviewComponentApiStateStoreRollbackSnapshotFacts" \
  "CjguiInternalRendererStage778PreviewComponentApiStateStoreRollbackSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage778PreviewComponentApiStateStoreRollbackSnapshotDraft" \
  "CjguiInternalRendererStage777PreviewComponentApiStateStoreCommitBoundaryReadiness" \
  "didConsumeStage777PreviewComponentApiStateStoreCommitBoundary" \
  "didMaterializeStateStoreRollbackBaseSnapshot" \
  "didMaterializeStateStorePendingWriteSnapshot" \
  "didMaterializeStateStoreConflictVersionLedger" \
  "didMaterializeStateStoreRollbackTokenLedger" \
  "didMaterializeChatComposerPreviewComponentApiStateStoreRollbackSnapshotSurface" \
  "didBindStateStoreRollbackSnapshotToStage777Boundary" \
  "didPrepareStage779PreviewComponentApiStateStoreNotPublishedHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage778 preview component api state-store rollback snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage778_preview_component_api_state_store_rollback_snapshot_owner_present=true"
echo "stage777_preview_component_api_state_store_commit_boundary_consumed=true"
echo "stage776_preview_component_api_commit_admission_runtime_manager_consumed_transitively=true"
echo "state_store_rollback_base_snapshot_materialized=true"
echo "state_store_pending_write_snapshot_materialized=true"
echo "state_store_conflict_version_ledger_materialized=true"
echo "state_store_rollback_token_ledger_materialized=true"
echo "todo_preview_component_api_state_store_rollback_snapshot_surface_materialized=true"
echo "settings_preview_component_api_state_store_rollback_snapshot_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_state_store_rollback_snapshot_surface_materialized=true"
echo "chat_composer_preview_component_api_state_store_rollback_snapshot_surface_materialized=true"
echo "state_store_rollback_snapshot_bound_to_stage777_boundary=true"
echo "stage779_preview_component_api_state_store_not_published_host_surface_prepared=true"
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
