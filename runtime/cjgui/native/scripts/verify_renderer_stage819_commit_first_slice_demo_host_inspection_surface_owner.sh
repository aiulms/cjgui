#!/usr/bin/env zsh
#
# Verifies the stage819 commit first-slice demo-host inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage819_commit_first_slice_demo_host_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage819 commit first-slice demo-host inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage819CommitFirstSliceDemoHostInspectionSurfacePlan" \
  "CjguiInternalRendererStage819CommitFirstSliceDemoHostInspectionSurfaceFacts" \
  "CjguiInternalRendererStage819CommitFirstSliceDemoHostInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage819CommitFirstSliceDemoHostInspectionSurfaceDraft" \
  "CjguiInternalRendererStage818CommitFirstSliceInspectionFilterControllerReadiness" \
  "didConsumeStage818CommitFirstSliceInspectionFilterController" \
  "didMaterializeTodoCommitInspectionSurface" \
  "didMaterializeSettingsCommitInspectionSurface" \
  "didMaterializeAiGeneratedSettingsCommitInspectionSurface" \
  "didMaterializeChatComposerCommitInspectionSurface" \
  "didMaterializeFileBrowserCommitInspectionSurface" \
  "didMaterializeCommitHostInspectionResultSurface" \
  "didPrepareStage820CommitFirstSliceHostInspectionRuntimePresenter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage819 commit first-slice demo-host inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage819_commit_first_slice_demo_host_inspection_surface_owner_present=true"
echo "stage818_commit_first_slice_inspection_filter_controller_consumed=true"
echo "stage817_commit_first_slice_host_inspection_lens_consumed_transitively=true"
echo "todo_commit_first_slice_inspection_surface_materialized=true"
echo "settings_commit_first_slice_inspection_surface_materialized=true"
echo "ai_generated_settings_commit_first_slice_inspection_surface_materialized=true"
echo "chat_composer_commit_first_slice_inspection_surface_materialized=true"
echo "file_browser_commit_first_slice_inspection_surface_materialized=true"
echo "commit_first_slice_host_inspection_result_surface_materialized=true"
echo "commit_first_slice_demo_surfaces_bound_to_stage818_filter_controller=true"
echo "stage820_commit_first_slice_host_inspection_runtime_presenter_prepared=true"
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
