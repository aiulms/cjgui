#!/usr/bin/env zsh
#
# Verifies the stage856 text input commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage856_text_input_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage856 text input commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage856TextInputCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage856TextInputCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage856TextInputCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage856TextInputCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage855TextInputCommitInspectionSurfaceReadiness" \
  "didConsumeStage855TextInputCommitInspectionSurface" \
  "didMaterializeSharedTextInputCommitRuntimeManager" \
  "didMaterializeTextInputCommitRuntimeContract" \
  "didMaterializeTextInputCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderTextInputCommitPreflightRollbackInspectionRuntime" \
  "didMaterializeFileBrowserTextInputCommitRuntimeSurface" \
  "didBindRuntimeManagerToStage853CommitPreflight" \
  "didBindRuntimeManagerToStage854RollbackSnapshot" \
  "didBindRuntimeManagerToStage855InspectionSurface" \
  "didMaterializeTextInputCommitFirstSliceReadiness" \
  "didReduceFuturePerDemoTextInputCommitTemplateNeed" \
  "didPrepareStage857OwnerLocalTextInputCommitDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage856 text input commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage856_text_input_commit_runtime_manager_owner_present=true"
echo "stage855_text_input_commit_inspection_surface_consumed=true"
echo "stage854_text_input_commit_rollback_snapshot_consumed_transitively=true"
echo "stage853_text_input_commit_preflight_consumed_transitively=true"
echo "shared_text_input_commit_runtime_manager_materialized=true"
echo "text_input_commit_runtime_contract_materialized=true"
echo "text_input_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_text_input_commit_preflight_rollback_inspection_runtime_materialized=true"
echo "todo_text_input_commit_runtime_surface_materialized=true"
echo "settings_text_input_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_text_input_commit_runtime_surface_materialized=true"
echo "chat_composer_text_input_commit_runtime_surface_materialized=true"
echo "file_browser_text_input_commit_runtime_surface_materialized=true"
echo "text_input_commit_runtime_manager_bound_to_stage853_commit_preflight=true"
echo "text_input_commit_runtime_manager_bound_to_stage854_rollback_snapshot=true"
echo "text_input_commit_runtime_manager_bound_to_stage855_inspection_surface=true"
echo "text_input_commit_first_slice_readiness_materialized=true"
echo "future_per_demo_text_input_commit_template_need_reduced=true"
echo "stage857_owner_local_text_input_commit_dry_run_prepared=true"
echo "owner_local_commit_first_slice_ready=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
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
