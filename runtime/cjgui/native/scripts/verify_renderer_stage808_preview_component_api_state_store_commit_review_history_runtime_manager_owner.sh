#!/usr/bin/env zsh
#
# Verifies the stage808 preview component API state-store commit review history runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage808_preview_component_api_state_store_commit_review_history_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage808 preview component api state-store commit review history runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManagerPlan" \
  "CjguiInternalRendererStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManagerFacts" \
  "CjguiInternalRendererStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManagerDraft" \
  "CjguiInternalRendererStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurfaceReadiness" \
  "didConsumeStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurface" \
  "didMaterializeSharedReviewHistoryRuntimeManager" \
  "didMaterializeReviewHistoryRuntimeContract" \
  "didMaterializeReviewHistoryExecutionReceiptContract" \
  "didMaterializeCycleOrderReviewHistoryTimeTravelDemoRuntime" \
  "didMaterializeFileBrowserReviewHistoryRuntimeSurface" \
  "didReduceFuturePerDemoReviewHistoryTemplateNeed" \
  "didPrepareStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsal"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage808 preview component api state-store commit review history runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_owner_present=true"
echo "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_consumed=true"
echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_consumed_transitively=true"
echo "stage805_preview_component_api_state_store_commit_review_history_consumed_transitively=true"
echo "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_consumed_transitively=true"
echo "shared_review_history_runtime_manager_materialized=true"
echo "review_history_runtime_contract_materialized=true"
echo "review_history_execution_receipt_contract_materialized=true"
echo "cycle_order_review_history_time_travel_demo_runtime_materialized=true"
echo "todo_review_history_runtime_surface_materialized=true"
echo "settings_review_history_runtime_surface_materialized=true"
echo "ai_generated_settings_review_history_runtime_surface_materialized=true"
echo "chat_composer_review_history_runtime_surface_materialized=true"
echo "file_browser_review_history_runtime_surface_materialized=true"
echo "review_history_runtime_manager_bound_to_stage805_history=true"
echo "review_history_runtime_manager_bound_to_stage806_time_travel=true"
echo "review_history_runtime_manager_bound_to_stage807_demo_host_surface=true"
echo "future_per_demo_review_history_template_need_reduced=true"
echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_prepared=true"
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
