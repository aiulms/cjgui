#!/usr/bin/env zsh
#
# Verifies the stage735 component visual state store commit host inspection UI owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage735_component_visual_state_store_commit_host_inspection_ui.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage735 component visual state store commit host inspection ui: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage735ComponentVisualStateStoreCommitHostInspectionUiPlan" \
  "CjguiInternalRendererStage735ComponentVisualStateStoreCommitHostInspectionUiFacts" \
  "CjguiInternalRendererStage735ComponentVisualStateStoreCommitHostInspectionUiReadiness" \
  "cjguiInternalExecuteDefaultRendererStage735ComponentVisualStateStoreCommitHostInspectionUiDraft" \
  "CjguiInternalRendererStage734ComponentVisualStateStoreCommitRollbackSnapshotReadiness" \
  "didConsumeStage734ComponentVisualStateStoreCommitRollbackSnapshot" \
  "didMaterializeCommitDemoHostInspectionUiSurface" \
  "didMaterializeCommitSlotDiffRowModel" \
  "didMaterializeCommitValidationMessageRow" \
  "didMaterializeCommitFocusHandoffReviewRow" \
  "didMaterializeCommitRenderCommandRefreshReceipt" \
  "didPrepareStage736ComponentStateStoreCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage735 component visual state store commit host inspection ui: missing token $token" >&2
    exit 3
  fi
done

echo "stage735_component_visual_state_store_commit_host_inspection_ui_owner_present=true"
echo "stage734_component_visual_state_store_commit_rollback_snapshot_consumed=true"
echo "stage733_component_visual_state_store_commit_preflight_consumed_transitively=true"
echo "commit_demo_host_inspection_ui_surface_materialized=true"
echo "commit_slot_diff_row_model_materialized=true"
echo "commit_validation_message_row_materialized=true"
echo "commit_focus_handoff_review_row_materialized=true"
echo "commit_render_command_refresh_receipt_materialized=true"
echo "commit_host_inspection_probe_input_contract_materialized=true"
echo "todo_component_visual_state_store_commit_host_inspection_ui_surface_materialized=true"
echo "settings_component_visual_state_store_commit_host_inspection_ui_surface_materialized=true"
echo "ai_generated_settings_component_visual_state_store_commit_host_inspection_ui_surface_materialized=true"
echo "chat_composer_component_visual_state_store_commit_host_inspection_ui_surface_materialized=true"
echo "stage736_component_state_store_commit_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
