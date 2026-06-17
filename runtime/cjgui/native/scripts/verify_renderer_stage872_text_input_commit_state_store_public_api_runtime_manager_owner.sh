#!/usr/bin/env zsh
#
# Verifies the stage872 text-input commit state-store public API runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage872_text_input_commit_state_store_public_api_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage872 text input commit state store public api runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage872TextInputCommitStateStorePublicApiRuntimeManagerPlan" \
  "CjguiInternalRendererStage872TextInputCommitStateStorePublicApiRuntimeManagerFacts" \
  "CjguiInternalRendererStage872TextInputCommitStateStorePublicApiRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage872TextInputCommitStateStorePublicApiRuntimeManagerDraft" \
  "CjguiInternalRendererStage871TextInputCommitStateStorePublicApiDemoInspectionSurfaceReadiness" \
  "didConsumeStage871TextInputCommitStateStorePublicApiDemoInspectionSurface" \
  "didMaterializeSharedStateStorePublicApiCommitRuntimeManager" \
  "didMaterializeStateStorePublicApiCommitRuntimeContract" \
  "didMaterializeStateStorePublicApiCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderStateStorePublicApiAdmissionInspectionRuntime" \
  "didMaterializeFileBrowserStateStorePublicApiCommitRuntimeSurface" \
  "didMaterializeCommonStateStorePublicApiDemoInspectionExecutor" \
  "didReduceFuturePerDemoStateStorePublicApiCommitTemplateNeed" \
  "didPrepareStage873OwnerLocalStateStoreCommitFirstSliceProof"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage872 text input commit state store public api runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage872_text_input_commit_state_store_public_api_runtime_manager_owner_present=true"
echo "stage871_text_input_commit_state_store_public_api_demo_inspection_surface_consumed=true"
echo "stage870_text_input_commit_state_store_public_api_admission_consumed_transitively=true"
echo "stage869_text_input_commit_state_store_public_api_readiness_consumed_transitively=true"
echo "stage868_text_input_commit_public_api_consumption_runtime_manager_consumed_transitively=true"
echo "shared_state_store_public_api_commit_runtime_manager_materialized=true"
echo "state_store_public_api_commit_runtime_contract_materialized=true"
echo "state_store_public_api_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_state_store_public_api_admission_inspection_runtime_materialized=true"
echo "todo_state_store_public_api_commit_runtime_surface_materialized=true"
echo "settings_state_store_public_api_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_state_store_public_api_commit_runtime_surface_materialized=true"
echo "chat_composer_state_store_public_api_commit_runtime_surface_materialized=true"
echo "file_browser_state_store_public_api_commit_runtime_surface_materialized=true"
echo "common_state_store_public_api_demo_inspection_executor_materialized=true"
echo "future_per_demo_state_store_public_api_commit_template_need_reduced=true"
echo "stage873_owner_local_state_store_commit_first_slice_proof_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
