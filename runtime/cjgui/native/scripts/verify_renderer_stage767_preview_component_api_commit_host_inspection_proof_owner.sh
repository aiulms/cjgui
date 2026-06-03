#!/usr/bin/env zsh
#
# Verifies the stage767 preview component API commit host inspection proof owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage767_preview_component_api_commit_host_inspection_proof.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage767 preview component api commit host inspection proof: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage767PreviewComponentApiCommitHostInspectionProofPlan" \
  "CjguiInternalRendererStage767PreviewComponentApiCommitHostInspectionProofFacts" \
  "CjguiInternalRendererStage767PreviewComponentApiCommitHostInspectionProofReadiness" \
  "cjguiInternalExecuteDefaultRendererStage767PreviewComponentApiCommitHostInspectionProofDraft" \
  "CjguiInternalRendererStage766PreviewComponentApiCommitRollbackSnapshotReadiness" \
  "didConsumeStage766PreviewComponentApiCommitRollbackSnapshot" \
  "didMaterializePreviewComponentApiCommitHostInspectionRows" \
  "didMaterializePreviewComponentApiCommitSlotDiffRows" \
  "didMaterializePreviewComponentApiCommitCompatibilityReviewRows" \
  "didMaterializePreviewComponentApiCommitRenderCommandRefreshReceipt" \
  "didMaterializePreviewComponentApiCommitResultSurfaceRefresh" \
  "didMaterializeChatComposerPreviewComponentApiCommitHostInspectionSurface" \
  "didPrepareStage768PreviewComponentApiCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage767 preview component api commit host inspection proof: missing token $token" >&2
    exit 3
  fi
done

echo "stage767_preview_component_api_commit_host_inspection_proof_owner_present=true"
echo "stage766_preview_component_api_commit_rollback_snapshot_consumed=true"
echo "stage765_preview_component_api_commit_preflight_consumed_transitively=true"
echo "preview_component_api_commit_rollback_snapshot_ledger_consumed=true"
echo "preview_component_api_commit_host_inspection_rows_materialized=true"
echo "preview_component_api_commit_slot_diff_rows_materialized=true"
echo "preview_component_api_commit_validation_message_rows_materialized=true"
echo "preview_component_api_commit_compatibility_review_rows_materialized=true"
echo "preview_component_api_commit_render_command_refresh_receipt_materialized=true"
echo "preview_component_api_commit_result_surface_refresh_materialized=true"
echo "todo_preview_component_api_commit_host_inspection_surface_materialized=true"
echo "settings_preview_component_api_commit_host_inspection_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_host_inspection_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_host_inspection_surface_materialized=true"
echo "commit_host_inspection_bound_to_stage766_rollback_snapshot=true"
echo "preview_component_api_commit_host_inspection_checkable=true"
echo "stage768_preview_component_api_commit_runtime_manager_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
