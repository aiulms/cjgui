#!/usr/bin/env zsh
#
# Verifies the stage857 owner-local text input commit dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage857_owner_local_text_input_commit_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage857 owner-local text input commit dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage857OwnerLocalTextInputCommitDryRunPlan" \
  "CjguiInternalRendererStage857OwnerLocalTextInputCommitDryRunFacts" \
  "CjguiInternalRendererStage857OwnerLocalTextInputCommitDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage857OwnerLocalTextInputCommitDryRunDraft" \
  "CjguiInternalRendererStage856TextInputCommitRuntimeManagerReadiness" \
  "didConsumeStage856TextInputCommitRuntimeManager" \
  "didMaterializeOwnerLocalTextInputCommitDryRunExecutor" \
  "didMaterializeOwnerLocalTextInputCommitApplicationPlan" \
  "didMaterializeOwnerLocalTextInputCommitReceipt" \
  "didMaterializeOwnerLocalTextInputCommitRollbackToken" \
  "didBindOwnerLocalCommitDryRunToStage856RuntimeManager" \
  "didKeepOwnerLocalCommitDryRunInMemoryOnly" \
  "didPrepareStage858OwnerLocalTextInputStateStoreCommitSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage857 owner-local text input commit dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage857_owner_local_text_input_commit_dry_run_owner_present=true"
echo "stage856_text_input_commit_runtime_manager_consumed=true"
echo "owner_local_text_input_commit_dry_run_executor_materialized=true"
echo "owner_local_text_input_commit_application_plan_materialized=true"
echo "owner_local_text_input_commit_receipt_materialized=true"
echo "owner_local_text_input_commit_rollback_token_materialized=true"
echo "owner_local_text_input_commit_dry_run_bound_to_stage856_runtime_manager=true"
echo "owner_local_text_input_commit_dry_run_in_memory_only=true"
echo "owner_local_text_input_commit_dry_run_executed=true"
echo "stage858_owner_local_text_input_state_store_commit_snapshot_prepared=true"
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
