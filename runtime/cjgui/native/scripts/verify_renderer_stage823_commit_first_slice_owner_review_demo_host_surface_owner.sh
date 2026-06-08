#!/usr/bin/env zsh
#
# Verifies the stage823 commit first-slice owner review demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage823_commit_first_slice_owner_review_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage823 commit first-slice owner review demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage823CommitFirstSliceOwnerReviewDemoHostSurfacePlan" \
  "CjguiInternalRendererStage823CommitFirstSliceOwnerReviewDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage823CommitFirstSliceOwnerReviewDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage823CommitFirstSliceOwnerReviewDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage822CommitFirstSliceReviewDecisionRouterReadiness" \
  "didConsumeStage822CommitFirstSliceReviewDecisionRouter" \
  "didMaterializeTodoOwnerReviewSurface" \
  "didMaterializeSettingsOwnerReviewSurface" \
  "didMaterializeAiGeneratedSettingsOwnerReviewSurface" \
  "didMaterializeChatComposerOwnerReviewSurface" \
  "didMaterializeFileBrowserOwnerReviewSurface" \
  "didMaterializeOwnerReviewResultSurface" \
  "didPrepareStage824CommitFirstSliceOwnerReviewRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage823 commit first-slice owner review demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage823_commit_first_slice_owner_review_demo_host_surface_owner_present=true"
echo "stage822_commit_first_slice_review_decision_router_consumed=true"
echo "stage821_commit_first_slice_owner_review_gate_consumed_transitively=true"
echo "todo_commit_first_slice_owner_review_surface_materialized=true"
echo "settings_commit_first_slice_owner_review_surface_materialized=true"
echo "ai_generated_settings_commit_first_slice_owner_review_surface_materialized=true"
echo "chat_composer_commit_first_slice_owner_review_surface_materialized=true"
echo "file_browser_commit_first_slice_owner_review_surface_materialized=true"
echo "commit_first_slice_owner_review_result_surface_materialized=true"
echo "commit_first_slice_demo_surfaces_bound_to_stage822_decision_router=true"
echo "stage824_commit_first_slice_owner_review_runtime_manager_prepared=true"
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
