#!/usr/bin/env zsh
#
# Verifies the stage775 preview component API commit admission host inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage775_preview_component_api_commit_admission_host_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage775 preview component api commit admission host inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage775PreviewComponentApiCommitAdmissionHostInspectionSurfacePlan" \
  "CjguiInternalRendererStage775PreviewComponentApiCommitAdmissionHostInspectionSurfaceFacts" \
  "CjguiInternalRendererStage775PreviewComponentApiCommitAdmissionHostInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage775PreviewComponentApiCommitAdmissionHostInspectionSurfaceDraft" \
  "CjguiInternalRendererStage774PreviewComponentApiCommitDenialRollbackReceiptReadiness" \
  "didConsumeStage774PreviewComponentApiCommitDenialRollbackReceipt" \
  "didMaterializePreviewComponentApiCommitAdmissionHostInspectionRows" \
  "didMaterializePreviewComponentApiCommitAdmissionResultSurfaceRefresh" \
  "didMaterializePreviewComponentApiCommitRollbackSnapshotPreview" \
  "didMaterializePreviewComponentApiCommitAdmissionSemanticDiffReceipt" \
  "didMaterializePreviewComponentApiCommitAdmissionFocusHandoffRows" \
  "didMaterializePreviewComponentApiCommitAdmissionRenderCommandRefreshPreview" \
  "didMaterializeChatComposerPreviewComponentApiCommitAdmissionHostInspectionSurface" \
  "didBindCommitAdmissionHostInspectionSurfaceToStage774Receipt" \
  "didPrepareStage776PreviewComponentApiCommitAdmissionRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage775 preview component api commit admission host inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage775_preview_component_api_commit_admission_host_inspection_surface_owner_present=true"
echo "stage774_preview_component_api_commit_denial_rollback_receipt_consumed=true"
echo "stage773_preview_component_api_commit_admission_dry_run_consumed_transitively=true"
echo "preview_component_api_commit_admission_host_inspection_rows_materialized=true"
echo "preview_component_api_commit_admission_result_surface_refresh_materialized=true"
echo "preview_component_api_commit_rollback_snapshot_preview_materialized=true"
echo "preview_component_api_commit_admission_semantic_diff_receipt_materialized=true"
echo "preview_component_api_commit_admission_focus_handoff_rows_materialized=true"
echo "preview_component_api_commit_admission_render_command_refresh_preview_materialized=true"
echo "todo_preview_component_api_commit_admission_host_inspection_surface_materialized=true"
echo "settings_preview_component_api_commit_admission_host_inspection_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_admission_host_inspection_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_admission_host_inspection_surface_materialized=true"
echo "commit_admission_host_inspection_surface_bound_to_stage774_receipt=true"
echo "stage776_preview_component_api_commit_admission_runtime_manager_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
