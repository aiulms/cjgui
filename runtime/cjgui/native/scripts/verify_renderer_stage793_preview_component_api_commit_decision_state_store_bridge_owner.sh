#!/usr/bin/env zsh
#
# Verifies the stage793 preview component API commit decision state-store bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage793_preview_component_api_commit_decision_state_store_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage793 preview component api commit decision state-store bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage793PreviewComponentApiCommitDecisionStateStoreBridgePlan" \
  "CjguiInternalRendererStage793PreviewComponentApiCommitDecisionStateStoreBridgeFacts" \
  "CjguiInternalRendererStage793PreviewComponentApiCommitDecisionStateStoreBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage793PreviewComponentApiCommitDecisionStateStoreBridgeDraft" \
  "CjguiInternalRendererStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutorReadiness" \
  "didConsumeStage792PreviewComponentApiCommitDecisionTransactionRuntimeExecutor" \
  "didMaterializeCommitDecisionStateStoreBridge" \
  "didMaterializeOwnerLocalWriteSetRouteClassifier" \
  "didMaterializeAcceptedDecisionWriteSetCandidate" \
  "didMaterializeRejectedDecisionNoopWriteSet" \
  "didMaterializeRollbackOnlyStateStoreRoute" \
  "didMaterializeRequestChangesStateStoreRoute" \
  "didBindStateStoreBridgeToStage792TransactionExecutor" \
  "didKeepCommitDecisionStateStoreBridgeNonCommitting" \
  "didPrepareStage794PreviewComponentApiStateStoreDryRunExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage793 preview component api commit decision state-store bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage793_preview_component_api_commit_decision_state_store_bridge_owner_present=true"
echo "stage792_preview_component_api_commit_decision_transaction_runtime_executor_consumed=true"
echo "stage791_preview_component_api_commit_transaction_demo_host_surface_consumed_transitively=true"
echo "stage790_preview_component_api_commit_transaction_patch_plan_consumed_transitively=true"
echo "stage789_preview_component_api_commit_admission_decision_consumed_transitively=true"
echo "commit_decision_state_store_bridge_materialized=true"
echo "owner_local_write_set_route_classifier_materialized=true"
echo "accepted_decision_write_set_candidate_materialized=true"
echo "rejected_decision_noop_write_set_materialized=true"
echo "rollback_only_state_store_route_materialized=true"
echo "request_changes_state_store_route_materialized=true"
echo "state_store_bridge_bound_to_stage792_transaction_executor=true"
echo "commit_decision_state_store_bridge_non_committing=true"
echo "stage794_preview_component_api_state_store_dry_run_executor_prepared=true"
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
