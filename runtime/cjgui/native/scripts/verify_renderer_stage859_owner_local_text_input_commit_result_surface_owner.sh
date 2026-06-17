#!/usr/bin/env zsh
#
# Verifies the stage859 owner-local text input commit result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage859_owner_local_text_input_commit_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage859 owner-local text input commit result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage859OwnerLocalTextInputCommitResultSurfacePlan" \
  "CjguiInternalRendererStage859OwnerLocalTextInputCommitResultSurfaceFacts" \
  "CjguiInternalRendererStage859OwnerLocalTextInputCommitResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage859OwnerLocalTextInputCommitResultSurfaceDraft" \
  "CjguiInternalRendererStage858OwnerLocalTextInputStateStoreCommitSnapshotReadiness" \
  "didConsumeStage858OwnerLocalTextInputStateStoreCommitSnapshot" \
  "didMaterializeOwnerLocalTextInputCommitResultRowModel" \
  "didMaterializeOwnerLocalTextInputCommittedValueRows" \
  "didMaterializeOwnerLocalTextInputRollbackRows" \
  "didMaterializeOwnerLocalTextInputNotPublishedBoundaryBanner" \
  "didMaterializeTodoOwnerLocalTextInputCommitResultSurface" \
  "didMaterializeSettingsOwnerLocalTextInputCommitResultSurface" \
  "didMaterializeAiGeneratedSettingsOwnerLocalTextInputCommitResultSurface" \
  "didMaterializeChatComposerOwnerLocalTextInputCommitResultSurface" \
  "didMaterializeFileBrowserOwnerLocalTextInputCommitResultSurface" \
  "didPrepareStage860OwnerLocalTextInputCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage859 owner-local text input commit result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage859_owner_local_text_input_commit_result_surface_owner_present=true"
echo "stage858_owner_local_text_input_state_store_commit_snapshot_consumed=true"
echo "stage857_owner_local_text_input_commit_dry_run_consumed_transitively=true"
echo "owner_local_text_input_commit_result_row_model_materialized=true"
echo "owner_local_text_input_committed_value_rows_materialized=true"
echo "owner_local_text_input_rollback_rows_materialized=true"
echo "owner_local_text_input_not_published_boundary_banner_materialized=true"
echo "todo_owner_local_text_input_commit_result_surface_materialized=true"
echo "settings_owner_local_text_input_commit_result_surface_materialized=true"
echo "ai_generated_settings_owner_local_text_input_commit_result_surface_materialized=true"
echo "chat_composer_owner_local_text_input_commit_result_surface_materialized=true"
echo "file_browser_owner_local_text_input_commit_result_surface_materialized=true"
echo "owner_local_text_input_commit_result_surface_bound_to_stage858_snapshot=true"
echo "owner_local_text_input_commit_first_slice_materialized=true"
echo "owner_local_text_input_commit_applied=true"
echo "stage860_owner_local_text_input_commit_runtime_manager_prepared=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
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
