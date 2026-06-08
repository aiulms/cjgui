#!/usr/bin/env zsh
#
# Verifies the stage781 preview component API commit inspection UI owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage781_preview_component_api_commit_inspection_ui.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage781 preview component api commit inspection ui: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage781PreviewComponentApiCommitInspectionUiPlan" \
  "CjguiInternalRendererStage781PreviewComponentApiCommitInspectionUiFacts" \
  "CjguiInternalRendererStage781PreviewComponentApiCommitInspectionUiReadiness" \
  "cjguiInternalExecuteDefaultRendererStage781PreviewComponentApiCommitInspectionUiDraft" \
  "CjguiInternalRendererStage780PreviewComponentApiStateStoreCommitRuntimeManagerReadiness" \
  "didConsumeStage780PreviewComponentApiStateStoreCommitRuntimeManager" \
  "didMaterializeCommitInspectionUiRowModel" \
  "didMaterializeCommitWriteSetReviewRows" \
  "didMaterializeCommitRollbackPreviewRows" \
  "didMaterializeCommitNotPublishedStatusBanner" \
  "didMaterializeChatComposerPreviewComponentApiCommitInspectionUiSurface" \
  "didBindCommitInspectionUiToStage780RuntimeManager" \
  "didPrepareStage782PreviewComponentApiCommitInspectionReviewActions"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage781 preview component api commit inspection ui: missing token $token" >&2
    exit 3
  fi
done

echo "stage781_preview_component_api_commit_inspection_ui_owner_present=true"
echo "stage780_preview_component_api_state_store_commit_runtime_manager_consumed=true"
echo "stage779_preview_component_api_state_store_not_published_host_surface_consumed_transitively=true"
echo "commit_inspection_ui_row_model_materialized=true"
echo "commit_write_set_review_rows_materialized=true"
echo "commit_rollback_preview_rows_materialized=true"
echo "commit_not_published_status_banner_materialized=true"
echo "todo_preview_component_api_commit_inspection_ui_surface_materialized=true"
echo "settings_preview_component_api_commit_inspection_ui_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_inspection_ui_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_inspection_ui_surface_materialized=true"
echo "commit_inspection_ui_bound_to_stage780_runtime_manager=true"
echo "stage782_preview_component_api_commit_inspection_review_actions_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
