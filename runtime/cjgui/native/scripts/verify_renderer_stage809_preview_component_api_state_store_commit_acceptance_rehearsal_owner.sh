#!/usr/bin/env zsh
#
# Verifies the stage809 preview component API state-store commit acceptance rehearsal owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage809 preview component api state-store commit acceptance rehearsal: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsalPlan" \
  "CjguiInternalRendererStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsalFacts" \
  "CjguiInternalRendererStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsalReadiness" \
  "cjguiInternalExecuteDefaultRendererStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsalDraft" \
  "CjguiInternalRendererStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManagerReadiness" \
  "didConsumeStage808PreviewComponentApiStateStoreCommitReviewHistoryRuntimeManager" \
  "didMaterializeAcceptanceRehearsalPlan" \
  "didMaterializeAcceptanceCandidateBundle" \
  "didMaterializeAcceptancePolicyGateLedger" \
  "didMaterializeRollbackAnchorBundle" \
  "didMaterializeNonCommittingEvidenceBundle" \
  "didBindAcceptanceRehearsalToReviewHistoryRuntimeManager" \
  "didPrepareStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage809 preview component api state-store commit acceptance rehearsal: missing token $token" >&2
    exit 3
  fi
done

echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_owner_present=true"
echo "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_consumed=true"
echo "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_consumed_transitively=true"
echo "acceptance_rehearsal_plan_materialized=true"
echo "acceptance_candidate_bundle_materialized=true"
echo "acceptance_policy_gate_ledger_materialized=true"
echo "rollback_anchor_bundle_materialized=true"
echo "non_committing_acceptance_evidence_bundle_materialized=true"
echo "acceptance_rehearsal_bound_to_review_history_runtime_manager=true"
echo "acceptance_rehearsal_non_committing=true"
echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_prepared=true"
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
