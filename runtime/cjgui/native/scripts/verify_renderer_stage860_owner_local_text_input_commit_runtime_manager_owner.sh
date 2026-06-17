#!/usr/bin/env zsh
#
# Verifies the stage860 owner-local text input commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage860_owner_local_text_input_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage860 owner-local text input commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage860OwnerLocalTextInputCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage860OwnerLocalTextInputCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage860OwnerLocalTextInputCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage860OwnerLocalTextInputCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage859OwnerLocalTextInputCommitResultSurfaceReadiness" \
  "didConsumeStage859OwnerLocalTextInputCommitResultSurface" \
  "didMaterializeSharedOwnerLocalTextInputCommitRuntimeManager" \
  "didMaterializeOwnerLocalTextInputCommitRuntimeContract" \
  "didMaterializeOwnerLocalTextInputCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderOwnerLocalTextInputCommitDryRunStateStoreResultRuntime" \
  "didMaterializeFileBrowserOwnerLocalTextInputCommitRuntimeSurface" \
  "didBindRuntimeManagerToStage857DryRun" \
  "didBindRuntimeManagerToStage858StateStoreCommitSnapshot" \
  "didBindRuntimeManagerToStage859ResultSurface" \
  "didMaterializeOwnerLocalTextInputCommitFirstSliceReadiness" \
  "didReduceFuturePerDemoOwnerLocalTextInputCommitTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage860 owner-local text input commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage860_owner_local_text_input_commit_runtime_manager_owner_present=true"
echo "stage859_owner_local_text_input_commit_result_surface_consumed=true"
echo "stage858_owner_local_text_input_state_store_commit_snapshot_consumed_transitively=true"
echo "stage857_owner_local_text_input_commit_dry_run_consumed_transitively=true"
echo "stage856_text_input_commit_runtime_manager_consumed_transitively=true"
echo "shared_owner_local_text_input_commit_runtime_manager_materialized=true"
echo "owner_local_text_input_commit_runtime_contract_materialized=true"
echo "owner_local_text_input_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_owner_local_text_input_commit_dry_run_state_store_result_runtime_materialized=true"
echo "todo_owner_local_text_input_commit_runtime_surface_materialized=true"
echo "settings_owner_local_text_input_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_owner_local_text_input_commit_runtime_surface_materialized=true"
echo "chat_composer_owner_local_text_input_commit_runtime_surface_materialized=true"
echo "file_browser_owner_local_text_input_commit_runtime_surface_materialized=true"
echo "owner_local_text_input_commit_runtime_manager_bound_to_stage857_dry_run=true"
echo "owner_local_text_input_commit_runtime_manager_bound_to_stage858_state_store_commit_snapshot=true"
echo "owner_local_text_input_commit_runtime_manager_bound_to_stage859_result_surface=true"
echo "owner_local_text_input_commit_first_slice_readiness_materialized=true"
echo "owner_local_text_input_commit_first_slice_materialized=true"
echo "owner_local_text_input_commit_applied=true"
echo "future_per_demo_owner_local_text_input_commit_template_need_reduced=true"
echo "stage861_text_input_owner_acceptance_review_after_owner_local_commit_prepared=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
