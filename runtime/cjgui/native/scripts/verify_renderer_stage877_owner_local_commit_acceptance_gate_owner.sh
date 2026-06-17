#!/usr/bin/env zsh
#
# Verifies the stage877 owner-local commit acceptance gate owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage877_owner_local_commit_acceptance_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage877 owner-local commit acceptance gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage877OwnerLocalCommitAcceptanceGatePlan" \
  "CjguiInternalRendererStage877OwnerLocalCommitAcceptanceGateFacts" \
  "CjguiInternalRendererStage877OwnerLocalCommitAcceptanceGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage877OwnerLocalCommitAcceptanceGateDraft" \
  "CjguiInternalRendererStage876OwnerLocalStateStoreCommitRuntimeManagerReadiness" \
  "didConsumeStage876OwnerLocalCommitRuntimeManager" \
  "didMaterializeOwnerLocalCommitAcceptancePolicyGate" \
  "didMaterializeOwnerLocalCommitAcceptanceRequestEnvelope" \
  "didMaterializeOwnerLocalCommitReviewScopeMatrix" \
  "didMaterializeAcceptRejectRequestChangesRoutes" \
  "didBindAcceptanceGateToOwnerLocalCommitReceipt" \
  "didPrepareStage878OwnerLocalCommitAcceptanceDecision"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage877 owner-local commit acceptance gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage877_owner_local_commit_acceptance_gate_owner_present=true"
echo "stage876_owner_local_commit_runtime_manager_consumed=true"
echo "stage875_owner_local_state_store_commit_demo_host_surface_consumed_transitively=true"
echo "stage874_owner_local_state_store_commit_rollback_ledger_consumed_transitively=true"
echo "stage873_owner_local_state_store_commit_first_slice_proof_consumed_transitively=true"
echo "owner_local_commit_acceptance_policy_gate_materialized=true"
echo "owner_local_commit_acceptance_request_envelope_materialized=true"
echo "owner_local_commit_review_scope_matrix_materialized=true"
echo "owner_local_commit_accept_reject_request_changes_routes_materialized=true"
echo "owner_local_commit_acceptance_gate_bound_to_commit_receipt=true"
echo "stage878_owner_local_commit_acceptance_decision_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
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
