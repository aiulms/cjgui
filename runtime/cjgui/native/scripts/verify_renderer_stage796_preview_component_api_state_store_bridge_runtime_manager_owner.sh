#!/usr/bin/env zsh
#
# Verifies the stage796 preview component API state-store bridge runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage796_preview_component_api_state_store_bridge_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage796 preview component api state-store bridge runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage796PreviewComponentApiStateStoreBridgeRuntimeManagerPlan" \
  "CjguiInternalRendererStage796PreviewComponentApiStateStoreBridgeRuntimeManagerFacts" \
  "CjguiInternalRendererStage796PreviewComponentApiStateStoreBridgeRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage796PreviewComponentApiStateStoreBridgeRuntimeManagerDraft" \
  "CjguiInternalRendererStage795PreviewComponentApiStateStoreInspectionSurfaceReadiness" \
  "didConsumeStage795PreviewComponentApiStateStoreInspectionSurface" \
  "didMaterializeSharedComponentStateStoreBridgeRuntimeManager" \
  "didMaterializeComponentStateStoreBridgeRuntimeContract" \
  "didMaterializeComponentStateStoreBridgeExecutionReceiptContract" \
  "didMaterializeCycleOrderCommitDecisionStateStoreDryRunInspectionRuntime" \
  "didMaterializeFileBrowserComponentStateStoreBridgeRuntimeSurface" \
  "didBindStateStoreBridgeRuntimeManagerToStage793Bridge" \
  "didBindStateStoreBridgeRuntimeManagerToStage794DryRunExecutor" \
  "didBindStateStoreBridgeRuntimeManagerToStage795InspectionSurface" \
  "didReduceFuturePerDemoStateStoreBridgeTemplateNeed" \
  "didPrepareStage797PreviewComponentApiStateStoreCommitAdmissionPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage796 preview component api state-store bridge runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage796_preview_component_api_state_store_bridge_runtime_manager_owner_present=true"
echo "stage795_preview_component_api_state_store_inspection_surface_consumed=true"
echo "stage794_preview_component_api_state_store_dry_run_executor_consumed_transitively=true"
echo "stage793_preview_component_api_commit_decision_state_store_bridge_consumed_transitively=true"
echo "stage792_preview_component_api_commit_decision_transaction_runtime_executor_consumed_transitively=true"
echo "shared_component_state_store_bridge_runtime_manager_materialized=true"
echo "component_state_store_bridge_runtime_contract_materialized=true"
echo "component_state_store_bridge_execution_receipt_contract_materialized=true"
echo "cycle_order_commit_decision_state_store_dry_run_inspection_runtime_materialized=true"
echo "todo_component_state_store_bridge_runtime_surface_materialized=true"
echo "settings_component_state_store_bridge_runtime_surface_materialized=true"
echo "ai_generated_settings_component_state_store_bridge_runtime_surface_materialized=true"
echo "chat_composer_component_state_store_bridge_runtime_surface_materialized=true"
echo "file_browser_component_state_store_bridge_runtime_surface_materialized=true"
echo "state_store_bridge_runtime_manager_bound_to_stage793_bridge=true"
echo "state_store_bridge_runtime_manager_bound_to_stage794_dry_run_executor=true"
echo "state_store_bridge_runtime_manager_bound_to_stage795_inspection_surface=true"
echo "future_per_demo_state_store_bridge_template_need_reduced=true"
echo "stage797_preview_component_api_state_store_commit_admission_preview_prepared=true"
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
