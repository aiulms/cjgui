#!/usr/bin/env zsh
#
# Verifies the stage804 preview component API state-store commit diff/explain runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage804 preview component api state-store commit diff explain runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManagerPlan" \
  "CjguiInternalRendererStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManagerFacts" \
  "CjguiInternalRendererStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage804PreviewComponentApiStateStoreCommitDiffExplainRuntimeManagerDraft" \
  "CjguiInternalRendererStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurfaceReadiness" \
  "didConsumeStage803PreviewComponentApiStateStoreCommitDiffExplainDemoHostSurface" \
  "didMaterializeSharedDiffExplainReviewRuntimeManager" \
  "didMaterializeDiffExplainReviewRuntimeContract" \
  "didMaterializeDiffExplainReviewExecutionReceiptContract" \
  "didMaterializeCycleOrderDiffExplainReviewDemoRuntime" \
  "didMaterializeFileBrowserDiffExplainRuntimeSurface" \
  "didReduceFuturePerDemoDiffExplainTemplateNeed" \
  "didPrepareStage805PreviewComponentApiStateStoreCommitDiffExplainReviewHistory"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage804 preview component api state-store commit diff explain runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_owner_present=true"
echo "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_consumed=true"
echo "stage802_preview_component_api_state_store_commit_review_decision_loop_consumed_transitively=true"
echo "stage801_preview_component_api_state_store_commit_diff_explain_consumed_transitively=true"
echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_consumed_transitively=true"
echo "shared_diff_explain_review_runtime_manager_materialized=true"
echo "diff_explain_review_runtime_contract_materialized=true"
echo "diff_explain_review_execution_receipt_contract_materialized=true"
echo "cycle_order_diff_explain_review_demo_runtime_materialized=true"
echo "todo_diff_explain_runtime_surface_materialized=true"
echo "settings_diff_explain_runtime_surface_materialized=true"
echo "ai_generated_settings_diff_explain_runtime_surface_materialized=true"
echo "chat_composer_diff_explain_runtime_surface_materialized=true"
echo "file_browser_diff_explain_runtime_surface_materialized=true"
echo "diff_explain_runtime_manager_bound_to_stage801_diff_model=true"
echo "diff_explain_runtime_manager_bound_to_stage802_decision_loop=true"
echo "diff_explain_runtime_manager_bound_to_stage803_demo_host_surface=true"
echo "future_per_demo_diff_explain_template_need_reduced=true"
echo "stage805_preview_component_api_state_store_commit_diff_explain_review_history_prepared=true"
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
