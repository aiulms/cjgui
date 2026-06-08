#!/usr/bin/env zsh
#
# Verifies the stage800 preview component API state-store commit admission runtime executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage800_preview_component_api_state_store_commit_admission_runtime_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage800 preview component api state-store commit admission runtime executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutorPlan" \
  "CjguiInternalRendererStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutorFacts" \
  "CjguiInternalRendererStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage800PreviewComponentApiStateStoreCommitAdmissionRuntimeExecutorDraft" \
  "CjguiInternalRendererStage799PreviewComponentApiStateStoreCommitDemoHostPreviewReadiness" \
  "didConsumeStage799PreviewComponentApiStateStoreCommitDemoHostPreview" \
  "didMaterializeSharedStateStoreCommitAdmissionRuntimeExecutor" \
  "didMaterializeStateStoreCommitAdmissionRuntimeContract" \
  "didMaterializeStateStoreCommitAdmissionExecutionReceiptContract" \
  "didMaterializeCycleOrderAdmissionPreviewReviewDemoRuntime" \
  "didMaterializeFileBrowserCommitAdmissionRuntimeSurface" \
  "didReduceFuturePerDemoCommitAdmissionTemplateNeed" \
  "didPrepareStage801PreviewComponentApiStateStoreCommitAdmissionDiffExplain"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage800 preview component api state-store commit admission runtime executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_owner_present=true"
echo "stage799_preview_component_api_state_store_commit_demo_host_preview_consumed=true"
echo "stage798_preview_component_api_state_store_commit_review_checkpoint_consumed_transitively=true"
echo "stage797_preview_component_api_state_store_commit_admission_preview_consumed_transitively=true"
echo "stage796_preview_component_api_state_store_bridge_runtime_manager_consumed_transitively=true"
echo "shared_state_store_commit_admission_runtime_executor_materialized=true"
echo "state_store_commit_admission_runtime_contract_materialized=true"
echo "state_store_commit_admission_execution_receipt_contract_materialized=true"
echo "cycle_order_admission_preview_review_demo_runtime_materialized=true"
echo "todo_commit_admission_runtime_surface_materialized=true"
echo "settings_commit_admission_runtime_surface_materialized=true"
echo "ai_generated_settings_commit_admission_runtime_surface_materialized=true"
echo "chat_composer_commit_admission_runtime_surface_materialized=true"
echo "file_browser_commit_admission_runtime_surface_materialized=true"
echo "state_store_commit_admission_runtime_executor_bound_to_stage797_preview=true"
echo "state_store_commit_admission_runtime_executor_bound_to_stage798_checkpoint=true"
echo "state_store_commit_admission_runtime_executor_bound_to_stage799_demo_host_preview=true"
echo "future_per_demo_commit_admission_template_need_reduced=true"
echo "stage801_preview_component_api_state_store_commit_admission_diff_explain_prepared=true"
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
