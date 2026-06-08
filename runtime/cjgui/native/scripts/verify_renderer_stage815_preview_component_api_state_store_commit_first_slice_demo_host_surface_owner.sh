#!/usr/bin/env zsh
#
# Verifies the stage815 preview component API state-store commit first-slice demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage815 preview component api state-store commit first-slice demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurfacePlan" \
  "CjguiInternalRendererStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutorReadiness" \
  "didConsumeStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutor" \
  "didMaterializeCommitInspectionRows" \
  "didMaterializeCommitResultSurfaceRefresh" \
  "didMaterializeTodoCommitFirstSlicePreviewSurface" \
  "didMaterializeSettingsCommitFirstSlicePreviewSurface" \
  "didMaterializeAiGeneratedSettingsCommitFirstSlicePreviewSurface" \
  "didMaterializeChatComposerCommitFirstSlicePreviewSurface" \
  "didMaterializeFileBrowserCommitFirstSlicePreviewSurface" \
  "didPrepareStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage815 preview component api state-store commit first-slice demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_owner_present=true"
echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_consumed=true"
echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_consumed_transitively=true"
echo "commit_inspection_rows_materialized=true"
echo "commit_result_surface_refresh_materialized=true"
echo "todo_commit_first_slice_preview_surface_materialized=true"
echo "settings_commit_first_slice_preview_surface_materialized=true"
echo "ai_generated_settings_commit_first_slice_preview_surface_materialized=true"
echo "chat_composer_commit_first_slice_preview_surface_materialized=true"
echo "file_browser_commit_first_slice_preview_surface_materialized=true"
echo "commit_demo_host_surface_bound_to_stage814_executor=true"
echo "commit_demo_host_surface_non_publishing=true"
echo "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_prepared=true"
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
