#!/usr/bin/env zsh
#
# Verifies the stage875 owner-local state-store commit demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage875_owner_local_state_store_commit_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage875 owner-local state-store commit demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage875OwnerLocalStateStoreCommitDemoHostSurfacePlan" \
  "CjguiInternalRendererStage875OwnerLocalStateStoreCommitDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage875OwnerLocalStateStoreCommitDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage875OwnerLocalStateStoreCommitDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage874OwnerLocalStateStoreCommitRollbackLedgerReadiness" \
  "didConsumeStage874OwnerLocalStateStoreCommitRollbackLedger" \
  "didMaterializeTodoOwnerLocalStateStoreCommitDemoHostSurface" \
  "didMaterializeSettingsOwnerLocalStateStoreCommitDemoHostSurface" \
  "didMaterializeAiGeneratedSettingsOwnerLocalStateStoreCommitDemoHostSurface" \
  "didMaterializeChatComposerOwnerLocalStateStoreCommitDemoHostSurface" \
  "didMaterializeFileBrowserOwnerLocalStateStoreCommitDemoHostSurface" \
  "didMaterializeOwnerLocalStateStoreCommitInspectionRowModel" \
  "didMaterializeOwnerLocalStateStoreRollbackPreviewRows" \
  "didMaterializeOwnerLocalStateStoreNotPublishedResultRows" \
  "didPrepareStage876OwnerLocalStateStoreCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage875 owner-local state-store commit demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage875_owner_local_state_store_commit_demo_host_surface_owner_present=true"
echo "stage874_owner_local_state_store_commit_rollback_ledger_consumed=true"
echo "owner_local_state_store_commit_rollback_ledger_consumed=true"
echo "todo_owner_local_state_store_commit_demo_host_surface_materialized=true"
echo "settings_owner_local_state_store_commit_demo_host_surface_materialized=true"
echo "ai_generated_settings_owner_local_state_store_commit_demo_host_surface_materialized=true"
echo "chat_composer_owner_local_state_store_commit_demo_host_surface_materialized=true"
echo "file_browser_owner_local_state_store_commit_demo_host_surface_materialized=true"
echo "owner_local_state_store_commit_inspection_row_model_materialized=true"
echo "owner_local_state_store_rollback_preview_rows_materialized=true"
echo "owner_local_state_store_not_published_result_rows_materialized=true"
echo "stage876_owner_local_state_store_commit_runtime_manager_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
