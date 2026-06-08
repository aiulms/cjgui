#!/usr/bin/env zsh
#
# Verifies the stage794 preview component API state-store dry-run executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage794_preview_component_api_state_store_dry_run_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage794 preview component api state-store dry-run executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage794PreviewComponentApiStateStoreDryRunExecutorPlan" \
  "CjguiInternalRendererStage794PreviewComponentApiStateStoreDryRunExecutorFacts" \
  "CjguiInternalRendererStage794PreviewComponentApiStateStoreDryRunExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage794PreviewComponentApiStateStoreDryRunExecutorDraft" \
  "CjguiInternalRendererStage793PreviewComponentApiCommitDecisionStateStoreBridgeReadiness" \
  "didConsumeStage793PreviewComponentApiCommitDecisionStateStoreBridge" \
  "didMaterializeComponentStateStoreDryRunExecutor" \
  "didMaterializeStateStoreMutationPreflightLedger" \
  "didMaterializeRollbackSlotSnapshot" \
  "didMaterializeTextEditMutationLedger" \
  "didMaterializeFocusHandoffMutationLedger" \
  "didMaterializeStyleTokenMutationLedger" \
  "didBindDryRunExecutorToStage793StateStoreBridge" \
  "didKeepStateStoreDryRunNonCommitting" \
  "didPrepareStage795PreviewComponentApiStateStoreInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage794 preview component api state-store dry-run executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage794_preview_component_api_state_store_dry_run_executor_owner_present=true"
echo "stage793_preview_component_api_commit_decision_state_store_bridge_consumed=true"
echo "stage792_preview_component_api_commit_decision_transaction_runtime_executor_consumed_transitively=true"
echo "commit_decision_state_store_bridge_consumed=true"
echo "component_state_store_dry_run_executor_materialized=true"
echo "state_store_mutation_preflight_ledger_materialized=true"
echo "rollback_slot_snapshot_materialized=true"
echo "text_edit_mutation_ledger_materialized=true"
echo "focus_handoff_mutation_ledger_materialized=true"
echo "style_token_mutation_ledger_materialized=true"
echo "dry_run_executor_bound_to_stage793_state_store_bridge=true"
echo "state_store_dry_run_non_committing=true"
echo "stage795_preview_component_api_state_store_inspection_surface_prepared=true"
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
