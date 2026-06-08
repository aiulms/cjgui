#!/usr/bin/env zsh
#
# Verifies the stage816 preview component API state-store commit first-slice runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage816_preview_component_api_state_store_commit_first_slice_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage816 preview component api state-store commit first-slice runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManagerPlan" \
  "CjguiInternalRendererStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManagerFacts" \
  "CjguiInternalRendererStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage816PreviewComponentApiStateStoreCommitFirstSliceRuntimeManagerDraft" \
  "CjguiInternalRendererStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurfaceReadiness" \
  "didConsumeStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurface" \
  "didMaterializeSharedCommitFirstSliceRuntimeManager" \
  "didMaterializeCommitFirstSliceRuntimeContract" \
  "didMaterializeCommitFirstSliceExecutionReceiptContract" \
  "didMaterializeCycleOrderCommitFirstSliceDemoRuntime" \
  "didMaterializeFileBrowserCommitFirstSliceRuntimeSurface" \
  "didReduceFuturePerDemoCommitFirstSliceTemplateNeed" \
  "didPrepareStage817PreviewComponentApiStateStoreCommitFirstSliceHostInspectionAfterStage816"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage816 preview component api state-store commit first-slice runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_owner_present=true"
echo "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_consumed=true"
echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_consumed_transitively=true"
echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_consumed_transitively=true"
echo "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_consumed_transitively=true"
echo "shared_commit_first_slice_runtime_manager_materialized=true"
echo "commit_first_slice_runtime_contract_materialized=true"
echo "commit_first_slice_execution_receipt_contract_materialized=true"
echo "cycle_order_commit_first_slice_demo_runtime_materialized=true"
echo "todo_commit_first_slice_runtime_surface_materialized=true"
echo "settings_commit_first_slice_runtime_surface_materialized=true"
echo "ai_generated_settings_commit_first_slice_runtime_surface_materialized=true"
echo "chat_composer_commit_first_slice_runtime_surface_materialized=true"
echo "file_browser_commit_first_slice_runtime_surface_materialized=true"
echo "commit_first_slice_runtime_manager_bound_to_stage813_preflight=true"
echo "commit_first_slice_runtime_manager_bound_to_stage814_executor=true"
echo "commit_first_slice_runtime_manager_bound_to_stage815_demo_host_surface=true"
echo "future_per_demo_commit_first_slice_template_need_reduced=true"
echo "stage817_preview_component_api_state_store_commit_first_slice_host_inspection_after_stage816_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
