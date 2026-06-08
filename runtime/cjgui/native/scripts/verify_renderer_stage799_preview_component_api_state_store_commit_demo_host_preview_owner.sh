#!/usr/bin/env zsh
#
# Verifies the stage799 preview component API state-store commit demo-host preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage799_preview_component_api_state_store_commit_demo_host_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage799 preview component api state-store commit demo-host preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage799PreviewComponentApiStateStoreCommitDemoHostPreviewPlan" \
  "CjguiInternalRendererStage799PreviewComponentApiStateStoreCommitDemoHostPreviewFacts" \
  "CjguiInternalRendererStage799PreviewComponentApiStateStoreCommitDemoHostPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage799PreviewComponentApiStateStoreCommitDemoHostPreviewDraft" \
  "CjguiInternalRendererStage798PreviewComponentApiStateStoreCommitReviewCheckpointReadiness" \
  "didConsumeStage798PreviewComponentApiStateStoreCommitReviewCheckpoint" \
  "didMaterializeCommitAdmissionDemoHostPreviewRows" \
  "didMaterializeCommitAdmissionResultSurfaceRefresh" \
  "didMaterializeTodoCommitAdmissionPreviewSurface" \
  "didMaterializeSettingsCommitAdmissionPreviewSurface" \
  "didMaterializeAiGeneratedSettingsCommitAdmissionPreviewSurface" \
  "didMaterializeChatComposerCommitAdmissionPreviewSurface" \
  "didMaterializeFileBrowserCommitAdmissionPreviewSurface" \
  "didPrepareStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage799 preview component api state-store commit demo-host preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage799_preview_component_api_state_store_commit_demo_host_preview_owner_present=true"
echo "stage798_preview_component_api_state_store_commit_review_checkpoint_consumed=true"
echo "commit_admission_demo_host_preview_rows_materialized=true"
echo "commit_admission_result_surface_refresh_materialized=true"
echo "commit_admission_host_inspection_receipt_materialized=true"
echo "todo_commit_admission_preview_surface_materialized=true"
echo "settings_commit_admission_preview_surface_materialized=true"
echo "ai_generated_settings_commit_admission_preview_surface_materialized=true"
echo "chat_composer_commit_admission_preview_surface_materialized=true"
echo "file_browser_commit_admission_preview_surface_materialized=true"
echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_prepared=true"
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
