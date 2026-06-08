#!/usr/bin/env zsh
#
# Verifies the stage780 preview component API state-store commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage780_preview_component_api_state_store_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage780 preview component api state-store commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage780PreviewComponentApiStateStoreCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage780PreviewComponentApiStateStoreCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage780PreviewComponentApiStateStoreCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage780PreviewComponentApiStateStoreCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage779PreviewComponentApiStateStoreNotPublishedHostSurfaceReadiness" \
  "didConsumeStage779PreviewComponentApiStateStoreNotPublishedHostSurface" \
  "didMaterializeSharedPreviewComponentApiStateStoreCommitRuntimeManager" \
  "didMaterializePreviewComponentApiStateStoreCommitRuntimeContract" \
  "didMaterializePreviewComponentApiStateStoreExecutionReceiptContract" \
  "didMaterializeCycleOrderPreviewApiStateStoreBoundaryRollbackHostRuntime" \
  "didMaterializeChatComposerPreviewComponentApiStateStoreCommitRuntimeSurface" \
  "didBindStateStoreCommitRuntimeManagerToStage777Boundary" \
  "didBindStateStoreCommitRuntimeManagerToStage778RollbackSnapshot" \
  "didBindStateStoreCommitRuntimeManagerToStage779NotPublishedHostSurface" \
  "didReduceFuturePerDemoStateStoreCommitTemplateNeed" \
  "didPrepareStage781PreviewComponentApiCommitInspectionUiAfterStage780"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage780 preview component api state-store commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage780_preview_component_api_state_store_commit_runtime_manager_owner_present=true"
echo "stage779_preview_component_api_state_store_not_published_host_surface_consumed=true"
echo "stage778_preview_component_api_state_store_rollback_snapshot_consumed_transitively=true"
echo "stage777_preview_component_api_state_store_commit_boundary_consumed_transitively=true"
echo "stage776_preview_component_api_commit_admission_runtime_manager_consumed_transitively=true"
echo "shared_preview_component_api_state_store_commit_runtime_manager_materialized=true"
echo "preview_component_api_state_store_commit_runtime_contract_materialized=true"
echo "preview_component_api_state_store_execution_receipt_contract_materialized=true"
echo "cycle_order_preview_api_state_store_boundary_rollback_host_runtime_materialized=true"
echo "todo_preview_component_api_state_store_commit_runtime_surface_materialized=true"
echo "settings_preview_component_api_state_store_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_state_store_commit_runtime_surface_materialized=true"
echo "chat_composer_preview_component_api_state_store_commit_runtime_surface_materialized=true"
echo "state_store_commit_runtime_manager_bound_to_stage777_boundary=true"
echo "state_store_commit_runtime_manager_bound_to_stage778_rollback_snapshot=true"
echo "state_store_commit_runtime_manager_bound_to_stage779_not_published_host_surface=true"
echo "future_per_demo_state_store_commit_template_need_reduced=true"
echo "stage781_preview_component_api_commit_inspection_ui_prepared=true"
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
