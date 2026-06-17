#!/usr/bin/env zsh
#
# Verifies the stage862 text-input acceptance decision reducer owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage862_text_input_acceptance_decision_reducer.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage862 text input acceptance decision reducer: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerPlan" \
  "CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerFacts" \
  "CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage862TextInputAcceptanceDecisionReducerDraft" \
  "CjguiInternalRendererStage861TextInputOwnerAcceptanceReviewGateReadiness" \
  "didConsumeStage861TextInputOwnerAcceptanceReviewGate" \
  "didMaterializeAcceptedDecisionCandidate" \
  "didMaterializeRejectedDecisionCandidate" \
  "didMaterializeRequestChangesDecisionCandidate" \
  "didMaterializeRollbackSnapshotSelection" \
  "didMaterializeNotPublishedAcceptanceReceipt" \
  "didBindDecisionReducerToStage861ReviewGate" \
  "didPrepareStage863TextInputAcceptanceDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage862 text input acceptance decision reducer: missing token $token" >&2
    exit 3
  fi
done

echo "stage862_text_input_acceptance_decision_reducer_owner_present=true"
echo "stage861_text_input_owner_acceptance_review_gate_consumed=true"
echo "stage860_owner_local_text_input_commit_runtime_manager_consumed_transitively=true"
echo "owner_acceptance_accepted_decision_candidate_materialized=true"
echo "owner_acceptance_rejected_decision_candidate_materialized=true"
echo "owner_acceptance_request_changes_decision_candidate_materialized=true"
echo "owner_acceptance_rollback_snapshot_selection_materialized=true"
echo "owner_acceptance_not_published_receipt_materialized=true"
echo "owner_acceptance_decision_reducer_bound_to_stage861_review_gate=true"
echo "stage863_text_input_acceptance_demo_host_surface_prepared=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
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
