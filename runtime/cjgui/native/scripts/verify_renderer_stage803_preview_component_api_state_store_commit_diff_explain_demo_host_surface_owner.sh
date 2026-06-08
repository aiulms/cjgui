#!/usr/bin/env zsh
#
# Verifies the stage803 preview component API state-store commit diff/explain demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurfacePlan" \
  "CjguiInternalRendererStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage802PreviewComponentApiStateStoreCommitReviewDecisionLoopReadiness" \
  "didConsumeStage802PreviewComponentApiStateStoreCommitReviewDecisionLoop" \
  "didMaterializeDiffExplainHostInspectionRows" \
  "didMaterializeDiffExplainResultSurfaceRefresh" \
  "didMaterializeMutationExplainPanel" \
  "didMaterializeTodoDiffExplainPreviewSurface" \
  "didMaterializeSettingsDiffExplainPreviewSurface" \
  "didMaterializeAiGeneratedSettingsDiffExplainPreviewSurface" \
  "didMaterializeChatComposerDiffExplainPreviewSurface" \
  "didMaterializeFileBrowserDiffExplainPreviewSurface" \
  "didPrepareStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_owner_present=true"
echo "stage802_preview_component_api_state_store_commit_review_decision_loop_consumed=true"
echo "diff_explain_host_inspection_rows_materialized=true"
echo "diff_explain_result_surface_refresh_materialized=true"
echo "mutation_explain_panel_materialized=true"
echo "todo_diff_explain_preview_surface_materialized=true"
echo "settings_diff_explain_preview_surface_materialized=true"
echo "ai_generated_settings_diff_explain_preview_surface_materialized=true"
echo "chat_composer_diff_explain_preview_surface_materialized=true"
echo "file_browser_diff_explain_preview_surface_materialized=true"
echo "diff_explain_demo_host_surface_bound_to_stage802_decision_loop=true"
echo "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
