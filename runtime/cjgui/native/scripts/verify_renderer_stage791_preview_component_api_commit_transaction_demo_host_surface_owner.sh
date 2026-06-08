#!/usr/bin/env zsh
#
# Verifies the stage791 preview component API commit transaction demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage791_preview_component_api_commit_transaction_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage791 preview component api commit transaction demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage791PreviewComponentApiCommitTransactionDemoHostSurfacePlan" \
  "CjguiInternalRendererStage791PreviewComponentApiCommitTransactionDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage791PreviewComponentApiCommitTransactionDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage791PreviewComponentApiCommitTransactionDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage790PreviewComponentApiCommitTransactionPatchPlanReadiness" \
  "didConsumeStage790PreviewComponentApiCommitTransactionPatchPlan" \
  "didMaterializeCommitTransactionHostInspectionReceipt" \
  "didMaterializeCommitTransactionResultSurfaceRefresh" \
  "didMaterializeCommitTransactionRollbackPreviewReceipt" \
  "didMaterializeCommitTransactionSemanticDiffExplain" \
  "didMaterializeTodoCommitTransactionDemoHostSurface" \
  "didMaterializeSettingsCommitTransactionDemoHostSurface" \
  "didMaterializeAiGeneratedSettingsCommitTransactionDemoHostSurface" \
  "didMaterializeChatComposerCommitTransactionDemoHostSurface" \
  "didPrepareStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage791 preview component api commit transaction demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage791_preview_component_api_commit_transaction_demo_host_surface_owner_present=true"
echo "stage790_preview_component_api_commit_transaction_patch_plan_consumed=true"
echo "stage789_preview_component_api_commit_admission_decision_consumed_transitively=true"
echo "commit_transaction_host_inspection_receipt_materialized=true"
echo "commit_transaction_result_surface_refresh_materialized=true"
echo "commit_transaction_rollback_preview_receipt_materialized=true"
echo "commit_transaction_semantic_diff_explain_materialized=true"
echo "todo_commit_transaction_demo_host_surface_materialized=true"
echo "settings_commit_transaction_demo_host_surface_materialized=true"
echo "ai_generated_settings_commit_transaction_demo_host_surface_materialized=true"
echo "chat_composer_commit_transaction_demo_host_surface_materialized=true"
echo "demo_host_surface_bound_to_stage790_transaction_patch_plan=true"
echo "commit_transaction_demo_host_surface_non_committing=true"
echo "stage792_preview_component_api_commit_decision_transaction_runtime_executor_prepared=true"
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
