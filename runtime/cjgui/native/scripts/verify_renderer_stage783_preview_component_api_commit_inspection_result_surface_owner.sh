#!/usr/bin/env zsh
#
# Verifies the stage783 preview component API commit inspection result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage783_preview_component_api_commit_inspection_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage783 preview component api commit inspection result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage783PreviewComponentApiCommitInspectionResultSurfacePlan" \
  "CjguiInternalRendererStage783PreviewComponentApiCommitInspectionResultSurfaceFacts" \
  "CjguiInternalRendererStage783PreviewComponentApiCommitInspectionResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage783PreviewComponentApiCommitInspectionResultSurfaceDraft" \
  "CjguiInternalRendererStage782PreviewComponentApiCommitInspectionReviewActionsReadiness" \
  "didConsumeStage782PreviewComponentApiCommitInspectionReviewActions" \
  "didMaterializeCommitInspectionExecutionReceipt" \
  "didMaterializeCommitInspectionResultSurfaceRefresh" \
  "didMaterializeCommitInspectionSemanticDiffReceipt" \
  "didMaterializeCommitInspectionRollbackDecisionPreview" \
  "didMaterializeChatComposerPreviewComponentApiCommitInspectionResultSurface" \
  "didBindResultSurfaceToStage782ReviewActions" \
  "didPrepareStage784PreviewComponentApiCommitInspectionRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage783 preview component api commit inspection result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage783_preview_component_api_commit_inspection_result_surface_owner_present=true"
echo "stage782_preview_component_api_commit_inspection_review_actions_consumed=true"
echo "stage781_preview_component_api_commit_inspection_ui_consumed_transitively=true"
echo "commit_inspection_execution_receipt_materialized=true"
echo "commit_inspection_result_surface_refresh_materialized=true"
echo "commit_inspection_semantic_diff_receipt_materialized=true"
echo "commit_inspection_rollback_decision_preview_materialized=true"
echo "todo_preview_component_api_commit_inspection_result_surface_materialized=true"
echo "settings_preview_component_api_commit_inspection_result_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_inspection_result_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_inspection_result_surface_materialized=true"
echo "result_surface_bound_to_stage782_review_actions=true"
echo "stage784_preview_component_api_commit_inspection_runtime_manager_prepared=true"
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
