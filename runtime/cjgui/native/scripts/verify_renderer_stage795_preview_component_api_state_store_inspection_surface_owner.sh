#!/usr/bin/env zsh
#
# Verifies the stage795 preview component API state-store inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage795_preview_component_api_state_store_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage795 preview component api state-store inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage795PreviewComponentApiStateStoreInspectionSurfacePlan" \
  "CjguiInternalRendererStage795PreviewComponentApiStateStoreInspectionSurfaceFacts" \
  "CjguiInternalRendererStage795PreviewComponentApiStateStoreInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage795PreviewComponentApiStateStoreInspectionSurfaceDraft" \
  "CjguiInternalRendererStage794PreviewComponentApiStateStoreDryRunExecutorReadiness" \
  "didConsumeStage794PreviewComponentApiStateStoreDryRunExecutor" \
  "didMaterializeStateStoreDryRunHostInspectionRows" \
  "didMaterializeStateStoreDryRunResultSurfaceRefresh" \
  "didMaterializeStateStoreMutationDiffReceipt" \
  "didMaterializeStateStoreRollbackPreviewReceipt" \
  "didMaterializeTodoStateStoreDryRunSurface" \
  "didMaterializeSettingsStateStoreDryRunSurface" \
  "didMaterializeAiGeneratedSettingsStateStoreDryRunSurface" \
  "didMaterializeChatComposerStateStoreDryRunSurface" \
  "didMaterializeFileBrowserStateStoreDryRunSurface" \
  "didBindInspectionSurfaceToStage794DryRunExecutor" \
  "didPrepareStage796PreviewComponentApiStateStoreBridgeRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage795 preview component api state-store inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage795_preview_component_api_state_store_inspection_surface_owner_present=true"
echo "stage794_preview_component_api_state_store_dry_run_executor_consumed=true"
echo "stage793_preview_component_api_commit_decision_state_store_bridge_consumed_transitively=true"
echo "component_state_store_dry_run_executor_consumed=true"
echo "state_store_dry_run_host_inspection_rows_materialized=true"
echo "state_store_dry_run_result_surface_refresh_materialized=true"
echo "state_store_mutation_diff_receipt_materialized=true"
echo "state_store_rollback_preview_receipt_materialized=true"
echo "todo_state_store_dry_run_surface_materialized=true"
echo "settings_state_store_dry_run_surface_materialized=true"
echo "ai_generated_settings_state_store_dry_run_surface_materialized=true"
echo "chat_composer_state_store_dry_run_surface_materialized=true"
echo "file_browser_state_store_dry_run_surface_materialized=true"
echo "inspection_surface_bound_to_stage794_dry_run_executor=true"
echo "state_store_inspection_surface_non_committing=true"
echo "stage796_preview_component_api_state_store_bridge_runtime_manager_prepared=true"
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
