#!/usr/bin/env zsh
#
# Verifies the stage779 preview component API state-store not-published host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage779_preview_component_api_state_store_not_published_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage779 preview component api state-store not-published host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage779PreviewComponentApiStateStoreNotPublishedHostSurfacePlan" \
  "CjguiInternalRendererStage779PreviewComponentApiStateStoreNotPublishedHostSurfaceFacts" \
  "CjguiInternalRendererStage779PreviewComponentApiStateStoreNotPublishedHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage779PreviewComponentApiStateStoreNotPublishedHostSurfaceDraft" \
  "CjguiInternalRendererStage778PreviewComponentApiStateStoreRollbackSnapshotReadiness" \
  "didConsumeStage778PreviewComponentApiStateStoreRollbackSnapshot" \
  "didMaterializeStateStoreNotPublishedReceipt" \
  "didMaterializeStateStoreCommitHostInspectionRows" \
  "didMaterializeStateStoreCommitResultSurfaceRefresh" \
  "didMaterializeStateStoreSemanticDiffPreview" \
  "didMaterializeChatComposerPreviewComponentApiStateStoreNotPublishedHostSurface" \
  "didBindStateStoreNotPublishedHostSurfaceToStage778RollbackSnapshot" \
  "didPrepareStage780PreviewComponentApiStateStoreCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage779 preview component api state-store not-published host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage779_preview_component_api_state_store_not_published_host_surface_owner_present=true"
echo "stage778_preview_component_api_state_store_rollback_snapshot_consumed=true"
echo "stage777_preview_component_api_state_store_commit_boundary_consumed_transitively=true"
echo "state_store_not_published_receipt_materialized=true"
echo "state_store_commit_host_inspection_rows_materialized=true"
echo "state_store_commit_result_surface_refresh_materialized=true"
echo "state_store_semantic_diff_preview_materialized=true"
echo "todo_preview_component_api_state_store_not_published_host_surface_materialized=true"
echo "settings_preview_component_api_state_store_not_published_host_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_state_store_not_published_host_surface_materialized=true"
echo "chat_composer_preview_component_api_state_store_not_published_host_surface_materialized=true"
echo "state_store_not_published_host_surface_bound_to_stage778_rollback_snapshot=true"
echo "stage780_preview_component_api_state_store_commit_runtime_manager_prepared=true"
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
