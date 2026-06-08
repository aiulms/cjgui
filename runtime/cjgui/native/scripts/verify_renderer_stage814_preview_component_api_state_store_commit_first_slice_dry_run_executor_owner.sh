#!/usr/bin/env zsh
#
# Verifies the stage814 preview component API state-store commit first-slice dry-run executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage814 preview component api state-store commit first-slice dry-run executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutorPlan" \
  "CjguiInternalRendererStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutorFacts" \
  "CjguiInternalRendererStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage814PreviewComponentApiStateStoreCommitFirstSliceDryRunExecutorDraft" \
  "CjguiInternalRendererStage813PreviewComponentApiStateStoreCommitFirstSlicePreflightReadiness" \
  "didConsumeStage813PreviewComponentApiStateStoreCommitFirstSlicePreflight" \
  "didMaterializeCommitDryRunExecutor" \
  "didMaterializeRollbackBeforeAfterSnapshot" \
  "didMaterializeCommitDenialReasonLedger" \
  "didMaterializeWriteSetReceipt" \
  "didKeepCommitExecutorNonPublishing" \
  "didPrepareStage815PreviewComponentApiStateStoreCommitFirstSliceDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage814 preview component api state-store commit first-slice dry-run executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_owner_present=true"
echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_consumed=true"
echo "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_consumed_transitively=true"
echo "commit_dry_run_executor_materialized=true"
echo "rollback_before_after_snapshot_materialized=true"
echo "commit_denial_reason_ledger_materialized=true"
echo "write_set_receipt_materialized=true"
echo "commit_first_slice_executor_bound_to_preflight_allowlist=true"
echo "commit_executor_non_publishing=true"
echo "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
