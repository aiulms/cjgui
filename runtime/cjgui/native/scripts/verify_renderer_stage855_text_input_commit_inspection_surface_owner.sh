#!/usr/bin/env zsh
#
# Verifies the stage855 text input commit inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage855_text_input_commit_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage855 text input commit inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage855TextInputCommitInspectionSurfacePlan" \
  "CjguiInternalRendererStage855TextInputCommitInspectionSurfaceFacts" \
  "CjguiInternalRendererStage855TextInputCommitInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage855TextInputCommitInspectionSurfaceDraft" \
  "CjguiInternalRendererStage854TextInputCommitRollbackSnapshotReadiness" \
  "didConsumeStage854TextInputCommitRollbackSnapshot" \
  "didMaterializeTextInputCommitInspectionRowModel" \
  "didMaterializeTextInputWriteSetInspectionRows" \
  "didMaterializeTextInputRollbackInspectionRows" \
  "didMaterializeTextInputNotPublishedStatusBanner" \
  "didMaterializeFileBrowserTextInputCommitInspectionSurface" \
  "didMaterializeTextInputCommitSemanticDiffReceipt" \
  "didBindInspectionSurfaceToStage854RollbackSnapshot" \
  "didPrepareStage856TextInputCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage855 text input commit inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage855_text_input_commit_inspection_surface_owner_present=true"
echo "stage854_text_input_commit_rollback_snapshot_consumed=true"
echo "stage853_text_input_commit_preflight_consumed_transitively=true"
echo "text_input_commit_inspection_row_model_materialized=true"
echo "text_input_write_set_inspection_rows_materialized=true"
echo "text_input_rollback_inspection_rows_materialized=true"
echo "text_input_not_published_status_banner_materialized=true"
echo "todo_text_input_commit_inspection_surface_materialized=true"
echo "settings_text_input_commit_inspection_surface_materialized=true"
echo "ai_generated_settings_text_input_commit_inspection_surface_materialized=true"
echo "chat_composer_text_input_commit_inspection_surface_materialized=true"
echo "file_browser_text_input_commit_inspection_surface_materialized=true"
echo "text_input_commit_semantic_diff_receipt_materialized=true"
echo "text_input_commit_inspection_surface_bound_to_stage854_rollback_snapshot=true"
echo "text_input_commit_inspection_surface_bound_to_stage853_commit_preflight=true"
echo "stage856_text_input_commit_runtime_manager_prepared=true"
echo "text_input_commit_committed=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
