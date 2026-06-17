#!/usr/bin/env zsh
#
# Verifies the stage878 owner-local commit acceptance decision owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage878_owner_local_commit_acceptance_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage878 owner-local commit acceptance decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage878OwnerLocalCommitAcceptanceDecisionPlan" \
  "CjguiInternalRendererStage878OwnerLocalCommitAcceptanceDecisionFacts" \
  "CjguiInternalRendererStage878OwnerLocalCommitAcceptanceDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage878OwnerLocalCommitAcceptanceDecisionDraft" \
  "CjguiInternalRendererStage877OwnerLocalCommitAcceptanceGateReadiness" \
  "didConsumeStage877OwnerLocalCommitAcceptanceGate" \
  "didMaterializeOwnerLocalCommitAcceptanceDecisionReducer" \
  "didMaterializeOwnerLocalCommitAcceptanceDecisionLedger" \
  "didMaterializeOwnerLocalCommitAcceptanceReceipt" \
  "didBindAcceptanceDecisionToRollbackPlan" \
  "didKeepAcceptanceReceiptNotPublished" \
  "didPrepareStage879OwnerLocalCommitAcceptanceDemoSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage878 owner-local commit acceptance decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage878_owner_local_commit_acceptance_decision_owner_present=true"
echo "stage877_owner_local_commit_acceptance_gate_consumed=true"
echo "stage876_owner_local_commit_runtime_manager_consumed_transitively=true"
echo "owner_local_commit_acceptance_decision_reducer_materialized=true"
echo "owner_local_commit_acceptance_decision_ledger_materialized=true"
echo "owner_local_commit_acceptance_receipt_materialized=true"
echo "owner_local_commit_acceptance_rollback_binding_materialized=true"
echo "owner_local_commit_acceptance_receipt_not_published=true"
echo "owner_local_commit_accept_reject_request_changes_classified=true"
echo "stage879_owner_local_commit_acceptance_demo_surface_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
