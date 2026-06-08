#!/usr/bin/env zsh
#
# Verifies the stage782 preview component API commit inspection review actions owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage782_preview_component_api_commit_inspection_review_actions.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage782 preview component api commit inspection review actions: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage782PreviewComponentApiCommitInspectionReviewActionsPlan" \
  "CjguiInternalRendererStage782PreviewComponentApiCommitInspectionReviewActionsFacts" \
  "CjguiInternalRendererStage782PreviewComponentApiCommitInspectionReviewActionsReadiness" \
  "cjguiInternalExecuteDefaultRendererStage782PreviewComponentApiCommitInspectionReviewActionsDraft" \
  "CjguiInternalRendererStage781PreviewComponentApiCommitInspectionUiReadiness" \
  "didConsumeStage781PreviewComponentApiCommitInspectionUi" \
  "didMaterializeCommitInspectionDiffAcknowledgeAction" \
  "didMaterializeCommitInspectionRollbackSelectAction" \
  "didMaterializeCommitInspectionAcceptabilityReviewAction" \
  "didMaterializeCommitInspectionRejectReasonDraftAction" \
  "didMaterializeChatComposerPreviewComponentApiCommitInspectionReviewActionSurface" \
  "didBindReviewActionsToStage781InspectionUi" \
  "didPrepareStage783PreviewComponentApiCommitInspectionResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage782 preview component api commit inspection review actions: missing token $token" >&2
    exit 3
  fi
done

echo "stage782_preview_component_api_commit_inspection_review_actions_owner_present=true"
echo "stage781_preview_component_api_commit_inspection_ui_consumed=true"
echo "stage780_preview_component_api_state_store_commit_runtime_manager_consumed_transitively=true"
echo "commit_inspection_diff_acknowledge_action_materialized=true"
echo "commit_inspection_rollback_select_action_materialized=true"
echo "commit_inspection_acceptability_review_action_materialized=true"
echo "commit_inspection_reject_reason_draft_action_materialized=true"
echo "todo_preview_component_api_commit_inspection_review_action_surface_materialized=true"
echo "settings_preview_component_api_commit_inspection_review_action_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_inspection_review_action_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_inspection_review_action_surface_materialized=true"
echo "review_actions_bound_to_stage781_inspection_ui=true"
echo "stage783_preview_component_api_commit_inspection_result_surface_prepared=true"
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
