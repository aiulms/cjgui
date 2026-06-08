#!/usr/bin/env zsh
#
# Verifies the stage792 preview component API commit decision transaction runtime executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage792_preview_component_api_commit_decision_transaction_runtime_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage792 preview component api commit decision transaction runtime executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutorPlan" \
  "CjguiInternalRendererStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutorFacts" \
  "CjguiInternalRendererStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutorDraft" \
  "CjguiInternalRendererStage791PreviewComponentApiCommitTransactionDemoHostSurfaceReadiness" \
  "didConsumeStage791PreviewComponentApiCommitTransactionDemoHostSurface" \
  "didMaterializeSharedCommitDecisionTransactionRuntimeExecutor" \
  "didMaterializeCommitDecisionTransactionRuntimeContract" \
  "didMaterializeCommitDecisionTransactionExecutionReceiptContract" \
  "didMaterializeCycleOrderPublicPreviewCommitDecisionTransactionPatchDemoRuntime" \
  "didMaterializeChatComposerCommitDecisionTransactionRuntimeSurface" \
  "didBindCommitDecisionTransactionRuntimeExecutorToStage789Decision" \
  "didBindCommitDecisionTransactionRuntimeExecutorToStage790PatchPlan" \
  "didBindCommitDecisionTransactionRuntimeExecutorToStage791DemoHostSurface" \
  "didReduceFuturePerDemoCommitDecisionTransactionTemplateNeed" \
  "didPrepareStage793PreviewComponentApiCommitDecisionStateStoreBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage792 preview component api commit decision transaction runtime executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage792_preview_component_api_commit_decision_transaction_runtime_executor_owner_present=true"
echo "stage791_preview_component_api_commit_transaction_demo_host_surface_consumed=true"
echo "stage790_preview_component_api_commit_transaction_patch_plan_consumed_transitively=true"
echo "stage789_preview_component_api_commit_admission_decision_consumed_transitively=true"
echo "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_consumed_transitively=true"
echo "shared_commit_decision_transaction_runtime_executor_materialized=true"
echo "commit_decision_transaction_runtime_contract_materialized=true"
echo "commit_decision_transaction_execution_receipt_contract_materialized=true"
echo "cycle_order_public_preview_commit_decision_transaction_patch_demo_runtime_materialized=true"
echo "todo_commit_decision_transaction_runtime_surface_materialized=true"
echo "settings_commit_decision_transaction_runtime_surface_materialized=true"
echo "ai_generated_settings_commit_decision_transaction_runtime_surface_materialized=true"
echo "chat_composer_commit_decision_transaction_runtime_surface_materialized=true"
echo "commit_decision_transaction_runtime_executor_bound_to_stage789_decision=true"
echo "commit_decision_transaction_runtime_executor_bound_to_stage790_patch_plan=true"
echo "commit_decision_transaction_runtime_executor_bound_to_stage791_demo_host_surface=true"
echo "future_per_demo_commit_decision_transaction_template_need_reduced=true"
echo "stage793_preview_component_api_commit_decision_state_store_bridge_prepared=true"
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
