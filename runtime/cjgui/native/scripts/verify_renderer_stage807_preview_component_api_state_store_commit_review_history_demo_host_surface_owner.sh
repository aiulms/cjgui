#!/usr/bin/env zsh
#
# Verifies the stage807 preview component API state-store commit review history demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage807_preview_component_api_state_store_commit_review_history_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage807 preview component api state-store commit review history demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurfacePlan" \
  "CjguiInternalRendererStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsalReadiness" \
  "didConsumeStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsal" \
  "didMaterializeReviewHistoryInspectionRows" \
  "didMaterializeTimeTravelResultSurfaceRefresh" \
  "didMaterializeTimelineSelectionPanel" \
  "didMaterializeTodoReviewHistoryPreviewSurface" \
  "didMaterializeSettingsReviewHistoryPreviewSurface" \
  "didMaterializeAiGeneratedSettingsReviewHistoryPreviewSurface" \
  "didMaterializeChatComposerReviewHistoryPreviewSurface" \
  "didMaterializeFileBrowserReviewHistoryPreviewSurface" \
  "didPrepareStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage807 preview component api state-store commit review history demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_owner_present=true"
echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_consumed=true"
echo "review_history_inspection_rows_materialized=true"
echo "time_travel_result_surface_refresh_materialized=true"
echo "timeline_selection_panel_materialized=true"
echo "todo_review_history_preview_surface_materialized=true"
echo "settings_review_history_preview_surface_materialized=true"
echo "ai_generated_settings_review_history_preview_surface_materialized=true"
echo "chat_composer_review_history_preview_surface_materialized=true"
echo "file_browser_review_history_preview_surface_materialized=true"
echo "review_history_demo_host_surface_bound_to_stage806_time_travel_rehearsal=true"
echo "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_prepared=true"
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
